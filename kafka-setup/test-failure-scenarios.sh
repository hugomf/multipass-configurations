#!/bin/bash
# Test script to simulate different failure scenarios

echo "🧪 Testing failure scenarios..."

# Test 1: Simulate missing completion file but Kafka running
echo "📋 Test 1: Missing completion file, but Kafka service running"
if multipass exec kafka-vm-auto -- sudo systemctl is-active kafka >/dev/null 2>&1; then
    echo "✅ Kafka service is running! Setup appears successful even without completion file."
    echo "   The script would continue and show connection details."
else
    echo "❌ Kafka service is not running - script would exit with error."
fi

echo ""

# Test 2: Check what diagnostic commands would show
echo "📋 Test 2: Diagnostic commands that would be shown on failure:"
echo "Command 1: multipass exec kafka-vm-auto -- sudo tail -n 50 /var/log/cloud-init-output.log"
echo "Command 2: multipass exec kafka-vm-auto -- sudo systemctl status kafka"

echo ""

# Test 3: Simulate timeout behavior
echo "📋 Test 3: Timeout behavior simulation"
echo "After 30 attempts (7.5 minutes), the script would:"
echo "1. Stop waiting for completion file"
echo "2. Check if Kafka service is active" 
echo "3. Either continue (if Kafka is running) or exit with error"

echo ""

# Test 4: Show current cloud-init status
echo "📋 Test 4: Current cloud-init status check"
STATUS=$(multipass exec kafka-vm-auto -- sudo cloud-init status 2>/dev/null || echo "error checking status")
echo "Cloud-init status: $STATUS"
