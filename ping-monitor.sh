#!/bin/bash

# Function to list available network interfaces
list_interfaces() {
    # Use the `ip link` command to list network interfaces and filter out non-network interfaces
    interfaces=$(ip link show | grep -oP '^\d+: \K[^:]+')

    # Convert interfaces into an indexed array
    interface_array=($interfaces)

    echo "Available network interfaces:"
    for i in "${!interface_array[@]}"; do
        echo "$((i + 1)): ${interface_array[i]}"
    done

    PS3="Select network interfaces (multiple choices allowed, separated by commas, e.g., 1,2,3): "

    while true; do
        read -p "$PS3" choices
        if [[ $choices =~ ^[0-9]+(,[0-9]+)*$ ]]; then
            IFS=',' read -r -a selected_indices <<< "$choices"
            selected_interfaces=()
            for index in "${selected_indices[@]}"; do
                if ((index >= 1 && index <= ${#interface_array[@]})); then
                    selected_interfaces+=("${interface_array[index-1]}")
                else
                    echo "Invalid selection: $index. Please try again."
                    continue 2
                fi
            done
            echo "You selected: ${selected_interfaces[*]}"
            break
        else
            echo "Invalid input. Please use numbers separated by commas (e.g., 1,2,3)."
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

# Log file where failures and packet loss details will be logged
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

        # Ping the gateway using the selected interface and capture output
        ping_output=$(ping -I $interface -c 1 -W 1 $gateway 2>&1)
        ping_status=$?

        # Check if ping was successful
        if [ $ping_status -ne 0 ]; then
            # If ping failed, log the timestamp, failure, and output
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Ping to gateway $gateway failed on interface $interface" >> $log_file
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Ping to gateway $gateway failed on interface $interface"
        #else
            # Extract packet loss percentage from the ping output
            #packet_loss=$(echo "$ping_output" | grep -oP '\d+(?=% packet loss)')
            #echo "$(date '+%Y-%m-%d %H:%M:%S') - Ping to gateway $gateway on interface $interface succeeded with $packet_loss% packet loss" >> $log_file
        fi
    done

    # Wait for 1 second before trying again
    sleep 1
done
