#!/bin/bash

image="20.04"
cpus="4"
mem="8G"
disk="20GB"
vm_name="microk8s"
local_launch_configuration="microk8s-config.yaml"
tmp_path="/tmp/{$launch_configuration_name}"
launch_configuration_dir="/root/snap/microk8s/common/"
launch_configuration_name=".microk8s.yaml"
launch_configuration_path="${launch_configuration_dir}${launch_configuration_name}"
argocd_install_manifest="https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/install.yaml"

multipass launch "${image}" --name "${vm_name}" --cpus "${cpus}" --memory "${mem}" --disk "${disk}"

multipass exec "${vm_name}" -- sudo mkdir -p "${launch_configuration_dir}"
multipass transfer "${local_launch_configuration}" "${vm_name}:${tmp_path}"
multipass exec "${vm_name}" -- sudo cp "${tmp_path}" "${launch_configuration_path}"

multipass exec "${vm_name}" -- sudo snap install microk8s --classic --channel 1.27
multipass exec "${vm_name}" -- sudo microk8s status --wait-ready
multipass exec "${vm_name}" -- sudo microk8s kubectl wait --namespace metallb-system --for=condition=Available deployment/controller


multipass exec "${vm_name}" -- sudo microk8s kubectl apply -f "${argocd_install_manifest}"
multipass exec "${vm_name}" -- sudo microk8s kubectl wait --for=condition=Available deployment/argocd-server --timeout=5m
