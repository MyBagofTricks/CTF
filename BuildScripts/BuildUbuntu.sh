#!/bin/bash

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

declare -a githublist=("https://github.com/tdifg/WebShell.git /opt/WebShell"
	"https://github.com/FuzzySecurity/PowerShell-Suite /opt/PowerShell"
	"https://github.com/samratashok/nishang /opt/nishang"
	"https://github.com/411Hall/JAWS /opt/JAWS"
        "https://github.com/PowerShellMafia/PowerSploit /opt/PowerSploit"
        "https://github.com/CoreSecurity/impacket /opt/Impacket"
        "https://github.com/danielmiessler/SecLists.git /opt/SecLists"
        "https://github.com/radare/radare2.git /opt/radare2"
        "https://github.com/rebootuser/LinEnum.git /opt/LinEnum/")

# Install git if not found
apt-get update
if !(which git); then
    apt-get install git -y
fi

apt-get install sleuthkit ftp vim tor gcc-multilib g++-multilib golang tmux exiftool socat nmap proxychains socat nodejs-legacy libzip-dev npm curl pkg-config python-pip python3-pip ruby strace ltrace atftpd    -y &

depriv curl -L https://github.com/radareorg/cutter/releases/download/v1.7.2/Cutter-v1.7.2-x86_64.Linux.AppImage > ~/Documents/Cutter-v1.7.2-x86_64.Linux.AppImage &

for url in "${githublist[@]}"; do
	git clone ${url} &
done

depriv git clone https://github.com/MyBagofTricks/vimconfig.git ~/.vim
wait

# get latest nodejs
curl -sL https://deb.nodesource.com/setup_10.x | sudo bash -
apt install nodejs -y &

#forensic toolkit
add gem install origami &
wait


#all stuff radare2
apt-get remove radare2
cd /opt/radare2
sys/install.sh
r2pm init
r2pm -ci r2frida &

# set tmux and vim symlinks
depriv ln -s ~/.vim/.vimrc ~/.vimrc
depriv ln -s ~/.vim/.tmux.conf ~/.tmux.conf
depriv rm -rf ~/.vim/plugins/*
depriv vim +PlugInstall +qall

wait
