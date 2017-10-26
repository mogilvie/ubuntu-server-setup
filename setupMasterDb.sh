#!/bin/bash

set -e

function getCurrentDir() {
    local current_dir="${BASH_SOURCE%/*}"
    if [[ ! -d "${current_dir}" ]]; then current_dir="$PWD"; fi
    echo "${current_dir}"
}

function includeDependencies() {
    # shellcheck source=./setupLibrary.sh
    source "${current_dir}/commonSetup.sh"
    source "${current_dir}/setupLibrary.sh"
}

current_dir=$(getCurrentDir)
includeDependencies
output_file="output.log"

function main() {
    read -rp "Enter the username of the new user account:" username

    promptForPassword

    # Run setup functions
    trap cleanup EXIT SIGHUP SIGINT SIGTERM

    addUserAccount "${username}" "${password}"

    read -rp $'Paste in the public SSH key for the new user:\n' sshKey
    echo 'Running setup script...'
    logTimestamp "${output_file}"

    exec 3>&1 >>"${output_file}" 2>&1
    disableSudoPassword "${username}"
    addSSHKey "${username}" "${sshKey}"
    changeSSHConfig
    setupUfw

    if ! hasSwap; then
        setupSwap
    fi

    setupTimezone

    echo "Installing Network Time Protocol... " >&3
    configureNTP

    sudo service ssh restart

    cleanup

    echo "Setup Done! Log file is located at ${output_file}" >&3
}

main
