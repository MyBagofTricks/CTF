#!/usr/bin/env bash
# This script installs various bells and whistles for Kali.
# It focuses on tools, bug fixes, and bleeding edge updates
# Easily download and run with: wget --quiet -O - https://raw.githubusercontent.com/MyBagofTricks/CTF/master/BuildScripts/BuildKali2019-XFCE.sh| bash

export DEBIAN_FRONTEND=noninteractive
export APTLIST="ftp tor gcc-multilib g++-multilib golang tmux
exiftool ncat strace ltrace libreoffice gimp nfs-common 
libssl-dev steghide snmp-mibs-downloader php-curl dbeaver
knockd python3-pip samdump2 html2text putty libcurl4-openssl-dev
libpcre3-dev libssh-dev freerdp2-x11 crackmapexec proxychains4
mingw-w64 wine wine32 jq evolution firefox-esr cifs-utils
libgmp3-dev libmpc-dev docker.io jq rlwrap libzip-dev bison
cmake flex checkinstall powershell gnome-terminal vim-nox
gdb openjdk-11-jdk"

declare -A gitlist=(
["https://github.com/tdifg/WebShell.git"]="/opt/WebShell"
['https://github.com/cobbr/Covenant.git --recurse-submodules']="/opt/Covenant"
["https://github.com/BloodHoundAD/BloodHound.git"]="/opt/Bloodhound"
["https://github.com/samratashok/nishang.git"]="/opt/nishang"
["https://github.com/411Hall/JAWS.git"]="/opt/JAWS"
["https://github.com/PowerShellMafia/PowerSploit.git -b dev"]="/opt/PowerSploit"
["https://github.com/CoreSecurity/impacket.git"]="/opt/Impacket"
["https://github.com/magnumripper/JohnTheRipper.git"]="/opt/JohnJumbo"
["https://github.com/danielmiessler/SecLists.git"]="/opt/SecLists"
["https://github.com/radare/radare2.git"]="/opt/radare2"
["https://github.com/rebootuser/LinEnum.git"]="/opt/LinEnum"
["https://github.com/trailofbits/onesixtyone.git"]="/opt/onesixtyone"
["https://github.com/rasta-mouse/Sherlock.git"]="/opt/Sherlock"
["https://github.com/EmpireProject/Empire.git"]="/opt/Empire"
["https://github.com/SecWiki/windows-kernel-exploits.git"]="/opt/windows-kernel-exploits"
["https://github.com/M4ximuss/Powerless.git"]="/opt/Powerless"
["https://github.com/swisskyrepo/PayloadsAllTheThings.git"]="/opt/PayloadAllTheThings"
["https://github.com/andrew-d/static-binaries.git"]="/opt/static-binaries"
["https://github.com/sleventyeleven/linuxprivchecker.git"]="/opt/linuxprivchecker"
["https://github.com/mzet-/linux-exploit-suggester.git"]="/opt/linux-exploit-suggster"
["https://github.com/FuzzySecurity/PowerShell-Suite.git"]="/opt/Powershell-Suite"
["https://github.com/mwielgoszewski/python-paddingoracle.git"]="/opt/python-poodle"
["https://github.com/diego-treitos/linux-smart-enumeration.git"]="/opt/linux-smart-enum"
["https://github.com/ShawnDEvans/smbmap.git"]="/opt/smbmap"
["https://github.com/jpillora/chisel.git"]="/opt/chisel"
["https://github.com/Ganapati/RsaCtfTool.git"]="/opt/RsaCtfTool"
["https://github.com/OJ/gobuster.git"]="/opt/gobuster"
["https://github.com/sashs/Ropper.git"]="/opt/Ropper"
["https://github.com/carlospolop/privilege-escalation-awesome-scripts-suite.git"]="/opt/peass"
["https://github.com/MyBagofTricks/vimconfig.git"]="/root/.vim"
["https://github.com/longld/peda.git"]="/root/peda"
)

## Funcitons 
lockCheck() {
    i=0 
    while fuser /var/lib/dpkg/lock &>/dev/null; do
        echo -ne "\r[!] Waiting for apt lock. If this persists, kill it or reboot. $i sec elapsed..."
        sleep 1
        ((i++)) 
    done
}

echo "*** Starting Custom Kali build script ***"
# Bail out if not run as root
if [[ $EUID -ne 0 ]]; then
        echo "[!] This script needs root privileges."
        exit 1
fi

lockCheck
echo "[+] Downloading Git repos in background"
for url in "${!gitlist[@]}"; do
       git clone $url ${gitlist[$url]} --quiet
done &


lockCheck
echo "[+] Installing apt packages. This may take 5-10mins..."
dpkg --add-architecture i386 
apt-get update 
apt-get install $APTLIST -y 

apt-get remove needrestart radare2 onesixtyone python-impacket smbmap -qy 
apt-get autoremove -y 
wait

curl --silent -L https://github.com/radareorg/cutter/releases/download/v1.9.0/Cutter-v1.9.0-x64.Linux.AppImage -o /usr/local/sbin/Cutter \
	&& chmod +x /usr/local/sbin/Cutter &

curl --silent -L https://ghidra-sre.org/ghidra_9.1_PUBLIC_20191023.zip -o /opt/ghidra_9.1_PUBLIC_20191023.zip ; cd /opt; unzip ghidra_9.1_PUBLIC_20191023.zip; rm ghidra_9.1_PUBLIC_20191023.zip \
	&& ln -sf /opt/ghidra_9.1_PUBLIC/ghidraRun /usr/local/bin/ghidraRun \
        && echo "[+] Ghidra installed!" &

# Build packages downloaded in previous step here
lockCheck
echo "[+] Installing radare2 from source"
cd /opt/radare2 && make purge;  sys/install.sh && echo "[*] radare2 installed!" 

echo "[+] Installing r2ghidara + r2retdec"
r2pm init && r2pm update; r2pm -i r2ghidra-dec r2retdec retdec \
	&& echo "[*] radare2 plugins installed!" &

echo "[+] Installing John the Ripper Community Edition"
cd /opt/JohnJumbo/src
./configure 
make && echo "[*] John the Ripper installed!" && rm -rf /opt/JohnJumbo &

cd /opt/RsaCtfTool
pip3 install -r requirements.txt 
ln -sf /opt/RsaCtfTool/RsaCtfTool.py /usr/local/sbin/RsaCtfTool.py 

echo "[+] Installing pwntools"
pip install -q pwntools && echo "[*] pwntools installed!" &

echo "[+] Installing python-paddingoracle API"
cd /opt/python-poodle
python2 setup.py install && echo "[*] python-paddingoracle installed!" &

echo "[+] Installing Empire"
cd /opt/Empire
echo | setup/install.sh && echo "[*] Empire installed!" &

cd /opt/onesixtyone
make && ln -sf /opt/onesixtyone/onesixtyone /usr/local/sbin/onesixtyone & 

cd /opt/gobuster
go get && go build -o /usr/bin/gobuster && rm -rf /opt/gobuster &

echo "[+] Installing and configuring Covenant Docker container"
cd /opt/Covenant/Covenant
docker build -t covenant . && echo "[*] Covenant installed"

echo "[x] Installing smbmap from source"
cd /opt/smbmap && pip3 install -r requirements.txt 
ln -s /opt/smbmap/smbmap.py /usr/bin/smbmap 

echo "[x] Installing nodejs from source"
curl -sL https://deb.nodesource.com/setup_13.x | sudo -E bash -
apt-get install -y nodejs 

echo "[x] Installig Ropper from source"
cd /opt/Ropper && pip install -r requirements.txt 
python setup.py install 

echo "[+] Adding custom aliases..."
echo "alias ll='ls -alh'" >> $HOME/.bashrc

sed -i '/mibs/s/^/#/g' /etc/snmp/snmp.conf
echo "source $HOME/peda/peda.py" >> $HOME/.gdbinit

echo "[x] Reinstalling Sparta, CrackMapExec, and enum4linux"
apt install crackmapexec sparta enum4linux -y 

echo "[-] Removing broken Impacket preinstalled on Kali"
pip uninstall impacket -y 
echo "[+] Installing Impacket"
cd /opt/Impacket
pip install -q -r requirements.txt 
python setup.py install && echo "[*] Impacket installed!" &

#echo "[*] Setting Burp's Java to 8 for compatibility"
#echo "2" | update-alternatives --config java >/dev/null

echo "[+] Customizing vim and tmux..."
rm $HOME/.vimrc 2>/dev/null 
ln -s $HOME/.vim/.vimrc $HOME/.vimrc
rm $HOME/.tmux.conf 2>/dev/null
ln -s $HOME/.vim/.tmux.conf $HOME/.tmux.conf
vim +'PlugUpdate --sync' +qall &>/dev/null &

# Script for FTP server setup
cd $HOME
cat > initialize-pureftpd.sh << '__EOF__'
#!/usr/bin/env bash
apt-get update; apt-get install pure-ftpd -y
groupadd ftpgroup
useradd -g ftpgroup -d /dev/null -s /etc ftpuser
pure-pw useradd hackerman -u ftpuser -d /ftphome
pure-pw mkdb
cd /etc/pure-ftpd/auth/
ln -s ../conf/PureDB 60pdb
mkdir -p /ftphome
chown -R ftpuser:ftpgroup /ftphome/
/etc/init.d/pure-ftpd restart
__EOF__
chmod +x $HOME/initialize-pureftpd.sh


echo "[+] Generating ssh key..."
rm -rf $HOME/.ssh
cat /dev/zero | ssh-keygen -t rsa -b 2048 -q -N '' -f $HOME/.ssh/id_rsa

# Uncomment this section and add your key if you want to wipe and replace existing settings
#tee ~/.ssh/authorized_keys << 'EOF'
#YOUR SSH KEY GOES HERE
#EOF

# Creates a script to fix copy/paste issues with Virtualbox
# run it whenever guest additions stop working
cat > $HOME/fixCopyPasteVB.sh << '__EOF__'
killall VBoxClient
VBoxClient --clipboard
VBoxClient --checkhostversion
VBoxClient --display
VBoxClient --seamless
VBoxClient --draganddrop
__EOF__
chmod +x $HOME/fixCopyPasteVB.sh

echo "[*] Waiting for background processes to complete..."
wait
echo "[*] Done! Don't forget to change the root password!"
echo "[!] Note: curl may have issues with older ssl ciphers. If so try installing libssl-dev"
