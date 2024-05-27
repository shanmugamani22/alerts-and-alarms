#!/bin/bash

# Set variables
threshold=80
webhook_url='xxxxxxx-xxxxxxx-xxxxxxx'  # Set destination URL here
alarm_name="jenkins-preprod-storage-space-exhaustion-alerts"  # Set the alarm name here

# Get instance IP
instance_ip=$(hostname -i)

# Function to get disk usage percentage
get_disk_usage() {
    df_output=$(df -h /)
    usage_percentage=$(echo "$df_output" | awk 'NR==2 {print $5}')
    echo "$usage_percentage"
}

# Function to construct Slack message
construct_slack_message() {
    disk_usage_percentage=$1

    if [ "${disk_usage_percentage%\%}" -gt "$threshold" ]; then
        color="danger"
        message="*Alarm Name*
$alarm_name
*Alarm Description*
*Trigger*
Maximum DiskUtilization GreaterThanThreshold $threshold percentage.
*Disk Usage*
$disk_usage_percentage
*Instance IP*
$instance_ip"
        echo "{\"attachments\":[{\"title\":\"AWS Alerts and Notification\",\"color\":\"$color\",\"text\":\"$message\"}]}"
    fi
}

# Function to send Slack alert
send_slack_alert() {
    disk_usage_percentage=$1

    slack_data=$(construct_slack_message "$disk_usage_percentage")
    if [ -n "$slack_data" ]; then
        curl -X POST -H 'Content-type: application/json' --data "$slack_data" "$webhook_url"
    fi
}

# Main function
main() {
    disk_usage_percentage=$(get_disk_usage)
    if [ -z "$disk_usage_percentage" ]; then
        echo "Failed to retrieve disk usage."
        exit 1
    fi

    if [ "${disk_usage_percentage%\%}" -gt "$threshold" ]; then
        echo "Sending Slack alert..."
        send_slack_alert "$disk_usage_percentage"
    else
        echo "Disk usage is below the threshold. No alert sent."
    fi
}

# Execute main function
main
