#!/bin/bash
clear
# Menu Options
echo "---------------------------------------- Demo Tools ----------------------------------------";
echo ' ';
echo "----- Requirements: Docker must be installed on your computer before running this tool -----";
echo "- If Docker is not installed, press [7] and then Docker will be installed on your computer -";
echo ' ';
echo "---------------------------------------- Demo Tools ----------------------------------------";
echo "1. Port Scan"
echo "2. Brute Force Tool"
echo "3. Web Application Tools"
echo "4. Network Scan"
echo "5. Generating Malware Samples (Real Samples)"
echo "6. Generating a Vulnerable Web Application"
echo "7. Install Docker "
echo "8. Exit from menu "
echo -n "Enter your menu choice [1-8]: "

# Preparing the Application 
while :
do

# Reading Choice
read choice

# Executing the Application 
case $choice in
  # Option 1
  1)  echo "You have selected the option 1"
    clear
    echo '--------------------------'  
    echo '---------- NMAP ----------'
    echo 'Target IP Address: '
    read NMAPIP 
    echo ' ' 
    echo 'Running the NMAP Scan..'  
    docker run --rm -it andrefernandes86/tools-nmap -A -T4 $NMAPIP
    echo ' ' 
    read -p "Press any key to continue.."
    sleep 3
    clear
    echo "1. Port Scan"
    echo "2. Brute Force Tool"
    echo "3. Web Application Tools"
    echo "4. Network Scan"
    echo "5. Generating Malware Samples (Real Samples)"
    echo "6. Generating a Vulnerable Web Application"
    echo "7. Install Docker "
    echo "8. Exit from menu "
    echo -n "Enter your menu choice [1-8]: "
    echo "";;
  # Option 2
  2)  echo "You have selected the option 2"
    clear
    echo '---------------------------'  
    echo '---------- HYDRA ----------'
    echo 'Target IP Address: '
    read HYDRAIP 
    echo ' ' 
    echo 'Target Port: '
    read HYDRAPORT 
    echo ' ' 
    echo 'Running the HYDRA Brute Force..'  
    docker run --rm andrefernandes86/tools-hydra -L /opt/usernames/top-usernames-shortlist.txt -P /opt/passwords/darkweb2017-top100.txt -f -V -s $HYDRAPORT $HYDRAIP http-get
    echo ' ' 
    read -p "Press any key to continue.."
    sleep 3
    clear
    echo "1. Port Scan"
    echo "2. Brute Force Tool"
    echo "3. Web Application Tools"
    echo "4. Network Scan"
    echo "5. Generating Malware Samples (Real Samples)"
    echo "6. Generating a Vulnerable Web Application"
    echo "7. Install Docker "
    echo "8. Exit from menu "
    echo -n "Enter your menu choice [1-8]: "
    echo "";;
    # Option 3
  3)  echo "You have selected the option 3"
    clear
    echo '-----------------------------------'  
    echo '---------- Web App Tools ----------'
    echo ' ' 
    echo 'Running the Web App Tools..'  
    docker run --rm -d -p 222:22 -p 7331:7331 -p 9292:9292 arachni/arachni:latest --name webtools
    echo ' ' 
    echo ' URL: http://$ip-address:9292 '
    echo ' Username: admin@admin.admin '
    echo ' Password: administrator '
    echo ' ' 
    read -p "Press any key to continue.."
    echo ' ' 
    sleep 3
    docker kill webtools
    clear
    echo "1. Port Scan"
    echo "2. Brute Force Tool"
    echo "3. Web Application Tools"
    echo "4. Network Scan"
    echo "5. Generating Malware Samples (Real Samples)"
    echo "6. Generating a Vulnerable Web Application"
    echo "7. Install Docker "
    echo "8. Exit from menu "
    echo -n "Enter your menu choice [1-8]: "
    echo "";;
  # Option 4
  4)  echo "You have selected the option 4"
    clear
    echo '-----------------------------------'  
    echo '---------- Network Scan ----------'
    echo ' ' 
    echo 'Running the Network Scan..'  
    echo 'Target IP Address: '
    read NETIP 
    echo ' ' 
    echo 'Target PORT: '
    read NETPORT 
    echo ' ' 
    docker run --rm -it --privileged --net=host -e TARGET_DOMAIN=$NETIP:$NETPORT andrefernandes86/tools-pentest
    echo ' ' 
    read -p "Press any key to continue.."
    echo ' ' 
    sleep 3
    clear
    echo "1. Port Scan"
    echo "2. Brute Force Tool"
    echo "3. Web Application Tools"
    echo "4. Network Scan"
    echo "5. Generating Malware Samples (Real Samples)"
    echo "6. Generating a Vulnerable Web Application"
    echo "7. Install Docker "
    echo "8. Exit from menu "
    echo -n "Enter your menu choice [1-8]: "
    echo "";;
  # Option 5
  5)  echo "You have selected the option 5"
    clear
    echo '-------------------------------------'  
    echo '---------- Malware Samples ----------'
    echo ' ' 
    echo 'Creating the webserver and adding the malware samples..'  
    docker run --rm -d -p 80:80 andrefernandes86/tools-malware-samples --name malware
    echo ' ' 
    echo ' URL: http://$ip-address '
    echo ' ' 
    read -p "Press any key to continue.."
    sleep 3
    docker kill malware
    clear
    echo "1. Port Scan"
    echo "2. Brute Force Tool"
    echo "3. Web Application Tools"
    echo "4. Network Scan"
    echo "5. Generating Malware Samples (Real Samples)"
    echo "6. Generating a Vulnerable Web Application"
    echo "7. Install Docker "
    echo "8. Exit from menu "
    echo -n "Enter your menu choice [1-8]: "
    echo "";;
    # Option 6
  6)  echo "You have selected the option 6"
    clear
    echo '------------------------------------------------'  
    echo '---------- Vulnerable Web Application ----------'
    echo ' ' 
    echo 'Creating the webserver and adding the malware samples..'  
    docker run --rm -p 81:80 andrefernandes86/demo-aws-c1ns-vulnerable-webserver --name wsrv
    echo ' ' 
    echo ' URL: http://$ip-address:81 '
    echo ' Username: admin '
    echo ' Password: password '
    echo ' ' 
    read -p "Press any key to continue.."
    sleep 3
    docker kill wsrv
    clear
    echo "1. Port Scan"
    echo "2. Brute Force Tool"
    echo "3. Web Application Tools"
    echo "4. Network Scan"
    echo "5. Generating Malware Samples (Real Samples)"
    echo "6. Generating a Vulnerable Web Application"
    echo "7. Install Docker "
    echo "8. Exit from menu "
    echo -n "Enter your menu choice [1-8]: "
    echo "";;
    7)  echo "You have selected the option 7"
    clear
    apt-get update -y
    curl -fsSL https://get.docker.com | sh
    clear
    echo "1. Port Scan"
    echo "2. Brute Force Tool"
    echo "3. Web Application Tools"
    echo "4. Network Scan"
    echo "5. Generating Malware Samples (Real Samples)"
    echo "6. Generating a Vulnerable Web Application"
    echo "7. Install Docker "
    echo "8. Exit from menu "
    echo -n "Enter your menu choice [1-8]: "
    echo "";;
  # Option 7
  8)  echo "Quitting ..."
    echo ' Cleaning the demo environment'
    docker systen prune
      exit;;
  
  # Default Pattern
  *) echo "invalid option";;
  
esac
  echo -n "Enter your menu choice [1-8]: "
done
