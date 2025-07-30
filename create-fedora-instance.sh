#!/bin/bash


# This is a script to create a fedora based instance with cloud-init enabled but is only meant to be for those who doesn't 
# support mavlan so the instance can be created with a bridge macvlan network to available to the host wifi network.
#
# The script takes two arguments: the image name and the container name.
#

# Set variables
image=$1
container=$2

# Image can be one of the following that supports cloud-init and fedora based:
# almalinux/9/cloud/arm64
# rockylinux/9/cloud/arm64 
# oracle/9/cloud/arm64 
# centos/9-Stream/cloud/arm64

#List Images that are cloud-init ready
# incus image list images: --columns ladts cloud


# Stop and remove the existing container
incus stop $container && incus remove $container

# Create a new container with the AlmaLinux 9 cloud image
incus init images:$image $container  --network macvlan0


# Apply the revised cloud-init configuration
incus config set $container user.user-data - < fedora-config.yaml

# Start the container
incus start $container 

sleep 40

#incus exec almita -- cloud-init schema --system

# Check cloud-init status
response=$(incus exec $ container  -- cloud-init status)

# View cloud-init logs for debugging
if [[ "$response" != *"status: done"* ]]; then
    echo "Cloud-init did not complete successfully. Check the logs for more information."
    incus exec $container  -- cat /var/log/cloud-init-output.log
fi