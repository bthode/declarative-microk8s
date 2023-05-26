#!/bin/bash


# Generic machine set up.
sudo apt update
sudo apt install -y zsh

chsh -s $(which zsh)
echo 'export EDITOR=vim' >> ~/.zshrc
echo 'alias kubectl="sudo microk8s kubectl"' >> ~/.zshrc
echo 'alias k="sudo microk8s kubectl"' >> ~/.zshrc


# Update apt to trust Google
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/google.gpg
# Add Kubernetes repo to apt
echo "deb [signed-by=/usr/share/keyrings/google.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
# Install some common k8 tools
sudo apt install -y kubectl kubeadm kubelet


# Microk8s / ArgoCD Setup
export local_launch_configuration="microk8s-config.yaml"
export launch_configuration_dir="/root/snap/microk8s/common/"
export launch_configuration_name=".microk8s.yaml"
export launch_configuration_path="${launch_configuration_dir}${launch_configuration_name}"
export argocd_install_manifest="https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/install.yaml"
export argocd_namespace="argocd"
export argocd_management="https://raw.githubusercontent.com/bthode/microk8s-argocd/master/argocd-manifest.yaml"
export kafkagram_applicaiton="https://raw.githubusercontent.com/bthode/kafkagram-argocd/main/argocd-manifest.yaml"

sudo mkdir -p "${launch_configuration_dir}"
sudo cp "${local_launch_configuration}" "${launch_configuration_path}"

sudo snap install microk8s --classic --channel 1.27
sudo microk8s status --wait-ready
sudo microk8s kubectl wait --namespace metallb-system --for=condition=Available deployment/controller
sudo microk8s kubectl wait pod --namespace=metallb-system --selector=app=metallb --for=condition=Ready --timeout=5m
sudo microk8s kubectl create namespace "${argocd_namespace}"
sudo microk8s kubectl apply -f "${argocd_install_manifest}" --namespace="${argocd_namespace}"
sudo microk8s kubectl wait --for=condition=Available deployment/argocd-server --timeout=5m

sudo microk8s kubectl apply -f "${argocd_management}" --namespace="${argocd_namespace}"
sudo microk8s kubectl apply -f "${kafkagram_applicaiton}" --namespace="${argocd_namespace}"

# login with admin user and below token (ignore an ending '%'):
sudo microk8s kubectl --namespace="${argocd_namespace}" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode && echo
