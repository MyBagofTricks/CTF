#!/usr/bin/env bash
# This script installs various bells and whistles for Kali.
# It focuses on tools, bug fixes, and bleeding edge updates
# Easily download and run with: wget --quiet -O https://github.com/MyBagofTricks/CTF/blob/master/BuildScripts/BuildKali2019.sh | bash

export DEBIAN_FRONTEND=noninteractive
export APTLIST="ftp tor gcc-multilib g++-multilib golang tmux
exiftool ncat strace ltrace libreoffice gimp nfs-common 
libssl-dev steghide snmp-mibs-downloader php-curl dbeaver
knockd python3-pip bkhive html2text putty libcurl4-openssl-dev
libpcre3-dev libssh-dev freerdp2-x11 crackmapexec proxychains4
mingw-w64 wine wine32 jq evolution firefox-esr cifs-utils
libgmp3-dev libmpc-dev docker.io jq rlwrap"


# Format: ["url1"]="path" ["url2"]="path" etc
declare -A tarlist=(
["https://github.com/tdifg/WebShell/tarball/master"]="/opt/WebShell"
['https://github.com/cobbr/Covenant/tarball/master']="/opt/Covenant"
['https://github.com/cobbr/Elite/tarball/master']="/opt/Elite"
["https://github.com/BloodHoundAD/BloodHound/tarball/master"]="/opt/Bloodhound"
["https://github.com/samratashok/nishang/tarball/master"]="/opt/nishang"
["https://github.com/411Hall/JAWS/tarball/master"]="/opt/JAWS"
["https://github.com/PowerShellMafia/PowerSploit/tarball/master"]="/opt/PowerSploit"
["https://github.com/CoreSecurity/impacket/tarball/master"]="/opt/Impacket"
["https://github.com/magnumripper/JohnTheRipper/tarball/master"]="/opt/JohnJumbo"
["https://github.com/danielmiessler/SecLists/tarball/master"]="/opt/SecLists"   
["https://github.com/radare/radare2/tarball/master"]="/opt/radare2"
["https://github.com/rebootuser/LinEnum/tarball/master"]="/opt/LinEnum"
["https://github.com/trailofbits/onesixtyone/tarball/master"]="/opt/onesixtyone"
["https://github.com/rasta-mouse/Sherlock/tarball/master"]="/opt/Sherlock"
["https://github.com/EmpireProject/Empire/tarball/master"]="/opt/Empire"
["https://github.com/SecWiki/windows-kernel-exploits/tarball/master"]="/opt/windows-kernel-exploits"
["https://github.com/M4ximuss/Powerless/tarball/master"]="/opt/Powerless"
["https://github.com/swisskyrepo/PayloadsAllTheThings/tarball/master"]="/opt/PayloadAllTheThings"
["https://github.com/andrew-d/static-binaries/tarball/master"]="/opt/static-binaries"
["https://github.com/sleventyeleven/linuxprivchecker/tarball/master"]="/opt/linuxprivchecker"
["https://github.com/mzet-/linux-exploit-suggester/tarball/master"]="/opt/linux-exploit-suggster"
["https://github.com/FuzzySecurity/PowerShell-Suite/tarball/master"]="/opt/Powershell-Suite"
["https://github.com/mwielgoszewski/python-paddingoracle/tarball/master"]="/opt/python-poodle"
["https://github.com/diego-treitos/linux-smart-enumeration/tarball/master"]="/opt/linux-smart-enum"
["https://github.com/jpillora/chisel/tarball/master"]="/opt/chisel"
["https://github.com/Ganapati/RsaCtfTool/tarball/master"]="/opt/RsaCtfTool"
["https://github.com/OJ/gobuster/tarball/master"]="/opt/gobuster"
["https://github.com/MyBagofTricks/vimconfig/tarball/master"]="/root/.vim"
["https://github.com/longld/peda/tarball/master"]="/root/peda"
)

# Default to quiet output. Add -v for verbose
verbosity='&>/dev/null'
while getopts v o; do
	case $o in
		(v) verbosity=""
	esac
done

## Funcitons 
lockCheck() {
    i=0 
    while fuser /var/lib/dpkg/lock &>/dev/null; do
        echo -ne "\r[!] Waiting for apt lock. If this persists, kill it or reboot. $i sec elapsed..."
        sleep 1
        ((i++)) 
    done
}

echo "*** Starting Custom Kali build script. Use -v for verbose output ***"
# Bail out if not run as root
if [[ $EUID -ne 0 ]]; then
        echo "[!] This script needs root privileges."
        exit 1
fi

lockCheck
echo "[+] Disabling suspend/sleep"
eval systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target $verbosity
eval gsettings set org.gnome.desktop.session idle-delay 0 $verbosity

echo "[+] Downloading tarballs in background"
for url in "${!tarlist[@]}"; do 
	eval mkdir -p ${tarlist[$url]} && curl --silent -L $url -o - \
		| tar -xzC ${tarlist[$url]} --strip-component=1 2>/dev/null &
done

eval curl --silent -L https://github.com/radareorg/cutter/releases/download/v1.7.2/Cutter-v1.7.2-x86_64.Linux.AppImage -o /usr/local/sbin/Cutter \
	&& chmod +x /usr/local/sbin/Cutter &

lockCheck
echo "[+] Installing the first batch of apt packages. This may take 5-10mins..."
eval dpkg --add-architecture i386 $verbosity
eval apt-get update $verbosity
eval apt-get install $APTLIST -y $verbosity

wait
# Build packages downloaded in previous step here
lockCheck
eval apt-get remove radare2 onesixtyone python-impacket -qy $verbosity


echo "[+] Installing radare2 from source"
eval /opt/radare2/sys/install.sh $verbosity && echo "[*] radare2 installed!" &

echo "[+] Installing John the Ripper Community Edition"
cd /opt/JohnJumbo/src
eval ./configure $verbosity 
eval make $verbosity && echo "[*] John the Ripper installed!" && rm -rf /opt/JohnJumbo &

echo "[-] Removing broken Impacket preinstalled on Kali"
eval pip uninstall impacket -y $verbosity
echo "[+] Installing Impacket"
cd /opt/Impacket
eval pip install -q -r requirements.txt $verbosity
eval python setup.py install $verbosity && echo "[*] Impacket installed!" &

cd /opt/RsaCtfTool
eval pip3 install -r requirements.txt $verbosity
eval ln -sf /opt/RsaCtfTool/RsaCtfTool.py /usr/local/sbin/RsaCtfTool.py $verbosity

echo "[+] Installing pwntools"
eval pip install -q pwntools $verbosity && echo "[*] pwntools installed!" &

echo "[+] Installing python-paddingoracle API"
cd /opt/python-poodle
eval python2 setup.py install $verbosity && echo "[*] python-paddingoracle installed!" &

echo "[+] Installing Empire"
cd /opt/Empire
eval echo | eval setup/install.sh $verbosity && echo "[*] Empire installed!" &

cd /opt/onesixtyone
eval make $verbosity && ln -sf /opt/onesixtyone/onesixtyone /usr/local/sbin/onesixtyone & 

cd /opt/gobuster
eval go get $verbosity && go build -o /usr/bin/gobuster $verbosity \
	&& rm -rf /opt/gobuster $verbosity &

echo "[+] Installing and configuring Covenant/Elite"
cd /opt/Covenant/Covenant
git clone --recurse-submodules -q https://github.com/cobbr/Covenant
eval docker build -t covenant . $verbosity && echo "[*] Covenant installed"
cd /opt/Elite/Elite
eval docker build -t elite . -q $verbosity && echo "[*] Elite installed"


echo "[+] Customizing vim and tmux..."
rm $HOME/.vimrc 2>/dev/null 
ln -s $HOME/.vim/.vimrc $HOME/.vimrc
rm $HOME/.tmux.conf 2>/dev/null
ln -s $HOME/.vim/.tmux.conf $HOME/.tmux.conf
eval vim +'PlugUpdate --sync' +qall &>/dev/null &

echo "[+] Adding custom aliases..."
echo "alias ll='ls -alh'" >> $HOME/.bashrc

sed -i '/mibs/s/^/#/g' /etc/snmp/snmp.conf
echo "source $HOME/peda/peda.py" >> $HOME/.gdbinit

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


echo "[*] Setting Burp's java to 8 for compatibility"
eval echo "2" | eval update-alternatives --config java >/dev/null

echo "[*] Waiting for background processes to complete..."
wait
echo "[*] Done! Don't forget to change the root password!"
echo "[!] Note: curl may have issues with older ssl ciphers. If so try installing libssl-dev"
