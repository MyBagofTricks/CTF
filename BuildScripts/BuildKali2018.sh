#!/bin/bash
# Basic Kali build script to add key utilities and tweaks
echo "*** Starting Custom Kali build script. Use -v for verbose output ***"

# Add git packages here
declare -a githublist=("https://github.com/tdifg/WebShell.git /opt/WebShell"
	"https://github.com/FuzzySecurity/PowerShell-Suite /opt/PowerShell"
	"https://github.com/samratashok/nishang /opt/nishang"
	"https://github.com/411Hall/JAWS /opt/JAWS"
        "https://github.com/PowerShellMafia/PowerSploit /opt/PowerSploit"
        "https://github.com/CoreSecurity/impacket /opt/Impacket"
        "https://github.com/danielmiessler/SecLists.git /opt/SecLists"
        "https://github.com/radare/radare2.git /opt/radare2"
        "https://github.com/rebootuser/LinEnum.git /opt/LinEnum/"
        "https://github.com/MyBagofTricks/vimconfig.git /root/.vim"
	)

# Default to quiet output. Add -v for verbose
verbosity='&>/dev/null'
while getopts v o; do
	case $o in
		(v) verbosity=""
	esac
done

# Bail out if not run as root
if [[ $EUID -ne 0 ]]; then
        echo "This script needs root privileges"
        exit 1
fi

i=0 
tput sc 
while fuser /var/lib/dpkg/lock >/dev/null; do
     case $(($i % 4)) in
         0 ) j="-" ;;
         1 ) j="\\" ;;
         2 ) j="|" ;;
         3 ) j="/" ;;
     esac
     tput rc
     echo -en "\r[$j] Waiting for apt-get lock..." 
     sleep 0.5
     ((i++)) 
done

eval apt-get update $verbosity
if !(which git &>/dev/null); then
    eval apt-get install git -y $verbosity
fi

eval apt-get install gobuster ftp tor gcc-multilib g++-multilib golang tmux \
	exiftool ncat strace ltrace libreoffice gimp  -y "${verbosity}" & 

for url in "${githublist[@]}"; do
	eval git clone ${url} $verbosity &
done

eval curl -L https://github.com/radareorg/cutter/releases/download/v1.7.2/Cutter-v1.7.2-x86_64.Linux.AppImage > ~/Documents/Cutter-v1.7.2-x86_64.Linux.AppImage $verbosity &

echo "[ ] Installing packages and cloning repos. This may around 5 minutes..."
wait

# Secondary installation phase
eval apt-get remove radare2 -y $verbosity
cd /opt/radare2
echo "[ ] Installing radare2 from source..."
eval sys/install.sh $verbosity & 

rm ~/.vimrc 2>/dev/null 
ln -s ~/.vim/.vimrc ~/.vimrc
rm ~/.tmux.conf 2>/dev/null
ln -s ~/.vim/.tmux.conf ~/.tmux.conf
vim +PlugUpdate +qall

### Settings & tweaks
echo "alias ll='ls -alh'" >> ~/.bashrc

# Uncomment this section and add your key if you want to wipe and replace existing settings
#rm -rf ~/.ssh
#cat /dev/zero | ssh-keygen -t rsa -b 4096 -q -N '' -f ~/.ssh/id_rsa
#tee ~/.ssh/authorized_keys << 'EOF'
#ssh-rsa YOUR KEY GOES HERE
#EOF

#final block
wait

echo "[!] Done! Don't forget to change the root password!"
