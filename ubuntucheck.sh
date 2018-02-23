#!/bin/bash
clear
sudo echo '
######################################################################################
# Tobii Ubuntu 16 realmd setup check & Nvidia 1050/1070/1080 check/install by Pierre #
######################################################################################'
echo ""
# ~~~~~~~~~~  Environment Setup ~~~~~~~~~~ #
    NORMAL=$(echo "\033[m")
    MENU=$(echo "\033[36m") #Blue
    NUMBER=$(echo "\033[33m") #yellow
    RED_TEXT=$(echo "\033[31m") #Red
    INTRO_TEXT=$(echo "\033[32m") #green and white text
    END=$(echo "\033[0m")
# ~~~~~~~~~~  Environment Setup ~~~~~~~~~~ #
echo ""
echo "${MENU}"Checking kernel information"${END}"
echo ""
hostnamectl status | sudo tee -a computerInfoOutput_${USER}.txt
echo ""
echo "___________________________________________________________________"
echo ""
echo ""
echo ""
echo "${MENU}"Checking Hardware information"${END}"
echo ""
sudo lshw -short | grep -E "(system|System Memory|processor)" | sudo tee -a computerInfoOutput_${USER}.txt
lspci | grep VGA | sudo tee -a computerInfoOutput_${USER}.txt
echo ""
echo "${MENU}"Checking network"${END}"
ifconfig | awk '{print $2}' | grep addr | head -1
speed=$( ping -q -w 1 -c 1 `ip r | grep default | cut -d ' ' -f 3` | grep max | awk '{print$4}' | cut -d '/' -f1)
echo "$speed ms"
ping -q -w 1 -c 1 `ip r | grep default | cut -d ' ' -f 3` > /dev/null && echo "Network is working" || echo "NO NETWORK"
echo ""
echo ""
echo "${MENU}"Checking disk space of disks"${END}"
echo ""
disk=$( df -Pm | awk '+$5 >=85  {print $1 " - " $5}' )
space=$( df -Pm | awk '+$5 >=85  {print $5}' | cut -d '%' -f1 )
totaldisk=$( df -h | awk '+$5 >=85  {print $1 " - " $2}' | cut -d '-' -f3 )
if [ "$space" ">" "85" ]
then
echo "I detected a space that seems to be getting full= $disk used of"$totaldisk""
echo ""
echo "trying to find large logs...."
echo ""
find / -name "*.log" -type f -size +200M -exec ls -lh {} \; 2> /dev/null | awk '{ print $NF ": " $5 }' | sort -nrk 2,2
echo ""
echo "trying to find large files...."
echo ""
find / -name "*" -type f -size +300M -exec ls -lh {} \; 2> /dev/null | awk '{ print $NF ": " $5 }' | sort -nrk 2,2
echo "___________________________________________________________________"
else
echo "${MENU}"Disk space looks good"${END}"
echo ""
echo "___________________________________________________________________"
fi
echo ""
echo ""
echo "${MENU}"Checking realm setup"${END}"
echo ""
sudo service sssd restart
export HOSTNAME
myhost=$( hostname )
grouPs=$( echo null )
therealm=$( echo null )
cauth=$( echo null )
therealm=$(realm discover $DOMAIN | grep -i configured: | cut -d ':' -f2 | sed -e 's/^[[:space:]]*//')
if [ "$therealm" = no ]
then
echo Realm configured?.. "${RED_TEXT}"FAIL"${END}"
else
echo Realm configured?.. "${INTRO_TEXT}"OK"${END}"
fi
if [ -f /etc/sudoers.d/sudoers ]
then
echo Checking sudoers file..  "${INTRO_TEXT}"OK"${END}"
else
echo checking sudoers file..  "${RED_TEXT}"FAIL"${END}"
fi
grouPs=$(cat /etc/sudoers.d/sudoers | grep -i $myhost | cut -d '%' -f2 | cut -d  '=' -f1 | sed -e 's/\<ALL\>//g')
solocal=$( cat /etc/sudoers.d/sudoers | grep -i $myhost | awk '{ print $1}' )
if [ $grouPs = "$myhost""sudoers" ]
then
echo "Checking group $solocal "${INTRO_TEXT}"OK"${END}""
else
echo Checking sudoers users.. "${RED_TEXT}"FAIL"${END}"
fi
homedir=$(cat /etc/pam.d/common-session | grep homedir | grep 0022 | cut -d '=' -f3)
if [ $homedir = 0022 ]
then
echo Checking PAM configuration.. "${INTRO_TEXT}"OK"${END}"
else
echo Checking PAM configuration.. "${RED_TEXT}"FAIL"${END}"
fi
echo "Disabled SSH login.group.allowed"
cauth=$(cat /etc/pam.d/common-auth | grep required | grep onerr | grep allow | cut -d '=' -f4 | cut -d 'f' -f1)
if [ $cauth = allow ]
then
echo Checking PAM auth configuration.. "${INTRO_TEXT}"OK"${END}"
else
echo Checking PAM auth configuration.. "${RED_TEXT}"FAIL"${END}"
fi
echo "___________________________________________________________________"
echo ""
echo "${MENU}"Checking graphic cards"${END}"
echo ""
var=$( sudo lspci | grep -i nvidia | head -1 | awk '{print $8}' )
ver=$( modinfo nvidia | grep -i version | head -1 | awk '{print $2}' )
if [ "$var"  = "1b81" ] || [ "$var"  = "1b80" ] || [ "$var" = "1070" ] || [ "$var" = "1080" ] || [ "$var" = "1c81" ] || [ "$var" = "1050" ]
then
if [ "$ver" = "387.34" ]
then
echo "Detected NVIDIA 1050/1070/1080"
echo "${INTRO_TEXT}"Correct Nvidia driver version '(' $ver ')' already installed.."${END}"
read -p "Do you wish to reinstall the 1070/1080 driver (y/n)?" yn
case $yn in
    [Yy]* ) echo "${INTRO_TEXT}"Reinstalling Nvidia 1050/1070/1080"${END}"
sudo service lightdm stop
sudo apt-get purge xserver-xorg-video-nouveau -y
sudo apt-get purge nvidia-*
sudo wget http://us.download.nvidia.com/XFree86/Linux-x86_64/387.34/NVIDIA-Linux-x86_64-387.34.run
sudo chmod +x NVIDIA-Linux-x86_64-387.34.run
sudo ./NVIDIA-Linux-x86_64-387.34.run -silent
sudo service lightdm start
sudo rm NVIDIA-Linux*.run;;
    [Nn]* ) echo ""
    exit;;
esac
else
echo "Driver for NVIDIA $ver is not installed but i detected a NVIDIA 1050/1070/1080 Hardware"
echo ""
echo "${MENU}"Installing driver.. Hold on"${END}"
echo ""
sleep 2
sudo service lightdm stop
sudo apt-get purge xserver-xorg-video-nouveau -y
sudo apt-get purge nvidia-*
sudo wget http://us.download.nvidia.com/XFree86/Linux-x86_64/387.34/NVIDIA-Linux-x86_64-387.34.run
sudo chmod +x NVIDIA-Linux-x86_64-387.34.run
sudo ./NVIDIA-Linux-x86_64-387.34.run -silent
sudo service lightdm start
sudo rm NVIDIA-*.run
echo ""
ver=$( modinfo nvidia | grep -i version | head -1 | awk '{print $2}' )
sleep 3
sudo echo "${INTRO_TEXT}"Current driver is '(' $ver ')' "${END}"
echo ""
fi
else
echo ""
sudo echo "${RED}"FAIL. No Nvidia 1050,1070 or 1080 card detected"${END}"
fi
