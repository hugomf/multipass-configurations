#!/bin/bash

# launch-ollama-instance.sh
# Script to create a Multipass VM with Ollama using a separate cloud-init YAML file

# Exit on any error
set -e

# Variables
VM_NAME="ollama-vm"
CPUS=4
MEMORY="16G"
DISK="20G"
CLOUD_INIT_FILE="ollama-cloud-init.yaml"
MODEL_NAME="codellama:7b-code"

# Check if Multipass is installed
if ! command -v multipass &> /dev/null; then
    echo "Error: Multipass is not installed. Please install it from https://multipass.run/"
    exit 1
fi

# Check if cloud-init YAML file exists
if [ ! -f "$CLOUD_INIT_FILE" ]; then
    echo "Error: Cloud-init file '$CLOUD_INIT_FILE' not found in the current directory."
    echo "Please create '$CLOUD_INIT_FILE' with the required configuration."
    exit 1
fi

# Check if VM already exists and delete it if necessary
if multipass list | grep -q "$VM_NAME"; then
    echo "Deleting existing VM: $VM_NAME"
    multipass delete --purge "$VM_NAME"
fi

# Launch Multipass VM with cloud-init
echo "Launching VM: $VM_NAME with $CPUS CPUs, $MEMORY memory, and $DISK disk"
multipass launch --name "$VM_NAME" --cpus "$CPUS" --memory "$MEMORY" --disk "$DISK" --cloud-init "$CLOUD_INIT_FILE" --bridged

# Wait for VM to be ready (cloud-init may take a few minutes)
echo "Waiting for VM to start and cloud-init to complete..."
sleep 60

# Get VM IP address
VM_IP=$(multipass info "$VM_NAME" | grep IPv4 | awk '{print $2}')
if [ -z "$VM_IP" ]; then
    echo "Error: Could not retrieve VM IP address. Check Multipass status with 'multipass list'."
    exit 1
fi

# Verify Ollama is running
echo "Verifying Ollama service..."
if multipass exec "$VM_NAME" -- bash -c "sudo snap services ollama | grep active"; then
    echo "Ollama service is active."
else
    echo "Error: Ollama service is not active. Check VM logs with 'multipass shell $VM_NAME' and 'sudo snap logs ollama'."
    exit 1
fi

# Verify model is downloaded
echo "Verifying model: $MODEL_NAME"
if multipass exec "$VM_NAME" -- bash -c "ollama list | grep $MODEL_NAME"; then
    echo "Model $MODEL_NAME is installed."
else
    echo "Error: Model $MODEL_NAME not found. Attempting to pull again..."
    multipass exec "$VM_NAME" -- bash -c "ollama pull $MODEL_NAME"
fi

# Output instructions
echo -e "\nSetup Complete!"
echo "VM Name: $VM_NAME"
echo "Ollama URL: http://$VM_IP:11434"
echo "Model: $MODEL_NAME"
echo -e "\nNext Steps:"
echo "1. In VS Code, configure Cline or Roo Cline:"
echo "   - API Provider: Ollama"
echo "   - Base URL: http://$VM_IP:11434"
echo "   - Model ID: $MODEL_NAME"
echo "2. Test with a code generation prompt in Cline/Roo Cline."
echo "3. To access the VM: multipass shell $VM_NAME"
echo "4. To check Ollama status: multipass exec $VM_NAME -- sudo snap services ollama"
echo "5. To view setup instructions in VM: multipass exec $VM_NAME -- cat /home/ubuntu/ollama_setup.txt"