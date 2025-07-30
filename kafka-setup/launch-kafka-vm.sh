#!/bin/bash
# Launch script for Kafka VM with automated setup
# This script creates a new Multipass VM with Kafka pre-installed and configured

set -e

VM_NAME=$1
if [ -z "$VM_NAME" ]; then
    echo "Usage: $0 <vm-name>"
    echo "Example: $0 kafka-vm"
    exit 1
fi
CLOUD_INIT_FILE="$(dirname "$0")/kafka-cloud-init.yaml"

echo "🚀 Launching Kafka VM with automated setup..."
echo "VM Name: $VM_NAME"
echo "Cloud-init file: $CLOUD_INIT_FILE"

# Check if cloud-init file exists
if [ ! -f "$CLOUD_INIT_FILE" ]; then
    echo "❌ Error: Cloud-init file not found at $CLOUD_INIT_FILE"
    exit 1
fi

# Check if VM already exists
if multipass list | grep -q "^$VM_NAME"; then
    echo "⚠️  VM '$VM_NAME' already exists. Do you want to delete it and create a new one? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "🗑️  Deleting existing VM..."
        multipass delete "$VM_NAME" --purge
    else
        echo "❌ Aborted. Use a different VM name or delete the existing VM manually."
        exit 1
    fi
fi

# Launch the VM with cloud-init
echo "📦 Creating VM with 2 CPUs, 4GB RAM, and 20GB disk..."
multipass launch --name "$VM_NAME" \
    --cpus 2 \
    --memory 4G \
    --disk 20G \
    --cloud-init "$CLOUD_INIT_FILE" \
    24.04

echo "⏳ VM created. Waiting for cloud-init to complete setup..."
echo "   This may take 3-5 minutes for package installation and Kafka setup..."

# Wait for cloud-init to complete with timeout
echo "🔄 Monitoring setup progress..."
COUNTER=0
MAX_ATTEMPTS=30  # 30 attempts x 15 seconds = 7.5 minutes max

while [ $COUNTER -lt $MAX_ATTEMPTS ]; do
    if multipass exec "$VM_NAME" -- test -f /home/ubuntu/kafka-setup-complete.txt 2>/dev/null; then
        echo "✅ Setup complete!"
        break
    fi
    
    # Show more detailed progress every few attempts
    if [ $((COUNTER % 4)) -eq 0 ]; then
        STATUS=$(multipass exec "$VM_NAME" -- sudo cloud-init status 2>/dev/null || echo "initializing")
        echo "   Progress update ($((COUNTER + 1))/$MAX_ATTEMPTS): Cloud-init status: $STATUS"
    else
        echo "   Still setting up Kafka... (checking again in 15 seconds)"
    fi
    
    sleep 15
    COUNTER=$((COUNTER + 1))
done

# Check if we timed out
if [ $COUNTER -eq $MAX_ATTEMPTS ]; then
    echo "⚠️  Setup is taking longer than expected. Let me check the current status..."
    
    # Check if Kafka is running even without the completion file
    if multipass exec "$VM_NAME" -- sudo systemctl is-active kafka >/dev/null 2>&1; then
        echo "✅ Kafka service is running! Setup appears successful even without completion file."
    else
        echo "❌ Setup may have failed. Check logs with:"
        echo "   multipass exec $VM_NAME -- sudo tail -n 50 /var/log/cloud-init-output.log"
        echo "   multipass exec $VM_NAME -- sudo systemctl status kafka"
        exit 1
    fi
fi

# Get VM info
VM_INFO=$(multipass info "$VM_NAME")
VM_IP=$(echo "$VM_INFO" | grep "IPv4" | awk '{print $2}' | head -1)

echo ""
echo "🎉 Kafka VM is ready!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "VM Name: $VM_NAME"
echo "VM IP:   $VM_IP"
echo "Kafka Broker: $VM_IP:9092"
echo "Controller:   $VM_IP:9093"
echo ""
echo "🔧 Quick test commands:"
echo "# Connect to VM:"
echo "multipass shell $VM_NAME"
echo ""
echo "# Create a test topic:"
echo "multipass exec $VM_NAME -- /opt/kafka/bin/kafka-topics.sh --create --topic test --bootstrap-server localhost:9092"
echo ""
echo "# List topics:"
echo "multipass exec $VM_NAME -- /opt/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092"
echo ""
echo "# Check Kafka service status:"
echo "multipass exec $VM_NAME -- sudo systemctl status kafka"
echo ""
echo "📋 Setup details available in VM at: /home/ubuntu/kafka-setup-complete.txt"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
