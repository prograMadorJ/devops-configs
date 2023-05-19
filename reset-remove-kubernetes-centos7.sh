docker rm $(docker ps -aq)
docker rm -f -v $(docker ps -q)
systemctl stop kubelet
systemctl stop docker
find /var/lib/kubelet | xargs -n 1 findmnt -n -t tmpfs -o TARGET -T | uniq | xargs -r umount -v
rm -r -f /etc/kubernetes /var/lib/kubelet /var/lib/etcd
kubeadm reset
iptables --flush
sudo rm -rf ~/.kube
sudo rm -rf /etc/kubernetes
yum remove -y kubelet kubeadm kubectl
echo "1" >/proc/sys/net/bridge/bridge-nf-call-iptables

# REBOOT

# yum install -y kubelet kubeadm kubectl
# systemctl start docker && systemctl enable docker
# systemctl start kubelet && systemctl enable kubelet
# systemctl daemon-reload
# systemctl enable --now kubelet
# systemctl restart kubelet

# Now Run Join Command as You got earlier