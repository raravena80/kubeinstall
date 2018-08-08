#!/bin/bash
#
# Install script for gcp
# Install Docker
apt -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common


curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
apt-key fingerprint 0EBFCD88

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt update
apt -y install docker-ce

# Install kubectl, kubeadm and kubelet
apt update && apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt update
apt install -y kubelet kubeadm kubectl

# the following is not compatible with k8s 1.11.x
# cat <<EOF > 20-cloud-provider.conf
# Environment="KUBELET_EXTRA_ARGS=--cloud-provider=gce"
# EOF

# sudo mv 20-cloud-provider.conf /etc/systemd/system/kubelet.service.d/
# systemctl daemon-reload
# systemctl restart kubelet
###

EXTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
KUBERNETES_VERSION=1.11.1

cat <<EOF > kubeadm.conf
kind: MasterConfiguration
apiVersion: kubeadm.k8s.io/v1alpha1
apiServerCertSANs:
  - 10.96.0.1
  - ${EXTERNAL_IP}
  - ${INTERNAL_IP}
apiServerExtraArgs:
  admission-control: PodPreset,Initializers,GenericAdmissionWebhook,NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,NodeRestriction,ResourceQuota
  feature-gates: AllAlpha=true
  runtime-config: api/all
cloudProvider: gce
kubernetesVersion: ${KUBERNETES_VERSION}
networking:
  podSubnet: 192.168.0.0/16
EOF

sudo kubeadm init --config=kubeadm.conf

sudo chmod 644 /etc/kubernetes/admin.conf

# kubectl taint nodes --all node-role.kubernetes.io/master- \
#  --kubeconfig /etc/kubernetes/admin.conf

kubectl apply \
  -f http://docs.projectcalico.org/v2.4/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml \
  --kubeconfig /etc/kubernetes/admin.conf
