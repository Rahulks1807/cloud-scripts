#!/bin/bash

# Excel sheet file name (replace with your file path)
excel_file="instance_list.xlsx"

# Temporary CSV file
csv_file="temp_instances.csv"

csv_file_new="temp_instances1.csv"

# Convert Excel to CSV (assuming the first sheet contains the data)
if ssconvert "$excel_file" "$csv_file"; then
    echo "Conversion successful!"
elif in2csv "$excel_file" > "$csv_file"; then  
    echo "Conversion successful using in2csv!"
else
    echo "Error: Could not convert Excel to CSV. Please ensure you have either ssconvert or in2csv installed." >&2
    exit 1
fi

# Function to apply labels to a single instance
function apply_labels() {
    zone="$1"
    instance_name="$2"
    labels=$3  # Get the labels directly from the CSV

    # Check if instance exists in the specified zone
    if gcloud compute instances describe "$instance_name" --zone="$zone" --quiet &>/dev/null; then
        echo "Applying labels $labels to instance $instance_name in zone $zone..."
        gcloud compute instances add-labels "$instance_name" --zone="$zone" --labels=$labels 
    else
        echo "Error: Instance $instance_name not found in zone $zone" >&2
    fi
}

# Read instances and zones from the CSV
while IFS="," read -r zone instance_name labels; do
    if [ ! -z "$zone" ] && [ ! -z "$instance_name" ]; then 
        apply_labels "$zone" "$instance_name" "$labels" 
    fi
done < "$csv_file_new"

# Clean up temporary file
rm "$csv_file"
