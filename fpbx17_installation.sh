 #!/bin/bash

cd /root
wget https://raw.githubusercontent.com/fdmgit/asterisk/main/start_inst.sh
wget https://raw.githubusercontent.com/FreePBX/sng_freepbx_debian_install/master/sng_freepbx_debian_install.sh -O fpbx_deb_inst.sh
tail -n +2 fpbx_deb_inst.sh > fpbx.tmp && cp fpbx.tmp fpbx_deb_inst.sh
wget https://raw.githubusercontent.com/fdmgit/asterisk/main/end_inst.sh

touch full_fpbx17_inst.sh
cat start_inst.sh fpbx_deb_inst.sh end_inst.sh > full_fpbx17_inst.sh

chmod +x full_fpbx17_inst.sh

rm fpbx.tmp
rm start_inst.sh
rm fpbx_deb_inst.sh
rm end_inst.sh

./full_fpbx17_inst.sh --skipversion --opensourceonly

cd /root

rm full_fpbx17_inst.sh

reboot


