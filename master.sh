#!/bin/bash

echo "======= Enabling IPv4 packet forwarding ======="; sleep 2
##https://kubernetes.io/docs/setup/production-environment/container-runtimes/#prerequisite-ipv4-forwarding-optional
##It's a single command starting from cat to the 3rd line EOF, make sure copy and paste in one go.
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system


echo "======= Installing container runtime ======="; sleep 2
sudo apt-get update
sudo apt-get install containerd -y

echo "======= Installing Kubeadm, Kubelet and Kubectl ======="; sleep 2
##https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "======= Setting up the systemd cgroup driver for container runtime ======="; sleep 2
##https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd
sudo mkdir -p /etc/containerd
containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/g' | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd


echo "======= Initializing control-plane node ======="; sleep 2 
##--ignore-preflight-errors='NumCPU,Mem' to ignore below errors related to Less CPUs Memory on EC2 Instance. You don't need to use "--ignore-preflight-errors='NumCPU,Mem'" it on local VM where we have CPUs 2 or more and memory 1700MB or more.
##[ERROR NumCPU]: the number of available CPUs 1 is less than the required 2
##[ERROR Mem]: the system RAM (957 MB) is less than the minimum 1700 MB
##https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/

PRIMARY_IP=$(ip route get 1.1.1.1 | awk '/via/ {print $7}')
kubeadm init --apiserver-advertise-address ${PRIMARY_IP} --pod-network-cidr '10.244.0.0/16' --upload-certs --ignore-preflight-errors='NumCPU,Mem' | sudo tee /root/kube_init_output


##To start using your cluster, you need to run the following as a regular user:

sudo mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
sudo chown root:root /root/.kube/config && sleep 20


echo "======= Installing Network Addon ======="; sleep 2
##https://kubernetes.io/docs/concepts/cluster-administration/addons/#networking-and-network-policy
##https://github.com/flannel-io/flannel#deploying-flannel-manually

sudo kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

echo "======= Configuring shell autocomplition ======";sleep 2
#https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#enable-kubectl-autocompletion
echo 'source <(kubectl completion bash)' >> /root/.bashrc
source /root/.bashrc

echo "====== K8s Master server initialization completed ======="
