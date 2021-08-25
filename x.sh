#!/bin/bash

echo "Welcome to bountyAutomator!"
read -p "Enter domain name to be scanned: " domain
mkdir $domain

echo "Running Amass scan"
amass enum -active -d $domain -brute -w /usr/share/wordlists/SecLists/Discovery/DNS/deepmagic.com-prefixes-top50000.txt -timeout 5 -o $domain/amass_sub.txt
cat $domain/amass_sub.txt | sort -u | sponge $domain/amass_sub.txt

echo "Running httprobe"
cat $domain/amass_sub.txt | httprobe -prefer-https > $domain/httprobe.txt

echo "Running eyewitness"
eyewitness -f $domain/httprobe.txt --web --threads 10 -d $domain/eyewitness

echo "Running Gobuster"
touch $domain/gobuster.txt
input=$domain/httprobe.txt
while IFS= read -r url
do
  gobuster -u $url dir -w /usr/share/wordlists/dirb/big.txt -x txt,php,html,zip,js -t 50 -k -q -o $domain/new.txt
  echo -e "$url\n$(cat $domain/new.txt)" > $domain/new.txt
  cat $domain/new.txt >> $domain/gobuster.txt
  rm $domain/new.txt
done < "$input"
