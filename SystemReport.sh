#!/bin/bash

################################################################
#                                                              #
#   MACHINE REPORT                                             #
#   -------------                                              #
#	                                                       #
#   -> Last Update:           01/27/2025                       #
#                                                              #
#   -> Author:                Pedro Sartori Giorgetti          #
#	-> Email:                 pedsar@gmail.com             #
#	-> Operating System:      Fedora                       #
#                                                              #
#   -> Description:                                            #
#	This project aims to implement the                     #
#  	  content I have learned. The script                   #
#	  generates a machine report, updates                  #
#	  it every five seconds, and includes                  #
#	  the option to send the report to your                #
#	  email.                                               #
#                                                              #
#   -> Requirements:                                           #
#       - Library: lsb_relase                                  #
#       - Configure SSMTP                                      #
#                                                              #
################################################################

get_period_of_day() {
	local current_time=$1

	if [[ $current_time -ge 6 && $current_time -le 11 ]]
	then
		echo "Good Morning"
	fi

	if [[ $current_time -ge 12 && $current_time -le 18 ]]
	then
		echo "Good Afternoon"
	fi

	if [[ $current_time -ge 19 || $current_time -le 5 ]]
	then
		echo "Good Evening"
	fi
}

generate_greeting_message () {
	local current_time=$(date +%H)
	local greet_by_time=$(get_period_of_day "$current_time")
	echo -e "\n$greet_by_time, $USER!"
}

press_any_key_to_continue(){
    echo -e "\n Press any key to continue..."
	read -n1
}

convert_mb_to_gb(){
    local mb_value=$1
    local gb_value=$(echo "scale=2; $mb_value /1024" | bc)
    echo "$gb_value GB"
}

get_ram_total(){
    local ram_total=$(free -m | awk '/Mem:/ {print $2}')
    ram_total=$(convert_mb_to_gb "$ram_total")
    echo "$ram_total"
}

get_ram_usage() {
    local ram_usage=$(free -m | awk '/Mem:/ {print $3}')
    ram_usage=$(convert_mb_to_gb "$ram_usage")
    echo "$ram_usage"
}

get_kernel_version(){
    echo $(uname -r)
}

get_distro(){
    echo $(uname -a | awk '{print $1, $2}')
}

get_os_version(){
    echo $(lsb_release -a 2>/dev/null | grep "Description" | cut -f2-)
}

get_hostname(){
    echo $(hostname)
}

get_architecture(){
    echo $(uname -m)
}

get_cpu_number(){
    echo $(grep -c "model name" /proc/cpuinfo)
}

get_cpu_model(){
    echo $(grep "model name" /proc/cpuinfo | head -n1 | cut -c14-)
}

get_disk_capacity(){
    echo $(df --block-size=1G --total | awk '/^total/ {print $2}')
}

get_file_system(){
    df -hT | awk 'NR==1 || !/tmpfs|udev/' | column -t
}

hardware_information() {
    echo " - Kernel Version: $(get_kernel_version)"
    echo " - Distro: $(get_distro)"
    echo " - OS Version: $(get_os_version)"
    echo " - Architecture: $(get_architecture)"
    echo " - CPU Model: $(get_cpu_model)"
    echo " - CPU Cores: $(get_cpu_number)"
    echo " - Total RAM: $(get_ram_total)"
    echo " - Hostname: $(get_hostname)"
    echo " - Total Disk Capacity: $(get_disk_capacity) GB"
    echo -e "\n - File System Information:"
    echo "$(get_file_system)"
}

get_task_info() {
    local tasks_info=$(top -b -n1 | grep "Tasks:" | awk '{print $2, $4, $6, $8, $10}')
    local total_tasks=$(echo $tasks_info | awk '{print $1}')
    local running_tasks=$(echo $tasks_info | awk '{print $2}')
    local sleeping_tasks=$(echo $tasks_info | awk '{print $3}')
    local stopped_tasks=$(echo $tasks_info | awk '{print $4}')
    local zombie_tasks=$(echo $tasks_info | awk '{print $5}')

     echo -e "\n - Total Tasks: $total_tasks\n   - Running Tasks: $running_tasks\n   - Sleeping Tasks: $sleeping_tasks\n   - Stopped Tasks: $stopped_tasks\n   - Zombie Tasks: $zombie_tasks"
}

get_network_name() {
    local network_name=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2)

    if [ -z "$network_name" ]
    then
        network_name=$(nmcli -t -f DEVICE,STATE connection show --active | grep "connected" | awk '{print $1}')

        if [ -n "$network_name" ]
        then
            echo "Connected via Ethernet: $network_name"
        else
            echo "No active network connection."
        fi
    else
        echo "Connected via Wi-Fi: $network_name"
    fi
}

get_cpu_usage(){
    echo $(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
}

get_cpu_temperature(){
    echo $(cat /sys/class/thermal/thermal_zone0/temp)
}

get_cpu_temperature_in_celcius(){
    echo "$(echo "scale=1; $(get_cpu_temperature) /1000" | bc)"
}

get_disk_usage_percentage(){
    echo $(df -h / | awk 'NR==2 {print $5}')
}

get_uptime(){
    echo $(uptime -s)
}

get_ip_address(){
    echo $(hostname -I | awk '{print $1}')
}

get_top_three_process(){
    echo -e "$(ps -eo pid,%cpu,%mem,comm --sort=-%cpu | head -n 4)\n"
}

get_last_three_logs(){
    echo -e "$(journalctl -p err -n 3)\n"
}

generate_machine_report(){
        clear 
        echo " - Last Update: $(date '+%y-%m-%d %H:%M:%S')"
        echo " - CPU Usage: $(get_cpu_usage)%"
        echo " - CPU Temperature: $(get_cpu_temperature_in_celcius) ºC"
        echo " - Memory Usage: $(get_ram_usage) / $(get_ram_total)"
        echo " - Disk Usage: $(get_disk_usage_percentage)"
        echo " - System Uptime: $(get_uptime)"
        echo " - $(get_network_name)"
        echo " - IP Address: $(get_ip_address)"
        echo -e "$(get_task_info)"
        echo -e "\n - The three heaviest processes\n$(get_top_three_process)" 
        echo -e "\n - The three last logs:\n$(get_last_three_logs)"
}

connection_internet_test(){
    ping -c 1 google.com &> /dev/null

    if [ $? -eq 0 ]
    then
        echo "Ping successful!"
    else
        echo "Internet connection error"
    fi
}

is_connected_to_the_internet(){
    if connection_internet_test | grep -q "Internet connection error" 
     then
        echo "false"
    else
        echo "true"
    fi
}

machine_report(){
    while [ 1 ]
    do
	    generate_machine_report      	
        echo -e "\n Press any key to exit!"
        read -n1 -t5 key 2>/dev/null

        if [ $? -eq 0 ]
        then
           break
        fi
    done
}

create_report_file(){
    echo -e "\nMACHINE REPORT\n\n" >> Machine_Report	  
    hardware_information >> Machine_Report
    echo -e "\n\n" >> Machine_Report
    generate_machine_report | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' >> Machine_Report
}    

request_user_email(){
	read -p " Enter your email address: " user_email
	echo "$user_email"
}

send_email(){
    local user_email=$1    
   
	if [[ "$(is_connected_to_the_internet)" == "true" ]]
    then
	   create_report_file
       clear 
       echo " Sending an email..."
       ssmtp $user_email < Machine_Report
	   press_any_key_to_continue
	   rm Machine_Report
    else
        clear
	    echo -e "\n The device was not connected to the internet!"
	    press_any_key_to_continue
    fi
}

are_all_null(){
    local parameters=("$@")

    for param in "%{parameters[@]}"
    do
        if [[ -n "$ param" ]]
        then
            return 1
        fi
    done
    return 0
}

set_alert_cpu_usage() {
    local cpu_usage_parameter
    read -p " - Set the max CPU usage (%) [Default: 80%]: " cpu_usage_parameter
    cpu_usage_parameter=${cpu_usage_parameter:-80}
    echo "$cpu_usage_parameter"
}

set_alert_cpu_temperature(){
    local cpu_temperature_parameter
    read -p " - Set the max CPU temperature (ºC) [Default: 50ºC]: " cpu_temperature_parameter
    cpu_temperature_parameter=${cpu_temperature_parameter:-50}
    echo "$cpu_temperature_parameter"
}

set_alert_ram_usage(){
    local ram_usage_parameter
    read -p " - Set the max RAM usage (%) [Default: 80%]: " ram_usage_parameter
    ram_usage_parameter=${ram_usage_parameter:-80}
    echo "$ram_usage_parameter"
}

set_alert_disk_usage(){
    local disk_usage_parameter
    read -p " - Set the max Disk usage (%) [Default: 80%]: " disk_usage_parameter
    disk_usage_parameter=${disk_usage_parameter:-80}
    echo "$disk_usage_parameter"
}

get_ram_usage_percentage() {
    usage=$(get_ram_usage | sed 's/ GB//')
    total=$(get_ram_total | sed 's/ GB//')
    echo "scale=2; ($usage/$total)*100" | bc
}

is_over_limit(){
    local parameter=$1
    local current_value=$2
       
     if [[ $(echo "$current_value >= $parameter" | bc -l) -eq 1 ]]
     then
        echo "TRUE"
     else
        echo "FALSE"
     fi
}

create_alert(){
    local user_email=$1
    local message_alert=$2
    echo -e "\n $message_alert\n" > Machine_Report
    send_email "$user_email"
}

system_monitoring(){     
    local user_email=$(request_user_email)
    
    echo -e "\n It's not necessary to input the symbols, just the values!\n If you press 'Enter' without entering a value, the default value will be assigned.\n"    

    local cpu_usage_parameter=$(set_alert_cpu_usage)
    local cpu_temperature_parameter=$(set_alert_cpu_temperature)
    local ram_usage_parameter=$(set_alert_ram_usage)
    local disk_usage_parameter=$(set_alert_disk_usage)
 
    while [ 1 ] 
    do
        clear
        echo -e "\n Monitoring the system..."        
        if [[ $(is_over_limit "$cpu_usage_parameter" "$(get_cpu_usage)") == "TRUE" ]]
        then
            local message_alert="Alert: The CPU usage has exceeded the defined limit!"
            echo -e "\n $message_alert"
            create_alert "$user_email" "$message_alert"
            break
        fi

        if [[ $(is_over_limit "$cpu_temperature_parameter" "$(get_cpu_temperature_in_celcius)") == "TRUE" ]]
        then
            local message_alert="Alert: The CPU temperature has exceeded the defined limit!"
            echo -e "\n $message_alert"
            create_alert "$user_email" "$message_alert"
            break
        fi
      
        if [[ $(is_over_limit "$ram_usage_parameter" "$(get_ram_usage_percentage)") == "TRUE" ]]
        then
            local message_alert="Alert: The RAM usage has exceeded the defined limit!"
            echo -e "\n $message_alert"
            create_alert "$user_email" "$message_alert"
            break
        fi

        if [[ $(is_over_limit "$disk_usage_parameter" "$(get_disk_usage_percentage | tr -d '%')") == "TRUE" ]]
        then
            local message_alert="Alert: The Disk usage has exceeded the defined limit!"
            echo -e "\n $message_alert"
            create_alert "$user_email" "$message_alert"
            break
        fi
        sleep 1
    done   
}

clear_And_Wait(){
	sleep 2
	clear
}

while [ 1 ]
do
	clear
	generate_greeting_message

	echo -e "\n     1 -> Hardware Information\n     2 -> Machine Report\n     3 -> Send the report to an email\n     4 -> Configure alert\n     5 -> Exit\n"
	read -p " - Select an option: " option

	case $option in
		1)
			clear
			echo -e "\nLoading Hardware Information..."
			clear_And_Wait
			hardware_information
            press_any_key_to_continue
			;;
		2)
			clear
			echo -e "\nLoading Machine Report..."
			clear_And_Wait
			machine_report
			;;
		3)
			clear
			echo -e "\nLoading file to send..."
			clear_And_Wait
			send_email $(request_user_email)
			;;
		
        4)
            clear
            echo -e "\nLoading alert settings..."
            clear_And_Wait
            system_monitoring
            ;;
        5)
			clear
			echo -e "\nExiting..."
			clear_And_Wait
			break
			;;
		*)
			clear
			echo -e "\n Invalid Option!"
			clear_And_Wait
			;;
	esac
done
