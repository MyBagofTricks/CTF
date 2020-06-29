#!/usr/bin/env bash
# IMPORTANT: THIS SCRIPT INSTALLS EVERYTHING FOR THE ROOT USER!!!!
# To enable the root user in Kali2020, sign in using kali:kali and execute `passwd root` to set the root account's pw 
# Sign back in as root and execute the script to install.
# Running Kali in anything other than a VM which gets discarded after every session is a bad idea
#
# This script installs various bells and whistles for Kali.
# It focuses on tools, bug fixes, and bleeding edge updates
# Easily download and run with: wget --quiet -O - https://raw.githubusercontent.com/MyBagofTricks/CTF/master/BuildScripts/BuildKali2020.sh | bash


export DEBIAN_FRONTEND=noninteractive
export APTLIST="ftp tor gcc-multilib g++-multilib golang tmux
libimage-exiftool-perl ncat strace ltrace libreoffice gimp nfs-common 
libssl-dev steghide snmp-mibs-downloader php-curl dbeaver
knockd python3-pip samdump2 html2text putty libcurl4-openssl-dev
libpcre3-dev libssh-dev freerdp2-x11 proxychains4
mingw-w64 wine wine32 jq evolution firefox-esr cifs-utils
libgmp3-dev libmpc-dev docker.io jq rlwrap libzip-dev bison
cmake flex checkinstall powershell gnome-terminal vim-nox
gdb openjdk-11-jdk powershell-empire python-dev crackmapexec"

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
["https://github.com/MyBagofTricks/vimconfig.git"]="$HOME/.vim"
["https://github.com/Hackplayers/evil-winrm.git"]="/opt/evil-winrm"
)

## Funcitons 
pretty_print() {                               
        OK='\033[0;32m'
        BAD='\033[0;31m'                                      
        NEUTRAL='\033[0;34m'                           
        NC='\033[0m'
        case "$2" in                                           
                "!" | "+" | "^") echo -e "$OK[$2]$NC $1";;
                "x") echo -e "$BAD[$2]$NC $1";;
                "*") echo -e "$NEUTRAL[$2]$NC $1";;
                *) echo "[ ] $1";;      
        esac
}

lock_check() {
    i=0 
    while fuser /var/lib/dpkg/lock &>/dev/null; do
	    echo -ne "\r[!] Waiting for apt lock. If this persists, kill it or reboot. $i sec elapsed..."
        sleep 1
        ((i++)) 
    done
}

pretty_print "*** Starting Custom Kali build script ***" "!"
(( EUID )) && { pretty_print "This script requires root privileges and installs everything for the root user" '!'; exit 1; }

lock_check
pretty_print "Downloading Git repos in background" "*"
for url in "${!gitlist[@]}"; do
       git clone $url ${gitlist[$url]} --quiet
done &

lock_check
dpkg --add-architecture i386 
apt-get -qq update 
pretty_print "Installing Stage 1 packages via apt:\n$APTLIST\nThis may take 5-10mins..." "*"
apt-get install -qq $APTLIST &>/dev/null 
pretty_print "Stage 1 packages installed." "+"

pretty_print "Removing outdated packages to instal newer versions" "*"
apt-get -qy remove needrestart radare2 onesixtyone python-impacket smbmap metasploit-framework &>/dev/null 
apt-get -qy autoremove &>/dev/null
pretty_print "Outdated packages removed." "+"
pretty_print "Waiting for background downloads to complete before starting Stage2" "!"
wait

# Install Python2-pip
curl -sL https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py \
	&& python2 /tmp/get-pip.py &>/dev/null

curl -sL https://github.com/radareorg/cutter/releases/download/v1.10.1/Cutter-v1.10.1-x64.Linux.AppImage -o /usr/local/bin/Cutter \
	&& chmod +x /usr/local/bin/Cutter && pretty_print "Cutter installed" "+" &

curl -sL https://ghidra-sre.org/ghidra_9.1_PUBLIC_20191023.zip -o /opt/ghidra_9.1_PUBLIC_20191023.zip ; cd /opt; unzip ghidra_9.1_PUBLIC_20191023.zip &>/dev/null ; rm ghidra_9.1_PUBLIC_20191023.zip \
	&& ln -sf /opt/ghidra_9.1_PUBLIC/ghidraRun /usr/local/bin/ghidraRun \
        && pretty_print "Ghidra installed!" "+" &

# Build packages downloaded in previous step here
lock_check
pretty_print "Installing radare2 from source" "*"
cd /opt/radare2 && make purge;  sys/install.sh &>/dev/null \
	&& pretty_print "radare2 installed!" "+"

pretty_print "Installing r2ghidara + r2dec" "*"
r2pm init && r2pm update; r2pm -gi r2ghidra-dec r2retdec r2dec retdec &>/dev/null \
	&& pretty_print "radare2 plugins installed!" "+" &

pretty_print "Installing the latest version of Metasploit" "*"
curl -sL https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb | bash \
	&& pretty_print "Metasploit installed successfully!" "+" &

pretty_print "Installing John the Ripper Community Edition" "*"
cd /opt/JohnJumbo/src && ./configure &>/dev/null && make &>/dev/null \
	&& make install &>/dev/null && pretty_print "John the Ripper installed!" "+" && rm -rf /opt/JohnJumbo &

cd /opt/RsaCtfTool
pip3 install -r requirements.txt --quiet 
ln -sf /opt/RsaCtfTool/RsaCtfTool.py /usr/local/bin/RsaCtfTool.py 

pretty_print "Installing pwntools for Python2 and Python3" "*"
pip install --upgrade git+https://github.com/Gallopsled/pwntools.git --quiet
pip3 install --upgrade git+https://github.com/Gallopsled/pwntools.git@dev3 --quiet
pretty_print "pwntools for Python2 and Python3 installed!" "+"

pretty_print "Installing python-paddingoracle API" "*"
cd /opt/python-poodle
python2 setup.py install && pretty_print "python-paddingoracle installed!" "+" &

cd /opt/onesixtyone
make && ln -sf /opt/onesixtyone/onesixtyone /usr/local/bin/onesixtyone & 

cd /opt/gobuster
go get && go build -o /usr/bin/gobuster && rm -rf /opt/gobuster \
	&& pretty_print "GoBuster installed" "+" &

pretty_print "Installing and configuring Covenant Docker container" "*"
cd /opt/Covenant/Covenant
docker build -t covenant . &>/dev/null  && pretty_print "Covenant installed" "+"

pretty_print "Installing smbmap from source" "*"
cd /opt/smbmap && pip3 install -r requirements.txt --quiet
ln -s /opt/smbmap/smbmap.py /usr/local/bin/smbmap 

pretty_print "Installing nodejs from source" "*"
curl -sL https://deb.nodesource.com/setup_13.x | sudo -E bash -
lock_check
apt-get -qy install nodejs &>/dev/null

pretty_print "Installig Ropper from source" "*"
cd /opt/Ropper && pip install -r requirements.txt --quiet
python setup.py install &>/dev/null

pretty_print "Installing Evil-WinRM" "*"
cd /opt/evil-winrm
gem install bundler && python2 setup.py install && pretty_print "python-paddingoracle installed!" "+" &


pretty_print "Adding custom aliases..." "*"
echo "alias ll='ls -alh'" >> /root/.bashrc
echo "alias ll='ls -alh" >> /home/kali/.bashrc

sed -i '/mibs/s/^/#/g' /etc/snmp/snmp.conf
echo "source /root/peda/peda.py" >> /root/.gdbinit
echo "source /home/kali/peda/peda.py" >> /home/kali/.gdbinit

pretty_print "Reinstalling Sparta and enum4linux" "*"
lock_check
apt-get -qy install sparta enum4linux

pretty_print "Removing broken Impacket preinstalled on Kali" "*"
pip uninstall impacket -y --quiet
pretty_print "Installing Impacket" "*"
cd /opt/Impacket
pip install -r requirements.txt --quiet
python setup.py install &>/dev/null && pretty_print "Impacket installed!" "+" &

#echo "[*] Setting Burp's Java to 8 for compatibility"
#echo "2" | update-alternatives --config java >/dev/null

pretty_print "Customizing vim and tmux..." "*"
rm -f /root/.vimrc /home/kali/.vimrc
ln -s /root/.vim/.vimrc /root/.vimrc
ln -s /home/kali/.vim/.vimrc /home/kali/.vimrc

rm -f /root/.tmux.conf /home/kali/.tmux.conf
ln -s /root/.vim/.tmux.conf /root/.tmux.conf
ln -s /home/kali/.vim/.tmux.conf /home/kali/.tmux.conf
vim +'PlugUpdate --sync' +qall &>/dev/null &

cp -r "$HOME/.vim" /home/kali/.vim

# Script for FTP server setup
cat > /root/initialize-pureftpd.sh << '__EOF__'
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
chmod +x /root/initialize-pureftpd.sh
cp /root/initialize-pureftpd.sh /home/kali


pretty_print "Generating ssh key..." "*" 
rm -rf /root/.ssh /home/kali/.ssh
cat /dev/zero | ssh-keygen -t rsa -b 2048 -q -N '' -f /root/.ssh/id_rsa
cat /dev/zero | ssh-keygen -t rsa -b 2048 -q -N '' -f /home/kali/.ssh/id_rsa

# Uncomment this section and add your key if you want to wipe and replace existing settings
#tee ~/.ssh/authorized_keys << 'EOF'
#YOUR SSH KEY GOES HERE
#EOF

# Creates a script to fix copy/paste issues with Virtualbox
# run it whenever guest additions stop working
cat > /root/fixCopyPasteVB.sh << '__EOF__'
killall VBoxClient
VBoxClient --clipboard
VBoxClient --checkhostversion
VBoxClient --display
VBoxClient --seamless
VBoxClient --draganddrop
__EOF__
chmod +x /root/fixCopyPasteVB.sh
cp /root/fixCopyPasteVB.sh /home/kali
echo 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/sbin:/usr/sbin' >> /home/kali/.bashrc

pretty_print "Waiting for background processes to complete..." 
wait
pretty_print "Done." "!"
