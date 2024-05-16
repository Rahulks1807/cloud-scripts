#Make sure you install the package gnumeric using you choice of package manager before running this script
#!/bin/bash

# Excel sheet file name (replace with your file path)
excel_file="instance_list.xlsx"

# Temporary CSV file Instead of the create a csv file with , separated values and that should do the job.
csv_file="temp_instances.csv"

# Convert Excel to CSV (assuming the first sheet contains the data)
if ssconvert "$excel_file" "$csv_file"; then
    echo "Conversion successful!"
elif in2csv "$excel_file" > "$csv_file"; then  
    echo "Conversion successful using in2csv!"
else
    echo "Error: Could not convert Excel to CSV. Please ensure you have either ssconvert or in2csv installed." >&2
    exit 1
fi

# Function to apply labels to disks attached to an instance
function apply_labels_to_disks() {
    zone="$1"
    instance_name="$2"
    labels="$3"  

    # Get attached disk names for the instance
    disk_names=$(gcloud compute instances describe "$instance_name" --zone="$zone" --format='value(disks.deviceName)' | grep -v boot)

    # Apply labels to each attached disk
    for disk_name in $disk_names; do
        echo "Applying labels $labels to disk $disk_name in zone $zone..."
        gcloud compute disks add-labels "$disk_name" --zone="$zone" --labels="$labels" 
    done
}

# Read instances and zones from the CSV
while IFS="," read -r zone instance_name labels; do
    if [ ! -z "$zone" ] && [ ! -z "$instance_name" ]; then 
        # Check if instance exists in the specified zone
        if gcloud compute instances describe "$instance_name" --zone="$zone" --quiet &>/dev/null; then
            echo "Instance $instance_name found in zone $zone"
            apply_labels_to_disks "$zone" "$instance_name" "$labels"
        else
            echo "Error: Instance $instance_name not found in zone $zone" >&2
        fi
    fi
done < "$csv_file"

# Clean up temporary file
rm "$csv_file"
