# Create the VM with cloud-init configuration
incus stop dns-server && incus remove dns-server


incus launch images:ubuntu/jammy/cloud/arm64 dns-server \
    --config=user.user-data="$(cat pihole-cloud-init.yaml)" --network macvlan0

# Configure static IP with macvlan
incus config device add dns-server eth0 nic \
    nictype=macvlan \
    parent=en0 \
    ipv4.address=192.168.1.10 \
    ipv4.gateway=192.168.1.1

# Start the VM
incus start dns-server

# Monitor the installation progress
incus exec dns-server -- tail -f /var/log/cloud-init-output.log