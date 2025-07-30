# Multipass LXC Host Network configuration

> **Macvlan Network:** Allows containers to have their own MAC address, appearing as unique devices on the network.

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

# 1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
#     link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
#     inet 127.0.0.1/8 scope host lo
#        valid_lft forever preferred_lft forever
#     inet6 ::1/128 scope host noprefixroute
#        valid_lft forever preferred_lft forever
# 2: enp0s1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
#     link/ether .....
#     inet 192.168.64.77/24 metric 100 brd 192.168.64.255 scope global dynamic enp0s1
#        valid_lft 3085sec preferred_lft 3085sec
#     inet6 ....
#       
# 3: enp0s2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
 #    link/ether ...
  #   inet 192.168.1.223/24 metric 200 brd 192.168.1.255 scope global dynamic enp0s2
  #      valid_lft 172288sec preferred_lft 172288sec
#     inet6 f....
# 4: incusbr0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc # noqueue state DOWN group default qlen 1000
#     link/ether ...
#     inet 10.252.152.1/24 scope global incusbr0
#     inet6 .....
#

# In this case: "enp0s2" is what you want to use as parent because it was the "local address of your wifi network"
lxc network create macvlan0 --type=macvlan parent=enp0s2

# To start your first container, try: lxc launch ubuntu:24.04
# Or for a virtual machine: lxc launch ubuntu:24.04 --vm
# 
# Network macvlan0 created

```

## Setup LXC to run Amazon Linux images (Optional)

### Inside VM (via `mp shell lxc`):

> You can run an lunch instances once you setup the remote access from the Host (macOS) machine but for this Amazon Linux instance you need to setup the *cgroups v1* directly inside the VM

In order to run **Amazon Linux** instances we need cgroup v1, we need to download the image and unset the requirements cgroup in the image.

#### For ARM

```shell
lxc image copy images:amazonlinux/2023/arm64 local: --copy-aliases
lxc image unset-property amazonlinux/2023/arm64 requirements.cgroup
```

#### For Intel

```shell
lxc image copy images:amazonlinux/2023/amd64 local: --copy-aliases
lxc image unset-property amazonlinux/2023/amd64 requirements.cgroup
```

* Go back to your host machine

```shell
exit
```

---

## Configure LXC client on host machine (macOS)

### On macOS Host:

  1. Add the remote server in the client *(getting multipass lxc's instance IP address)*

        ```shell
        lxc remote add default $(mp info lxc | grep IPv4 | awk '{print $2}') --password password --accept-certificate
        ```

  2. Point the remote server to **default**

        ```shell
        lxc remote switch default
        ```

  3. List availabe images

        ```shell
        lxc image list images:
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

## Check that the instance was created correctly

Please note that the IP address is under the WiFI network

```shell
lxc list
+-------------+---------+----------------------+------+-----------+-----------+
|    NAME     |  STATE  |         IPV4         | IPV6 |   TYPE    | SNAPSHOTS |
+-------------+---------+----------------------+------+-----------+-----------+
| amazonlinux | RUNNING | 192.168.1.222 (eth0) |      | CONTAINER | 0         |
+-------------+---------+----------------------+------+-----------+-----------+
```

### Notes

**Why macvlan?**

> **WiFi Limitations:** Bridging over **WiFi** is generally not recommended because many WiFi drivers do not support it. macvlan is a workaround that allows instances to communicate on the network as if they are separate physical devices.
