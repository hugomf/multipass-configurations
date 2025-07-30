incus config device add dns-server eth0 nic \
  nictype=macvlan \
  parent=eth0
  ipv4.address=192.168.1.5 \
  ipv4.gateway=192.168.1.1 \
  ipv4.dns=8.8.8.8 \
  ipv6.address=auto \
  ipv6.gateway=auto \
  i



mp launch 22.04 \  
--name dns-server \
--cpus 2 \
--memory 4G \
--disk 40G \
--bridged \
--cloud-init static-config.yaml


mp exec dns-server  -- cat /var/log/cloud-init-output.log

curl -sSL https://install.pi-hole.net | bash        

Your Admin Webpage login password is sz6Jtb1J


sudo ufw allow 80/tcp
sudo ufw allow 53/tcp
sudo ufw allow 53/udp
sudo ufw allow 67/tcp
sudo ufw allow 67/udp
sudo ufw allow 546:547/udp


  incus init images:ubuntu/jammy/cloud/arm64 dns-server --network macvlan0

  incus config set dns-server user.user-data - < static-config.yaml

  incus start dns-server

  incus exec dns-server -- cloud-init schema --system

   incus exec dns-server  -- cat /var/log/cloud-init-output.log

