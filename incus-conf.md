# Multipass-Incus Host Network configuration

**Macvlan Network:** Allows containers to have their own MAC address, appearing as unique devices on the network.

## Configuration

### On macOS Host:

* Make sure to set an alias `alias mp=multipass` on your `.bashrc` or `.zshrc` file

* Configure multipass **bridge** as follows:

```shell
mp networks # check the wifi interface (usually is en0)

# Name   Type       Description
# en0    wifi       Wi-Fi
# en4    ethernet   Ethernet Adapter (en4)
# en5    ethernet   Ethernet Adapter (en5)
# en6    ethernet   Ethernet Adapter (en6)

mp set local.bridged-network=en0
```

* Create a multipass ubuntu instance and name it `inucs`, make sure to add bridged `flag`

```shell
mp launch -n incus -c 2 -m 4G -d 50G --bridged
```

* Connect to Incus

```shell
mp shell incus
```

### Inside VM (via `mp shell incus`):

* Install incus

```shell
sudo apt-get install incus
```

* Create a group call `incus-admin` and assign user to the group

```shell
sudo groupadd incus-admin # Sometimes the group already exists
sudo gpasswd -a ubuntu incus-admin
```

> **Note:** Remember to restart your terminal so the user can be assigned to the group

* Initialize configuration, accept all the defaults except for `Would you like the server to be available over the network?`
enter `yes`, hit enter and continue

```shell
sudo incus admin init
...
Would you like the server to be available over the network? (yes/no) [default=no]: yes
...
```

* Configure the remote access (add trusted access)

```shell
incus config trust add macos


# To start your first container, try: incus launch images:ubuntu/22.04
# Or for a virtual machine: incus launch images:ubuntu/22.04 --vm

# Client macos certificate add token:
# eyJjbGllbnRfbmFtZSI6Im1hY29zIiwiZ....

```

* **Copy the generated token, we will use it later**

* Load the macvlan kernel module
  
```shell
sudo modprobe macvlan
```

* create the macvlan network in incus

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
incus network create macvlan0 --type=macvlan parent=enp0s2
```

## Setup incus to run Amazon Linux images (Optional)

### Inside VM (via `mp shell incus`):

* In order to run **Amazon Linux** instances we need cgroup v1, we need to download the image and unset the requirements cgroup in the image.

#### For ARM

```shell
incus image copy images:amazonlinux/2/arm64 local: --copy-aliases
incus image unset-property amazonlinux/2/arm64 requirements.cgroup
```

#### For Intel

```shell
incus image copy images:amazonlinux/2 local: --copy-aliases
incus image unset-property amazonlinux/2 requirements.cgroup
```

* Go back to your host machine

```shell
exit
```

---

## Configure incus client on host machine (macOS)

### On macOS Host:

  1. Install incus client in macOS

        ```shell

        brew install incus
        ```

  2. Add the remote server in the client *(getting multipass lxc's instance IP address)*

        ```shell

            incus remote add default $(mp info incus | grep IPv4 | awk '{print $2}') --token eyJjbGllbnRfbmFtZSI6....

            # Certificate fingerprint: # 0098e0e3683ce8905ced62f1110aaaeafe9f467019cf5d158569ce6e65f5b42d
            # ok (y/n/[fingerprint])? y 
            # Client certificate now trusted by server: default
        ```

  3. Point the remote server to **default**

        ```shell
        incus remote switch default
        ```

  4. List availabe images

        ```shell
        incus image list images:
        ```

  5. Create for example opensuse instance (remember to assign it to the macvlan0 network)

```shell
incus launch images:opensuse/tumbleweed opensuse --network macvlan0
```

## Create the Amazon Linux instance (Optional)

### For ARM

```shell
incus launch images:amazonlinux/2/arm64 amazonlinux --network macvlan0
```

### For Intel / AMD

```shell
incus launch images:amazonlinux/2 amazonlinux --network macvlan0
```

### Notes

**Why macvlan?**

> **WiFi Limitations:** Bridging over **WiFi** is generally not recommended because many WiFi drivers do not support it. macvlan is a workaround that allows instances to communicate on the network as if they are separate physical devices.
