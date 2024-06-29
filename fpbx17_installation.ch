 end_inst.sh >#!/bin/bash

cd /root
wget https://raw.githubusercontent.com/fdmgit/asterisk/main/start_inst.ch
wget https://raw.githubusercontent.com/FreePBX/sng_freepbx_debian_install/master/sng_freepbx_debian_install.sh -O fpbx_deb_inst.sh | tail n +2
wget https://raw.githubusercontent.com/fdmgit/asterisk/main/end_inst.ch

touch full_fpbx17_inst.sh
cat start_inst.sh fpbx_deb_inst.sh end_inst.sh > full_fpbx17_inst.sh

chmod +x full_fpbx17_inst.sh

rm start_inst.sh
rm fpbx_deb_inst.sh
rm end_inst.sh

. ./full_fpbx17_inst.sh --skipversion

cd /root

rm full_fpbx17_inst.sh

reboot


