#!/bin/bash

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'
origIFS="${IFS}"

if [ -z $1 ]; then
	echo "Usage: $0 <HOST>"
	exit
else
	host=$1
fi

enum_all_port ()
{
	printf "\n${YELLOW}Scanning openning port ...\n${NC}"
	
	ports=$(nmap -sS -p- --min-rate 1000 $host | grep ^[0-9] | cut -d '/' -f1 | tr '\n' ',' | sed s/,$//)

	if [ -z $ports ]; then
		printf "${RED}[-] Found no openning port!${NC}"
		exit
	else
		printf "${GREEN}[+] Openning ports: $ports\n${NC}"
		array_ports=$(echo $ports | tr ',' '\n')
	fi
}

enum_open_service ()
{
	printf "\n${YELLOW}===============================services===============================\n${NC}"

	echo "nmap -sC -sV $1 -p$2"
	nmap -sC -sV $host -p$ports
}

enum_vuln_service ()
{
	printf "\n${YELLOW}===============================vuln===============================\n${NC}"

	echo "nmap --script vuln $1 -p$2"
	nmap --script vuln $host -p$ports
}

enum_smtp_service ()
{
	printf "\n${YELLOW}===============================$port===============================\n${NC}"

	echo "nmap $host -p$port --script=smtp-*"
	nmap $host -p$port --script=smtp-*
}

enum_http_service ()
{
	printf "\n${YELLOW}===============================$port===============================\n${NC}"

	echo "gobuster dir -u http://$host -w /usr/share/seclists/Discovery/Web-Content/common.txt"
	gobuster dir -u http://$host -w /usr/share/seclists/Discovery/Web-Content/common.txt
}

enum_https_service ()
{
	printf "\n${YELLOW}===============================$port===============================\n${NC}"

	echo "gobuster dir -k -u https://$host -w /usr/share/seclists/Discovery/Web-Content/common.txt"
	gobuster dir -k -u https://$host -w /usr/share/seclists/Discovery/Web-Content/common.txt
}

enum_smb_service ()
{
	printf "\n${YELLOW}===============================$port===============================\n${NC}"

	echo "smbmap -H $host"
	smbmap -H $host

	echo "smbclient -L $host"
	smbclient -L $host
}

recon ()
{
	for port in $array_ports; do
		case $port in

			"25")
				enum_smtp_service $host $port
			;;

			"80")
				enum_http_service $host $port
			;;

			"443")
				enum_https_service $host $port
			;;

			"139" | "445")
				enum_smb_service $host $port
			;;

			*)
				printf ""
			;;
		esac
	done
}

main ()
{
	enum_all_port $host
	
	enum_open_service $host $ports

	enum_vuln_service $host $ports

	recon $array_ports
}

main