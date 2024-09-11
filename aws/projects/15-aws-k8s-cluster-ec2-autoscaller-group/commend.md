sudo apt-get update
 sudo apt-get install -y docker.io

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo apt update
sudo apt install -y kubelet kubeadm kubectl


# Enable Docker and Kubelet services
sudo systemctl enable docker kubelet

# Configure sysctl settings
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p



sudo systemctl restart docker
sudo systemctl enable containerd
sudo systemctl restart containerd
sudo systemctl restart kubelet
sudo kubeadm reset



sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors=all