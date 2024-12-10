#!/usr/bin/env bash

#Written by the guy who breaks things...

# I haven't set up debug yet but:
DEBUG=0

# Settings
NO_UNIGINE=0
INSTALL_CHECK=1
AUTOSTART_CHECK=0
# Used ^ for which autostart to use. If -ns is used, switches to 1 and uses "ss-autostart-ns.desktop to skip gpu tests"
# otherwise set to 0 which uses ss-autostart.desktop for skipping install checks
#this may be able to be moved to just "INSTAL_CHECK" :shrug: 

# Paths & Directorys
AUTOSTART_USER_PATH=/home/$(WHOAMI)/
SCRIPT_DIR=$(dirname "$0")
ASD_EXTERNAL_PATH=$SCRIPT_DIR/ss-autostart.desktop
ASD_NS_EXTERNAL_PATH=$SCRIPT_DIR/ss-autostart-ns.desktop

clear

# Do I need this?
#if ! [ -d SCRIPT_DIR ]; then
#    SCRIPT_DIR=~
#fi

whoami
sleep 5

install(){

#check and install git
if ! dpkg -l | grep -q git; then
    echo ""
    echo "Installing git"
    sudo apt install git -y > /dev/null 2>&1
    echo "Installed git"
    sleep 3
fi

# Installing git-lfs if not installed
if ! dpkg -l | grep -q git-lfs; then
    echo ""
    echo "Installing git-lfs"
    sudo apt install git-lfs -y > /dev/null 2>&1
    echo "Installed git-lfs"
    sleep 3
fi

# Clone the repository only if it doesn't already exist
if ! [ -d ~/stress-scripts ]; then
    echo "Cloning the stress-scripts repo..."
    git clone https://github.com/jacobktm/stress-scripts.git ~/stress-scripts > /dev/null 2>&1
    echo "The stress-scripts repo cloned successfully"
    sleep 3
fi

# Move this script to the users home folder if it is not there already
if [ -d ~/ss-setup.sh ]; then
    cp -r /media/$(whoami)/jonah/scripts/setup/ss-setup.sh ~/
    # Check if this script was actually moved to the users home folder
    if [ -d /home/$(whoami)/ss-setup.sh ]; then
        echo "Move of this script failed. Run manually or move script."
        exit
    fi
fi 

# if autostart=0 copy the ns script to /etc/xdg/autostart
if [ $AUTOSTART_CHECK -eq 0 ]; then
    if ! [ -d /etc/xdg/autostart/ss-autostart.desktop ]; then 
        whoami
        sudo cp -r $SCRIPT_DIR/ss-autostart.desktop /etc/xdg/autostart/
        if [ $DEBUG -eq 1 ]; then
            echo "Copied ss-autostart.desktop to users home folder."
            sleep 5
        fi
    fi
fi

# if autostart=1 copy the ns script to /etc/xdg/autostart
if [ $AUTOSTART_CHECK -eq 1 ]; then
    if ! [ -d /etc/xdg/autostart/ss-autostart-ns.desktop ]; then 
        whoami
        sudo cp -r $SCRIPT_DIR/ss-autostart-ns.desktop /etc/xdg/autostart/
        if [ $DEBUG -eq 1 ]; then
            echo "Copied ss-autostart-ns.desktop to users home folder."
            sleep 5
        fi
    fi
fi

# Install system updates, upgrade, then reboot 
echo "Installing updates"
sudo apt update && sudo apt full-upgrade -y
echo "Updates installed. System will reboot..."
sleep 5
echo "reboot point line 101"
echo "exiting"
sleep 2
exit
#reboot 

}

Help() {
    echo "Usage: ./ss-setup.sh [options]"
    echo "h       display this message and exit"
    echo ""
    echo "-------------------------------------------"
    echo ""
    echo "s       skip GPU stress tests"
    echo "n       do not check if deps are installed"
}

while getopts "hsnd" options; do
    case $options in
        h) # help menu
            Help
            exit;;
        s) # Doesn't use unigine
            NO_UNIGINE=1
            AUTOSTART_CHECK=1;;
        n) # Don't check if deps are installed. ss-autostart.desktop used for gpu tests
            INSTALL_CHECK=0;;
        d) # Enable debuging. Hidden from help menu
            DEBUG=1;;
        *) # Invalid option
            echo "Error: Invalid option" 1>&2
            Help 1>&2
            exit 1;;
    esac
done

# Run the install function unless -i switch is used
if [ $INSTALL_CHECK -eq 1 ]; then
    echo "Checking if all dependencys are installed "
    echo "and if the stress-tests repo is present in users home folder"
    sleep 3
    install
    sleep 3
fi

# Check for and remove trubble-checklist package
if dpkg -l | grep -i trubble-checklist > /dev/null 2>&1; then
    echo ""
    echo "Removing trubble-checklist"
    sudo dpkg --purge trubble-checklist > /dev/null 2>&1
    echo "trubble-checklist removed"
    sleep 3
fi

# Check if the stress-scripts dir is present then run w/ or w/o GPU stress tests
Run() {

# check if stress-scripts dir is present in users home folder
# if the folder is not present, the install function will run
if [ -d ~/stress-scripts ]; then
    cd ~/stress-scripts
else
install
fi

# Run the stress tests script with or without unigine based on the NO_UNIGINE flag
if [ $NO_UNIGINE -eq 0 ]; then
    echo "Running with GPU tests"
    sleep 2
    ./s76-stress-tests.sh
else
    echo "Running without GPU stress"
    sleep 2
    ./s76-stress-tests.sh -s
fi
}

Run


unused-code() {
#-----------------------------------------------#
 #unused. remove if wanted
 # Setup the reboot systemd service if it hasn't been already
 #if ! systemctl status >> temp.txt | cat temp.txt | grep -i streboot.service; then
 #    echo "test"
    # Setup the reboot systemd service if it hasn't been already
 #    if ! [ -d /etc/systemd/system/streboot.service ]; then
 #        echo "Moving file for system.d"
 #        sudo cp -r /media/$(whoami)/jonah/scripts/setup/streboot.service /etc/systemd/system/streboot.service
 #       echo "done"
 #    fi
    # Reload and start streboot.service
 #   echo "Daemon reload"
 #   sudo systemctl daemon-reload
 #   echo "starting service"
 #   sudo systemctl enable streboot.service
 #fi

 # Check if systemd service is working as intended
 #if systemctl status >> temp.txt | cat temp.txt | grep -i streboot.service; then
 #    echo "copy of systemd service file failed"
 #    if [ -d /etc/systemd/system/streboot.service ]; then
 #        echo "Moving file for system.d"
 #        sudo mv streboot.service /etc/systemd/system/streboot.service
 #    fi
    # Check again. If failed, exit script
 #    if ! systemctl status >> temp.txt | cat temp.txt | grep -i streboot.service; then
 #    echo "Failed to move file twice. Maybe do manually?"
 #    exit
 #    fi
 #fi

 # Check if service is installed but not enabled
 #if ! systemctl status streboot.service | grep "Active: inactive" ; then
 #    echo "systemd service failed to start. Attempting..."
 #    sudo systemctl enable streboot.service
 #    if ! 'systemctl status streboot.service | grep "Active: inactive"' ; then
 #        echo "Service did not start twice. Maybe run everything manually?"
 #        exit; else
 #        echo "Service started"
 #    fi
 #fi

 # Check if "-s" switch was passed eventually
 #if 
 #---------------------------------------------#
 #end unused
}