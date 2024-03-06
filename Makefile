.PHONY: create-cluster destroy-cluster install-argocd

# Path to save the workbench kubeconfig
KUBECONFIG_PATH := $(shell pwd)/workbench-kubeconfig
CLUSTER_NAME := workbench

# Create a kind cluster with a specific name and kubeconfig
create-cluster:
	kind create cluster --config kind-config.yaml --kubeconfig $(KUBECONFIG_PATH)
	@echo "Cluster 'workbench' created. Kubeconfig is located at $(KUBECONFIG_PATH)"

# Install Argo CD in the kind cluster
install-argocd:
	kubectl --kubeconfig $(KUBECONFIG_PATH) create namespace argocd || true
	kubectl --kubeconfig $(KUBECONFIG_PATH) apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl --kubeconfig $(KUBECONFIG_PATH) rollout status deploy/argocd-server -n argocd
	@echo "Argo CD has been installed. Visit https://argoproj.github.io/argo-cd/getting_started/ for next steps."

start-argocd:
	kubectl --kubeconfig=$(KUBECONFIG_PATH) port-forward svc/argocd-server -n argocd 8080:443
	@echo "Argo CD API server port is now forwarded to localhost:8080."
	
# Configure Argo CD CLI to interact with the installed Argo CD and clean up afterwards
# Configure Argo CD CLI to interact with the installed Argo CD and clean up afterwards
configure-argocd-cli:
	@echo "Forwarding the Argo CD API server port to localhost..."
	@kubectl --kubeconfig=$(KUBECONFIG_PATH) port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 & \
	PID=$$!; \
	sleep 5; \
	echo "Retrieving the initial admin password..."; \
	ARGOCD_PWD=$$(kubectl --kubeconfig=$(KUBECONFIG_PATH) get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode); \
	echo "Configuring the Argo CD CLI..."; \
	argocd login localhost:8080 --username admin --password $$ARGOCD_PWD --insecure; \
	echo "Killing the port-forward process..."; \
	kill $$PID
	@echo "Argo CD CLI is configured to interact with your cluster, and the port-forward process has been terminated."

# Destroy the kind cluster
destroy-cluster:
	kind delete cluster --name $(CLUSTER_NAME)
	@rm -f $(KUBECONFIG_PATH)
	@echo "Cluster 'workbench' and its kubeconfig have been removed."
