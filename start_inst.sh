#!/bin/bash

##################################################
#             Var / Const Definition             #
##################################################

okinput=true

NC=$(echo -en '\001\033[0m\002')
RED=$(echo -en '\001\033[00;31m\002')
GREEN=$(echo -en '\001\033[00;32m\002')
YELLOW=$(echo -en '\001\033[00;33m\002')
BLUE=$(echo -en '\001\033[00;34m\002')
MAGENTA=$(echo -en '\001\033[00;35m\002')
PURPLE=$(echo -en '\001\033[00;35m\002')
CYAN=$(echo -en '\001\033[00;36m\002')
WHITE=$(echo -en '\001\033[01;37m\002')

LIGHTGRAY=$(echo -en '\001\033[00;37m\002')
LRED=$(echo -en '\001\033[01;31m\002')
LGREEN=$(echo -en '\001\033[01;32m\002')
LYELLOW=$(echo -en '\001\033[01;33m\002')
LBLUE=$(echo -en '\001\033[01;34m\002')
LMAGENTA=$(echo -en '\001\033[01;35m\002')
LPURPLE=$(echo -en '\001\033[01;35m\002')
LCYAN=$(echo -en '\001\033[01;36m\002')


##################################################
#                   Functions                    #
##################################################

print_header () {
   clear
   echo ""
   echo -e "${YELLOW}     Welcome to the Asterisk / FreePBX System installer!${NC}"
   echo -e "${GREEN}"
   echo "     I need to ask you a few questions before starting the setup."
   echo ""
}

print_conf () {
   clear
   echo ""
   echo -e "${YELLOW}     Asterisk / FreePBX System installer${NC}"
   echo -e "${GREEN}"
   echo "     Your input is:"
   echo ""
}

get_fqdn_pw () {
   rpasswd=""
   fqdn=""

   print_header

   until [ ${#rpasswd} -gt 11 ]; do
       echo -en "${GREEN}     Enter new root password [min. length is 12 char]: ${YELLOW} "
       read -e -i "${rpasswd}" rpasswd
       if [ ${#rpasswd} -lt 12 ]; then
           print_header
	   echo -e "${LRED}     Password has too few characters"
       fi
    done

    print_header
    echo -e "${GREEN}     Enter new root password [min. length is 12 char]:  ${YELLOW}${rpasswd}"

    until [[ "$fqdn" =~ ^.*\..*\..*$ ]]; do
    #   print_header
    #   echo -e "${GREEN}     Enter new root password [min. length is 12 char]:  ${YELLOW}${rpasswd}"
        echo -en "${GREEN}     Enter a full qualified domain name:               ${YELLOW} "
        read -e -i "${fqdn}" fqdn
        if [[ "$fqdn" =~ ^.*\..*\..*$ ]]; then
            print_conf
            echo -e "${GREEN}     New root password:           ${YELLOW}${rpasswd}"
            echo -e "${GREEN}     Full qualified domain name:  ${YELLOW}${fqdn}"
        else
            print_header
            echo -e "${GREEN}     Enter new root password [min. length is 12 char]:  ${YELLOW}${rpasswd}"
            echo ""
            echo -e "${LRED}     The FQDN is not correct"   
        fi
     done

     echo -e "${NC}"
     read -r -p "     Ready to start installation [Y/n] ? " start_inst
     if [[ "$start_inst" = "" ]]; then
         start_inst="Y"
     fi
     if [[ "$start_inst" != [yY] ]]; then
         clear
         exit
     fi   
     hostnamectl set-hostname $fqdn  # set hostname
     echo "root:${rpasswd}" | chpasswd    # set root password -
}


ssh_hard () {

    echo "deb http://deb.debian.org/debian/ bookworm-backports main" | tee -a /etc/apt/sources.list   

    apt update
    apt upgrade -y

	###################################
	#### SSH Hardening
	#### https://sshaudit.com
	###################################

	#### Re-generate the RSA and ED25519 keys
	rm /etc/ssh/ssh_host_*
	ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
	ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""

	#### Remove small Diffie-Hellman moduli
	awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.safe
	mv /etc/ssh/moduli.safe /etc/ssh/moduli

	#### Restrict supported key exchange, cipher, and MAC algorithms
	echo -e "# Restrict key exchange, cipher, and MAC algorithms, as per sshaudit.com\n# hardening guide.\n\nKexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,gss-curve25519-sha256-,diffie-hellman-group16-sha512,gss-group16-sha512-,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256\n\nCiphers aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr\n\nMACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com\n\nHostKeyAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256\n\nRequiredRSASize 3072\n\nCASignatureAlgorithms sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256\n\nGSSAPIKexAlgorithms gss-curve25519-sha256-,gss-group16-sha512-\n\nHostbasedAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-256\n\nPubkeyAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-256\n\n" > /etc/ssh/sshd_config.d/ssh-audit_hardening.conf
 
    #### Change SSH port and some config parameters
        sed -i "s|\#LoginGraceTime 2m|LoginGraceTime 1m|g" /etc/ssh/sshd_config
	sed -i "s|\#Port 22|Port 49153|g" /etc/ssh/sshd_config
	sed -i "s|\#MaxAuthTries 6|MaxAuthTries 4|g" /etc/ssh/sshd_config
	sed -i "s|X11Forwarding yes|X11Forwarding no|g" /etc/ssh/sshd_config
	sed -i "s|session    required     pam_env.so user_readenv=1 envfile=/etc/default/locale|session    required     pam_env.so envfile=/etc/default/locale|g" /etc/pam.d/sshd

    # Restart SSH: Port changed to 49153
    systemctl restart sshd
    sleep 5
}

server_env () {

    cd /root
    wget https://raw.githubusercontent.com/fdmgit/asterisk/main/bashrc.ini
    cp bashrc.ini /root/.bashrc
    cp bashrc.ini /etc/skel/.bashrc
    rm /root/bashrc.ini
    echo 'export PATH="$PATH:/root/.local/bin:/snap/bin"'  >> .bashrc
    echo 'export PATH="$PATH:/root/.local/bin:/snap/bin"'  >> /etc/skel/.bashrc
    apt install curl sudo -y

    ###################################
    #### Setup root key file
    ###################################

	if [ -d /root/.ssh ]; then 
		echo ".ssh exists"
	else
		mkdir /root/.ssh
	fi

	if [ -f /root/.ssh/authorized_keys ]; then
		echo "file authorized_keys exists"
	else
		cd /root/.ssh
		wget https://raw.githubusercontent.com/fdmgit/virtualmin/main/authorized_keys
	fi
}

inst_webmin () {

	###########################
	#  Install Webmin
	###########################

	apt-get -y install perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions unzip shared-mime-info
        curl -o webmin-setup-repo.sh https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repo.sh
	echo "y" | sh webmin-setup-repo.sh
	apt-get install webmin --install-recommends -y
        #wget https://rc.download.webmin.dev/webmin_2.303-1_all.deb
        #dpkg -i webmin_2.303-1_all.deb
        sleep 30
 }

 function inst_php82() {


    #apt-get install php8.2-{bcmath,bz2,cgi,curl,dba,fpm,gd,gmp,igbinary,imagick,imap,intl,ldap,mbstring} -y
    #apt-get install php8.2-{mysql,odbc,opcache,pspell,readline,redis,soap,sqlite3,tidy,xml,xmlrpc,xsl,zip} -y

    cat >>/etc/php/8.2/apache2/php.ini <<'EOF'

[PHP]
output_buffering = Off
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 2048M
upload_max_filesize = 2048M
date.timezone = Europe/Zurich
max_input_vars = 10000
[Session]
session.gc_maxlifetime = 3600     
[opcache]
opcache.enable=1

EOF

    cat >>/etc/php/8.2/cli/php.ini <<'EOF'

[PHP]
output_buffering = Off
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 2048M
upload_max_filesize = 2048M
date.timezone = Europe/Zurich
max_input_vars = 10000
[Session]
session.gc_maxlifetime = 3600     
[opcache]
opcache.enable=1

EOF

}


closing_msg () {

######################################################
# Closing message after completion of installation
######################################################

    cd /root

    # Closing message
    host_name=$(hostname | awk '{print $1}')
    echo ""
    echo -e "${YELLOW}ATTENTION\\n"
    echo -e "${GREEN}The port for SSH has changed. To login use the following comand:\\n"
    echo -e "${CYAN}        ssh root@${host_name} -p 49153${NC}\\n"
    echo ""
    echo -e "${GREEN} Webmin page is reachable by entering:\\n"
    echo -e "${CYAN}        https://${host_name}:10000"
    echo -e "${NC}\\n"
    echo -e "End Time:" "$(date +"%d.%m.%Y %T")"
    echo ""
    echo ""
}

set_swap () {

###########################
#      Set Swap Space
###########################

    cd /root
    swapon --show > swapon.out       ## check if swap exists
    FILESIZE=$(stat -c%s swapon.out)

    if [[ "$FILESIZE" == "0" ]]; then      ## swap space does not exist
        fallocate -l 1G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile swap swap defaults 0 0' >> /etc/fstab
    fi
    rm swapon.out
}

inst_certbot () {
    apt install certbot python3-certbot-apache -y

    a2enmod ssl
    a2enmod headers
    a2enmod proxy
    a2enmod proxy-http
    service apache2 restart
    
}


inst_locate () {

    apt-get install plocate -y
    updatedb
    timedatectl set-timezone Europe/Zurich

}

inst_f2b () {
    cd /root
    wget https://github.com/fail2ban/fail2ban/releases/download/1.1.0/fail2ban_1.1.0-1.upstream1_all.deb
    apt install ./fail2ban_1.1.0-1.upstream1_all.deb -y 
    rm fail2ban_1.1.0-1.upstream1_all.deb
    cd /etc/fail2ban/jail.d
    wget https://raw.githubusercontent.com/fdmgit/asterisk/main/ignoreip.local
    wget https://raw.githubusercontent.com/fdmgit/asterisk/main/pts2.local
    systemctl restart fail2ban
    wait 20
}

inst_f2b_jails () {
    cd /etc/fail2ban/jail.d
    wget https://raw.githubusercontent.com/fdmgit/asterisk/main/ignoreip.local
    wget https://raw.githubusercontent.com/fdmgit/asterisk/main/pts2.local
}

inst_base () {
    apt install curl sudo rsyslog -y
}

function inst_logo_styles () {

###################################
#### add logo and styles
###################################

    cd /root

cat >> /root/inst_logo_styles.sh <<'EOF'

wget https://raw.githubusercontent.com/fdmgit/virtualmin/main/logostyle.zip
unzip logostyle.zip
cp logo.png /etc/webmin/authentic-theme/
cp logo_welcome.png /etc/webmin/authentic-theme/
cp styles.css /etc/webmin/authentic-theme/
rm logo.png
rm logo_welcome.png
rm styles.css
rm logostyle.zip
rm inst_logo_styles.sh

EOF

    chmod +x /root/inst_logo_styles.sh

}

function inst_snap_certbot () {

    apt install snapd -y
    snap install snapd
    snap install --classic certbot
    ln -s /snap/bin/certbot /usr/bin/certbot

}

#####################################################################################
#                                               FreePBX 17                          #
#####################################################################################

#### Pre-installation

get_fqdn_pw
ssh_hard
server_env
set_swap
#inst_f2b
#inst_webmin
inst_base
inst_logo_styles


