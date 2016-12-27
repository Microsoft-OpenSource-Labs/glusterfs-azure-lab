
#!/bin/bash
echo "Preparing node2... "
# Update the system
yum -y update 
# Add the glusterfs epel yum repository 
cat >> /etc/yum.repos.d/glusterfs-epel.repo << EOF
[glusterfs-epel]
name=GlusterFS is a clustered file-system capable of scaling to several petabytes.
baseurl=http://buildlogs.centos.org/centos/7/storage/x86_64/gluster-3.8/
enabled=1
skip_if_unavailable=1
gpgcheck=0
EOF
# Install the latest epel repository 
yum -y install http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
# Install gluster-fs and samba
yum install glusterfs-server samba -y
#create RAID0
sudo mdadm --create md0 --level=0 --chunk=256K --raid-devices=2 /dev/sdc /dev/sdd
# create and configure and format LVMs
sudo pvcreate --dataalignment 1024K /dev/md/md0
sudo vgcreate --physicalextentsize 256K glustervg-data /dev/md/md0
for n in {1..2}; do sudo lvcreate -L 5G -n brick$n glustervg-data; done
for n in {1..2}; do sudo mkfs.xfs /dev/glustervg-data/brick$n; done
# create mounts points and mount the bricks
sudo mkdir -p /bricks/brick{1,2}
for n in {1..2}; do sudo mount /dev/glustervg-data/brick$n /bricks/brick$n; done
for n in {1..2}; do  echo "/dev/glustervg-data/brick$n  /bricks/brick$n    xfs     defaults    0 0" >> /etc/fstab; done
mount -a
#turn SELinux to permissive mode
setenforce 0
#Enable and start glusterd service
systemctl enable glusterd
systemctl start glusterd



