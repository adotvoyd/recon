#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 input_file.txt output_file.txt"
  exit 1
fi

input_file=$1
output_file=$2

# Use grep to extract domains and subdomains
grep -oE "[a-zA-Z0-9.-]+\.([a-zA-Z]{2,})" "$input_file" | sort -u > "$output_file"

echo "Domains and subdomains extracted and saved to $output_file."
