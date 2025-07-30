#!/bin/bash
# Simulate the exact failure detection logic from the main script

VM_NAME="kafka-vm-auto"
echo "🧪 Simulating failure detection logic..."
echo ""

# Check if completion file exists (simulating the timeout scenario)
if multipass exec "$VM_NAME" -- test -f /home/ubuntu/kafka-setup-complete.txt 2>/dev/null; then
    echo "✅ Completion file found - normal success path"
else
    echo "⚠️  Completion file missing - entering failure detection mode"
    echo ""
    
    # This is the exact logic from the main script
    if multipass exec "$VM_NAME" -- sudo systemctl is-active kafka >/dev/null 2>&1; then
        echo "✅ Kafka service is running! Setup appears successful even without completion file."
        echo "   → Script would continue and show connection details"
        echo "   → Exit code: 0 (success)"
    else
        echo "❌ Kafka service is not running - setup failed"
        echo "   → Script would show diagnostic commands:"
        echo "   → multipass exec $VM_NAME -- sudo tail -n 50 /var/log/cloud-init-output.log"
        echo "   → multipass exec $VM_NAME -- sudo systemctl status kafka"
        echo "   → Exit code: 1 (failure)"
    fi
fi

echo ""
echo "📊 Current system status:"
echo "- Kafka service: $(multipass exec "$VM_NAME" -- sudo systemctl is-active kafka 2>/dev/null || echo 'inactive')"
echo "- Cloud-init: $(multipass exec "$VM_NAME" -- sudo cloud-init status 2>/dev/null || echo 'unknown')"
