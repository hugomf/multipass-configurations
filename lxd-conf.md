# Multipass-LXC Host Network configuration

**Macvlan Network:** Allows containers to have their own MAC address, appearing as unique devices on the network.

## Configuration

### On macOS Host:

* Make sure to set an alias `alias mp=multipass` on your `.bashrc` or `.zshrc` file

* Configure multipass **bridge** as follows:

```shell
mp networks # check the wifi interface (usually it's en0)

mp set local.bridged-network=en0
```

* Create a multipass ubuntu instance and name it `lxc`, make sure to add bridged `flag`

```shell
mp launch -n lxc -c 2 -m 4G -d 50G --bridged
```

* Connect to lxc

```shell
mp shell lxc
```

### Inside VM (via `mp shell lxc`):

* Initialize the configuration

```shell
sudo lxd init --auto --trust-password password --network-address '[::]'
```

* Load the macvlan kernel module
  
```shell
sudo modprobe macvlan
```

* create the macvlan network in lxd

```shell
# Verify the network configuration
ip addr  # check the interface id to change the parent flag in the next command

lxc network create macvlan0 --type=macvlan parent=eth0
```

## Setup LXC to run Amazon Linux images (Optional)

* In order to run **Amazon Linux** instances we need cgroup v1, we need to download the image and unset the requirements cgroup in the image.

### For ARM

```shell
lxc image copy images:amazonlinux/2023/arm64 local: --copy-aliases
lxc image unset-property amazonlinux/2023/arm64 requirements.cgroup
```

### For Intel

```shell
lxc image copy images:amazonlinux/2023/amd64 local: --copy-aliases
lxc image unset-property amazonlinux/2023/amd64 requirements.cgroup
```

* Go back to your host machine

```shell
exit
```

## Configure LXC client on host machine (MACOS)

### On macOS Host:

* Add the remote server in the client *(getting multipass lxc's instance IP address)*

```shell
lxc remote add default $(mp info lxc | grep IPv4 | awk '{print $2}') --password password --accept-certificate
```

* Point the remote server to **default**

```shell
lxc remote switch default
```

## Create the Amazon Linux instance

### For ARM

```shell
lxc launch images:amazonlinux/2023/arm64 amazonlinux --network macvlan0
```

### For Intel / AMD

```shell
lxc launch images:amazonlinux/2023/amd64 amazonlinux --network macvlan0
```

### Notes

**Why macvlan?**

> **WiFi Limitations:** Bridging over **WiFi** is generally not recommended because many WiFi drivers do not support it. macvlan is a workaround that allows instances to communicate on the network as if they are separate physical devices.
