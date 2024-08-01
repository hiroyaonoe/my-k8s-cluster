#!/bin/bash -eux

# swap off
free -h
sudo swapoff -a
free -h

# comment out `/swap.img       none    swap    sw      0       0` in /etc/fstab
exit

# https://kubernetes.io/docs/setup/production-environment/container-runtimes/
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
# fs.inotify.max_user_instances       = 1024
EOF

# Apply sysctl params without reboot
sudo sysctl --system

lsmod | grep br_netfilter
lsmod | grep overlay

sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

# sudo vim /etc/security/limits.conf 
# * soft nofile 65536
# * hard nofile 65536

# https://github.com/containerd/containerd/blob/main/docs/getting-started.md
wget https://github.com/containerd/containerd/releases/download/v1.7.15/containerd-1.7.15-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local containerd-1.7.15-linux-amd64.tar.gz

sudo mkdir -p /usr/local/lib/systemd/system
sudo wget -O /usr/local/lib/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service

sudo systemctl daemon-reload
sudo systemctl enable --now containerd

wget https://github.com/opencontainers/runc/releases/download/v1.1.12/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc

wget https://github.com/containernetworking/plugins/releases/download/v1.4.1/cni-plugins-linux-amd64-v1.4.1.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.4.1.tgz

# https://github.com/containerd/nerdctl#install
wget https://github.com/containerd/nerdctl/releases/download/v1.7.5/nerdctl-1.7.5-linux-amd64.tar.gz
sudo tar Cxzvvf /usr/local/bin nerdctl-1.7.5-linux-amd64.tar.gz

sudo nerdctl ps


# https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd-systemd
sudo mkdir -p /etc/containerd
# https://github.com/kubernetes/kubeadm/issues/2833#issuecomment-1456845860
containerd config default | sudo tee /etc/containerd/config.toml
cat <<EOF | sudo tee /etc/containerd/config.toml
version = 2
[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
   [plugins."io.containerd.grpc.v1.cri".containerd]
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            SystemdCgroup = true
EOF

sudo systemctl restart containerd

# https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/configure-cgroup-driver/#configuring-the-kubelet-cgroup-driver
# https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta3/
cat kubeadm/kubeadm-config.yaml

sudo mkdir -p /etc/default
cat <<EOF | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS=--node-ip=<host-IP>
EOF

# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet=1.29.3-1.1 kubeadm=1.29.3-1.1 kubectl=1.29.3-1.1
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet


# Only control-plane

# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/
# https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/configure-cgroup-driver/
sudo kubeadm init --config kubeadm/kubeadm-config.yaml

# Add worker node
sudo kubeadm token create --print-join-command
