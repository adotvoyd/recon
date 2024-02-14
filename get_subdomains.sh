#!/bin/bash

# Check if a file argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <domain_file>"
    exit 1
fi
# Read domains from the provided file
DOMAIN_FILE="$1"
if [ ! -f "$DOMAIN_FILE" ]; then
    echo "Error: Domain file not found."
    exit 1
fi
# Function to install packages
install_packages() {
    for package in "$@"
    do
        if ! command -v "$package" &> /dev/null
        then
            echo "Installing $package..."
            # Adjust the package manager command based on your system (apt, yum, etc.)
            sudo apt-get install -y "$package"
        else
            echo "$package is already installed."
        fi
    done
}
wget https://raw.githubusercontent.com/six2dez/resolvers_reconftw/main/resolvers.txt
# Install necessary packages
install_packages amass subfinder massdns
# Install Go Tools
install_go_tool() {
    local tool_path="$1"
    if ! command -v "$tool_path" &> /dev/null; then
        echo "Installing $tool_path..."
        go install "$tool_path"
        sudo mv "$tool_path" /usr/bin/  # Assuming /usr/local/bin is in your PATH
    else
        echo "$tool_path is already installed."
    fi
}
install_go_tool github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
install_go_tool github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
install_go_tool github.com/projectdiscovery/httpx/cmd/httpx@latest
install_go_tool github.com/d3mondev/puredns/v2@latest
# Create a timestamp
TIMESTAMP=$(date +"%Y%m%d%H%M")
while IFS= read -r DOMAIN; do
    # Specify the location where you want to store the results for each domain
    OUTPUT_DIR="./${DOMAIN}_${TIMESTAMP}"
    mkdir -p "${OUTPUT_DIR}"
    # Run amass
    echo "Running amass for $DOMAIN..."
    amass enum -timeout 15 -d "$DOMAIN" -o "${OUTPUT_DIR}/amass.txt"
    # Run subfinder
    echo "Running subfinder for $DOMAIN..."
    subfinder -d "$DOMAIN" -o "${OUTPUT_DIR}/subfinder.txt"
    # Combine results for bruteforcing
    cat "${OUTPUT_DIR}/amass.txt" "${OUTPUT_DIR}/subfinder.txt" | sort -u > "${OUTPUT_DIR}/combined.txt"
    # Run puredns bruteforce
    echo "Running puredns bruteforce for $DOMAIN..."
    puredns bruteforce "/usr/share/seclists/Discovery/DNS/dns-Jhaddix.txt" "$DOMAIN" -w "${OUTPUT_DIR}/puredns.txt" -r resolvers.txt
    # Combine all results
    cat "${OUTPUT_DIR}/amass.txt" "${OUTPUT_DIR}/subfinder.txt" "${OUTPUT_DIR}/puredns.txt" | sort -u > "${OUTPUT_DIR}/all_subdomains.txt"
    echo "Subdomain enumeration for $DOMAIN completed."

    chmod +x extract_domains all_subdomains.txt cleaned_domains.txt

    #Run subfinder and pipe to project nuclei and httpx 
    echo "Running Nuclei through subfinder and httpx for $DOMAIN..."
    cat cleaned_domains.txt | httpx | nuclei -u "$DOMAIN"

done < "$DOMAIN_FILE"
