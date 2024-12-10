#!/bin/bash

# Function to list available network interfaces
list_interfaces() {
    # Use the `ip link` command to list network interfaces and filter out non-network interfaces
    interfaces=$(ip link show | grep -oP '^\d+: \K[^:]+')

    echo "Available network interfaces:"
    PS3="Select network interfaces (multiple choices allowed, e.g., 1 2 3): "
    select interface in $interfaces; do
        if [[ -n "$interface" ]]; then
            selected_interfaces+=("$interface")
            echo "You selected: $interface"
        else
            echo "Invalid selection, please try again."
        fi

        # Ask if the user wants to select more interfaces or proceed
        read -p "Do you want to select another interface? (y/n): " choice
        if [[ "$choice" != "y" ]]; then
            break
        fi
    done
}

# Function to get the gateway for a selected interface
get_gateway() {
    gateway=$(ip route show dev $interface | grep default | awk '{print $3}')
    if [[ -n "$gateway" ]]; then
        echo "Gateway for $interface is: $gateway"
    else
        echo "No gateway found for $interface."
        exit 1
    fi
}

# Get available interfaces
list_interfaces

# Log file where failures will be logged
log_file="ping_failures.log"

# Loop through selected interfaces and get their gateways
for interface in "${selected_interfaces[@]}"; do
    get_gateway "$interface"
done

# Infinite loop to keep pinging the gateways of the selected interfaces
while true; do
    for interface in "${selected_interfaces[@]}"; do
        # Get the gateway for the current interface
        gateway=$(ip route show dev $interface | grep default | awk '{print $3}')

        # Ping the gateway using the selected interface
        ping -I $interface -c 1 -W 1 $gateway > /dev/null

        # Check if ping was successful
        if [ $? -ne 0 ]; then
            # If ping failed, log the timestamp and failure
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Ping to gateway $gateway failed on interface $interface" >> $log_file
        fi
    done
    
    # Wait for 1 second before trying again
    sleep 1
done

