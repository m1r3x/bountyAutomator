#!/bin/bash

echo "Welcome to bountyAutomator!"
read -p "Enter domain name to be scanned: " domain
mkdir $domain

echo "Checking for binaries"
declare -a Tools=("amass" "httprobe" "eyewitness" "gobuster")

for tool in ${Tools[@]}; do
  if ! command -v $tool &> /dev/null
    then
      echo "$tool could not be found. Please install it to be able to use this script."
      exit
  fi
done


echo "Running Amass scan"
amass enum -active -d $domain -brute -w /usr/share/wordlists/SecLists/Discovery/DNS/deepmagic.com-prefixes-top50000.txt -timeout 120 -o $domain/amass_sub.txt
cat $domain/amass_sub.txt | sort -u | sponge $domain/amass_sub.txt

echo "Running httprobe"
cat $domain/amass_sub.txt | httprobe -prefer-https > $domain/httprobe.txt

echo "Running eyewitness"
eyewitness -f $domain/httprobe.txt --web --no-prompt --threads 10 -d $domain/eyewitness


echo "Running Gobuster"
touch $domain/gobuster.txt
input=$domain/httprobe.txt
while IFS= read -r url
do
  gobuster -u $url dir -w /usr/share/wordlists/dirb/big.txt -x txt,php,html,zip,js -t 50 -k -q -o $domain/new.txt -b 503,429
  echo -e "$url\n$(cat $domain/new.txt)" > $domain/new.txt
  cat $domain/new.txt >> $domain/gobuster.txt
  rm $domain/new.txt
done < "$input"
