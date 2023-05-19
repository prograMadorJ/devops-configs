STEPS=18
STEP=0
SLEEP_SEC=3

########################################

# STARTING LOGO

########################################
echo ""
echo "[$(date "+%Y-%m-%d %H:%M:%S")] Starting..."
echo "
  _          _                          _            
 | | ___   _| |__   ___ _ __ _ __   ___| |_ ___  ___ 
 | |/ / | | | '_ \ / _ \ '__| '_ \ / _ \ __/ _ \/ __|
 |   <| |_| | |_) |  __/ |  | | | |  __/ ||  __/\__ \ 
 |_|\_\\\\__,_|_.__/ \___|_|  |_| |_|\___|\__\___||___/
 "
echo ""
########################################

# UPDATING PACKAGES

########################################
echo "[$(date "+%Y-%m-%d %H:%M:%S")] [ $((++STEP))/$STEPS ] Updating packages..."
echo ""

sudo yum -y update

echo ""
########################################

# CONFIGURING REPO KUBERNETES

########################################
sleep $SLEEP_SEC
echo "[$(date "+%Y-%m-%d %H:%M:%S")] [ $((++STEP))/$STEPS ] Configure repo kubernetes..."
echo ""

sudo tee /etc/yum.repos.d/kubernetes.repo<<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

echo ""
########################################

# INSTALLING REQUIRE PACKAGES

########################################
sleep $SLEEP_SEC
echo "[$(date "+%Y-%m-%d %H:%M:%S")] [ $((++STEP))/$STEPS ] Installing require packages..."
echo ""

sudo yum clean all && sudo yum -y makecache
sudo yum -y install epel-release vim git curl wget

echo ""
########################################

# DISABLE SELinux AND SWAP

########################################
sleep $SLEEP_SEC
echo "[$(date "+%Y-%m-%d %H:%M:%S")] [ $((++STEP))/$STEPS ] Disable SELinux and Swap..."
echo ""

sudo setenforce 0
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config

sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a

## this apply only master node
sudo firewall-cmd --add-port={6443,2379-2380,10250,10251,10252,5473,179,5473}/tcp --permanent
sudo firewall-cmd --add-port={4789,8285,8472}/udp --permanent
sudo firewall-cmd --reload

## this apply only worker nodes
# sudo firewall-cmd --add-port={10250,30000-32767,5473,179,5473}/tcp --permanent
# sudo firewall-cmd --add-port={4789,8285,8472}/udp --permanent
# sudo firewall-cmd --reload


echo ""
################################################################################

# INSTALL & CONFIGURING DOCKER | CONTAINERD | KUBELET | KUBEADM | KUBECTL

################################################################################
sleep $SLEEP_SEC
echo "[$(date "+%Y-%m-%d %H:%M:%S")] [ $((++STEP))/$STEPS ] Install & configuring kubernetes with Containerd..."
echo ""


echo "[$(date "+%Y-%m-%d %H:%M:%S")] [ $((++STEP))/$STEPS ] Configure persistent loading of modules..."
echo ""

sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

sleep $SLEEP_SEC
echo ""
echo "[$(date "+%Y-%m-%d %H:%M:%S")] [ $((++STEP))/$STEPS ] Configure modprobe..."
echo ""

sudo modprobe overlay
sudo modprobe br_netfilter

sleep $SLEEP_SEC
echo ""
echo "[$(date "+%Y-%m-%d %H:%M:%S")] [ $((++STEP))/$STEPS ] Set sysctl params..."
echo ""

sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sleep $SLEEP_SEC
echo ""
echo "[$(date "+%Y-%m-%d %H:%M:%S")] [ $((++STEP))/$STEPS ] Reload sysctl..."
echo ""

sudo sysctl --system

sleep $SLEEP_SEC
echo ""
echo "[$(date "+%Y-%m-%d %H:%M:%S")] [ $((++STEP))/$STEPS ] Install required packages..."
echo ""

sudo yum install -y yum-utils device-mapper-persistent-data lvm2

sleep $SLEEP_SEC
echo ""
echo "[$(date "+%Y-%m-%d %H:%M:%S")] [ $((++STEP))/$STEPS ] Add Docker repo..."
echo ""

sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

sleep $SLEEP_SEC
echo ""
echo "[$(date "+%Y-%m-%d %H:%M:%S")] [ $((++STEP))/$STEPS ] Install docker, containerd, kubernetes required systems..."
echo ""

sudo yum update -y && yum install -y docker-ce docker-ce-cli docker-compose-plugin containerd.io kubelet kubeadm kubectl

sleep $SLEEP_SEC
echo ""
echo "[$(date "+%Y-%m-%d %H:%M:%S")] [ $((++STEP))/$STEPS ] Configure containerd and start services..."
echo ""

sudo mkdir -p /etc/containerd
sudo containerd config default > /etc/containerd/config.toml

sleep $SLEEP_SEC
echo ""
echo "[$(date "+%Y-%m-%d %H:%M:%S")] [ $((++STEP))/$STEPS ] Start containerd..."
echo ""

sudo systemctl restart containerd
sudo systemctl enable containerd

sleep $SLEEP_SEC
echo ""
echo "[$(date "+%Y-%m-%d %H:%M:%S")] [ $((++STEP))/$STEPS ] Start Docker..."
echo ""

sudo systemctl restart docker
sudo systemctl enable docker

sleep $SLEEP_SEC
echo ""
echo "[$(date "+%Y-%m-%d %H:%M:%S")] [ $((++STEP))/$STEPS ] Start Kubelet..."
echo ""

sudo systemctl enable kubelet

# echo ""
# echo "[$(date "+%Y-%m-%d %H:%M:%S")] [ $((++STEP))/$STEPS ]  Remove Containerd/Config.toml..."
# echo ""

# sudo rm /etc/containerd/config.toml

sleep $SLEEP_SEC
echo ""
echo "[$(date "+%Y-%m-%d %H:%M:%S")] [ $((++STEP))/$STEPS ] Starting Kubeadm..."
echo ""

kubeadm init


sleep $SLEEP_SEC
echo ""
echo "[$(date "+%Y-%m-%d %H:%M:%S")] [ $((++STEP))/$STEPS ] Appling Scripts & Configurations..."
echo ""

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

export KUBECONFIG=/etc/kubernetes/admin.conf


echo ""
echo "[$(date "+%Y-%m-%d %H:%M:%S")] *** Kubernetes Instalation Successfuly ***"
echo ""