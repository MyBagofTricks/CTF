#!/bin/bash
# Basic Ubuntu build script to add key utilities and tweaks
echo "*** Starting Custom Ubuntu build script***"
echo "**Use -v for verbose output to stdout**"
BUILD_DIR=$PWD/build
mkdir -p $BUILD_DIR &>/dev/null

declare -a commandList=("git clone https://github.com/tdifg/WebShell.git /opt/Shells/WebShell"
	"git clone https://github.com/FuzzySecurity/PowerShell-Suite /opt/Shells/PowerShell"
	"git clone https://github.com/samratashok/nishang /opt/Shells/nishang"
	"git clone https://github.com/411Hall/JAWS /opt/Enum/JAWS"
        "git clone https://github.com/PowerShellMafia/PowerSploit /opt/Shells/PowerSploit"
        "git clone https://github.com/CoreSecurity/impacket /opt/Shells/Impacket"
        "git clone https://github.com/danielmiessler/SecLists.git /opt/Enum/SecLists"
        "git clone https://github.com/radare/radare2.git /opt/radare2"
	"git clone https://github.com/rebootuser/LinEnum.git /opt/Enum/LinEnum/"
	"git clone https://github.com/MyBagofTricks/vimconfig.git $HOME/.vim"
	"curl -s https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb -o $BUILD_DIR/msfinstall"
	"curl -sL https://deb.nodesource.com/setup_10.x -o $BUILD_DIR/setup_10.x")

declare -a aptPackages=("pkg-config sleuthkit ftp vim tor gcc-multilib \
	g++-multilib golang tmux exiftool socat nmap proxychains socat \
	libzip-dev openssh-server npm curl python-pip python3-pip ruby \
	openssh-server strace ltrace atftpd gddrescue gdb") 

# Bail out if not run as root
if [[ $EUID -ne 0 ]]; then
        echo "This script needs root privileges"
        exit 1
fi

# Drop root priv for user specific files
depriv() {
  if [[ $SUDO_USER ]]; then
    sudo -u "$SUDO_USER" -- "$@"
  else
    "$@"
  fi
}

# Default to quiet output. Add -v for verbose
verbosity='&>/dev/null'
while getopts v o; do
        case $o in
		(v) verbosity=''
        esac
done

i=0 
while fuser /var/lib/dpkg/lock &>/dev/null; do
    echo -ne "\r[!] Waiting for apt lock. If this persists, try rebooting. $i seconds..."
    sleep 1
    ((i++)) 
done

eval apt-get update $verbosity
if !(which git &>/dev/null); then
    eval apt-get install git -y $verbosity
fi

echo "[ ] Downloading source packages"
for cmd in "${commandList[@]}"; do
	eval ${cmd} $verbosity &
done

echo "[ ] Installing base packages (build essentials, git, etc)"
# Install Base Development Tools if not found
if !(dpkg --get-selections  | grep "build-essential" &>/dev/null); then
    eval apt-get install build-essential -y $verbosity
fi

# Install packages one by one in case a package changes names
echo "[ ] Installing main packages and cloning repos. This may take around 10 minutes..."
for package in ${aptPackages[@]}; do
	eval apt-get install ${package} -y $verbosity
done

wait
echo "[ ] Installing secondary packages"
eval add gem install origami $verbosity &
chmod 755 $BUILD_DIR/setup_10.x && eval $BUILD_DIR/setup_10.x $verbosity
eval apt install nodejs -y $verbosity 

chmod 755 $BUILD_DIR/msfinstall && eval $BUILD_DIR/msfinstall $verbosity &

#all stuff radare2
eval apt-get remove radare2 $verbosity
eval /opt/radare2/sys/install.sh $verbosity
eval r2pm init $verbosity
eval r2pm -ci r2frida $verbosity & 

# set tmux and vim symlinks
chown $SUDO_USER:$SUDO_USER -R $HOME/.vim
depriv ln -s $HOME/.vim/.vimrc $HOME/.vimrc
depriv ln -s $HOME/.vim/.tmux.conf $HOME/.tmux.conf
rm -rf $HOME/.vim/plugins/* 2>/dev/null
depriv vim +PlugInstall +qall

wait

#Final Cleanup
rm -rf $BUILD_DIR

clear && echo "[!] Done!"
