#!/usr/bin/env bash



apt-get update && apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list 
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt update
apt-get install $APT_ARGS kubeadm=$KUBE_VERSION  kubelet=$KUBE_VERSION kubernetes-cni iptables
#kubeadm reset -f 

if [[ -z $(which docker) ]];
then
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  systemctl enable docker
  systemctl start docker
fi

if [[ $1 == "master" ]]; 
then
  apt install $APT_ARGS  kubectl=$KUBE_VERSION 
  kubeadm init $KUBEADM_MASTER_ARGS $KUBEADM_ARGS
  kubeadm token create $TOKEN --ttl 1h --print-join-command > /k8s/join
  export KUBECONFIG=/etc/kubernetes/admin.conf 
  cp /etc/kubernetes/admin.conf /k8s/config
  mkdir -p /home/vagrant/.kube
  cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-legacy.yml
else 
  JOIN_CMD=$(cat /k8s/join)
  bash -c "$JOIN_CMD $KUBEADM_ARGS"
fi
