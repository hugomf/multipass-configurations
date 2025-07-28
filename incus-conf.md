# Multipass-Incus Host Network configuration

**Macvlan Network:** Allows containers to have their own MAC address, appearing as unique devices on the network.

## Configuration

* Make sure to set an alias `alias mp=multipass` on your `.bashrc` or `.zshrc` file

* Configure multipass **bridge** as follows:

```shell
mp networks # check the wifi interface (usually it's en0)

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

* Install incus

```shell
sudo apt-get install incus
```

* Create a group call `incus-admin` and assign user to the group

```shell
sudo groupadd incus-admin
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

```

Copy the generated token to be used later

* Load the macvlan kernel module
  
```shell
sudo modprobe macvlan
```

* create the macvlan network in incus

```shell
# Verify the network configuration
ip addr  # check the interface id to change the parent flag in the next command

incus network create macvlan0 --type=macvlan parent=eth0
```

## Setup incus to run Amazon Linux images (Optional)

* In order to run **Amazon Linux** instances we need cgroup v1, we need to download the image and unset the requirements cgroup in the image.

### For ARM

```shell
incus image copy images:amazonlinux/2/arm64 local: --copy-aliases
incus image unset-property amazonlinux/2/arm64 requirements.cgroup
```

### For Intel

```shell
incus image copy images:amazonlinux/2 local: --copy-aliases
incus image unset-property amazonlinux/2 requirements.cgroup
```

* Go back to your host machine

```shell
exit
```

## Configure incus client on host machine (MACOS)

* Add the remote server in the client *(getting multipass lxc's instance IP address)*

```shell
incus remote add default {paste token here}
```

* Point the remote server to **default**

```shell
incus remote switch default
```

** List availabe images

```shell
incus image list images:
```

* Create for example opensuse instance (remember to assign it to the macvlan0 network)

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
