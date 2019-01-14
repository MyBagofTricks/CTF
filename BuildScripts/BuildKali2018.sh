#!/bin/bash
# This script installs various packages for Kali, creates ssh keys, and tweaks settings
# Easily download and run with:
#   wget --quiet -O https://github.com/MyBagofTricks/CTF/blob/master/BuildScripts/BuildKali2018.sh | bash

export DEBIAN_FRONTEND=noninteractive
export APTLIST="gobuster ftp tor gcc-multilib g++-multilib golang tmux
	exiftool ncat strace ltrace libreoffice gimp nfs-common 
	libssl-dev steghide snmp-mibs-downloader php-curl dbeaver"

## Add git packages here
# Async will not be used for these. Use tarballs for those
# Format: <url> <output dir>
declare -a githublist=(
	"https://github.com/MyBagofTricks/vimconfig.git /root/.vim"
)

# Format: ["url1"]="name1" ["url2"]="name2" etc
# The name will be used for the target directory in /opt
declare -A tarlist=(
	["https://github.com/tdifg/WebShell/tarball/master"]="WebShell"
	["https://github.com/FuzzySecurity/PowerShell-Suite/tarball/master"]="PowerShell" 
	["https://github.com/samratashok/nishang/tarball/master"]="nishang"
	["https://github.com/411Hall/JAWS/tarball/master"]="JAWS"
        ["https://github.com/PowerShellMafia/PowerSploit/tarball/master"]="PowerSploit"
        ["https://github.com/CoreSecurity/impacket/tarball/master"]="Impacket"
	["https://github.com/magnumripper/JohnTheRipper/tarball/master"]="JohnJumbo"
        ["https://github.com/danielmiessler/SecLists/tarball/master"]="SecLists"   
        ["https://github.com/radare/radare2/tarball/master"]="radare2"
        ["https://github.com/rebootuser/LinEnum/tarball/master"]="LinEnum"
	["https://github.com/trailofbits/onesixtyone/tarball/master"]="onesixone"
	["https://github.com/rasta-mouse/Sherlock/tarball/master"]="Sherlock"
	["https://github.com/EmpireProject/Empire/tarball/master"]="Empire"
	["https://github.com/SecWiki/windows-kernel-exploits/tarball/master"]="windows-kernel-exploits"
	["https://github.com/M4ximuss/Powerless/tarball/master"]="Powerless"
	["https://github.com/swisskyrepo/PayloadsAllTheThings/tarball/master"]="Payloads"
	["https://github.com/andrew-d/static-binaries/tarball/master"]="static-binaries"

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
# Disable suspend/sleep
eval systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target $verbosity
eval gsettings set org.gnome.desktop.session idle-delay 0 $verbosity

echo "[+] Downloading tarballs in background..."
for url in "${!tarlist[@]}"; do 
	eval mkdir -p /opt/${tarlist[$url]} && curl --silent -L $url -o - \
		| tar -xzC /opt/${tarlist[$url]} --strip-component=1 2>/dev/null &
done

lockCheck
echo "[+] Cloning GitHub Repos..."
for url in "${githublist[@]}"; do
	eval git clone ${url} $verbosity
done

eval curl --silent -L https://github.com/radareorg/cutter/releases/download/v1.7.2/Cutter-v1.7.2-x86_64.Linux.AppImage -o $HOME/Desktop/Cutter.AppImage \
	&& chmod +x $HOME/Desktop/Cutter.AppImage &

lockCheck
# Install packages one by one in case a package changes names
echo "[+] Installing packages via apt. This may take 5-10min depending on your bandwidth..."
for package in $APTLIST; do
	eval apt-get install ${package} -qy $verbosity
done

wait

## Secondary installation phase
# Build any packages downloaded in previous step here
lockCheck
echo "[*] Installing radare2 from source..."
eval apt-get remove radare2 -qy $verbosity
eval /opt/radare2/sys/install.sh $verbosity \
	&& echo "[^] radare2 installed!" &

echo "[*] Installing John the Ripper Community Edition..."
cd /opt/JohnJumbo/src
eval ./configure $verbosity 
eval make $verbosity \
	&& echo "[^] John the Ripper installed!" &

echo "[*] Installing Impacket..."
cd /opt/Impacket
eval pip install -q -r requirements.txt $verbosity
eval python setup.py install $verbosity \
	&& echo "[^] Impacket installed!" &

echo "[*] Installing pwntools..."
eval pip install -q pwntools $verbosity \
	&& echo "[^] pwntools installed!" &

cd /opt/onesixone
eval make $verbosity &

echo "[+] Customizing vim and tmux..."
rm $HOME/.vimrc 2>/dev/null 
ln -s $HOME/.vim/.vimrc $HOME/.vimrc
rm $HOME/.tmux.conf 2>/dev/null
ln -s $HOME/.vim/.tmux.conf $HOME/.tmux.conf
eval vim +'PlugUpdate --sync' +qall &>/dev/null &

echo "[+] Adding custom aliases..."
echo "alias ll='ls -alh'" >> $HOME/.bashrc

sed -i '/mibs/s/^/#/g' /etc/snmp/snmp.conf


echo "[+] Generating ssh key..."
rm -rf $HOME/.ssh
cat /dev/zero | ssh-keygen -t rsa -b 2048 -q -N '' -f ~/.ssh/id_rsa

# Uncomment this section and add your key if you want to wipe and replace existing settings
#tee ~/.ssh/authorized_keys << 'EOF'
#YOUR SSH KEY GOES HERE
#EOF

echo "[ ] Waiting for background processes to complete..."
wait

echo "[*] Done! Don't forget to change the root password!"
