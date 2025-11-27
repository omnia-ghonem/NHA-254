
# 🚀 End-to-End DevOps Project  
### Terraform • Ansible • Kubernetes • Prometheus • Grafana • Alertmanager • FastAPI Application

This project demonstrates an **end-to-end automated production environment** built using:

- **Terraform** → Provision AWS infrastructure  
- **Ansible** → Configure EC2, install Kubernetes, deploy monitoring stack  
- **Kubernetes** → Run workloads & services  
- **Prometheus + Grafana + Alertmanager** → Full monitoring stack  
- **FastAPI To-Do App** → Deployed on Kubernetes, instrumented with Prometheus metrics  

---

# 📁 **Project Directory Structure**

```
project/
│
├── terraform/
│   ├── ansible.tf
│   ├── EC2-instances.tf
│   ├── provider.tf
│   ├── variables.tf
│   └── vpc.tf
│
├── ansible/
│   ├── Install_kubernetes/
│   │     └── kubernetes_install_tasks.yaml
│   │
│   ├── Install_monitoring_tools/
│   │     ├── Install_Alertmanager/
│   │     │     ├── alert_manager_install_tasks.yaml
│   │     │     └── AlertManagerConfigmap.yaml
│   │     ├── Install_Grafana/
│   │     │     ├── grafana_install_tasks.yaml
│   │     │     └── grafana-datasource-config.yaml
│   │     ├── Install_kube_state_metrics/
│   │     │     └── kube_state_metrics_install_tasks.yaml
│   │     ├── Install_Node_Exporter/
│   │     │     └── node_exporter_install_tasks.yaml
│   │     └── Install_Prometheus/
│   │           └── prometheus_install_tasks.yaml
│   │
│   └── To_do_app/
│         ├── app/
│         │     ├── static/style.css
│         │     ├── templates/index.html
│         │     └── main.py
│         ├── k8s/
│         │     ├── deployment.yml
│         │     └── service.yml
│         ├── Dockerfile
│         ├── app_apply_tasks.yaml
│         └── secrets.yaml
│
└── requirements.txt
```

---

#  **1. Terraform — Provision AWS Infrastructure**

Move into Terraform directory:

```bash
cd terraform
```

## Initialize Terraform:

```bash
terraform init
```

## Validate:

```bash
terraform validate
```

## Plan:

```bash
terraform plan
```

## Apply (create infrastructure):

```bash
terraform apply -auto-approve
```

Terraform creates:

- VPC  
- Subnets  
- Internet Gateway  
- Route tables  
- Security Groups  
- EC2 Master Node  
- EC2 Worker Nodes  
- SSH Key Pair  

Terraform Outputs:

- Master Node Public IP  
- Worker Node Private IPs  
- SSH key path  

---

#  **2. Ansible — Configure Kubernetes Cluster**

Move to Ansible directory:

```bash
cd ../ansible
```

#  **3. Ansible — Dynamic Terraform Inventory

You **do NOT need inventory.ini**.

### `inventory.yaml` (Dynamic Inventory)
```yaml
---
plugin: cloud.terraform.terraform_provider
```

### Validate inventory:
```bash
ansible-inventory -i inventory.yaml --graph
```

Expected:
```
@all:
  |--@ungrouped:
  |--@masters:
  |  |--control_node
  |--@workers:
  |  |--worker_node_1
  |  |--worker_node_2
  |  |--worker_node_3
```

## Test connection:

```bash
ansible all -m ping
```

---

## ▶ Step 1 — Install Kubernetes components

```bash
ansible-playbook Install_kubernetes/kubernetes_install_tasks.yaml
```

Installs:

- containerd  
- kubelet  
- kubeadm  
- kubectl  

Performs:

- `kubeadm init`  
- Configure kubectl  
- Deploy Calico CNI  
- Generate join command  
- `Join Worker Nodes with Cluster`

Validate at Master Node:

```bash
kubectl get nodes
```

Expected output:

```
master     Ready
worker1    Ready
worker2    Ready
```

---

#  **3. Install Monitoring Tools**

Your monitoring stack includes:

- Prometheus  
- Alertmanager  
- Grafana  
- Node Exporter  
- Kube-State-Metrics  

---

##  3.1 Install Prometheus


```bash
ansible-playbook Install_monitoring_tools/Install_Prometheus/prometheus_install_tasks.yaml
```
---

## 🟥 3.2 Install Node Exporter

```bash
ansible-playbook Install_monitoring_tools/Install_Node_Exporter/node_exporter_install_tasks.yaml
```

---

## 🟩 3.3 Install Kube-State-Metrics

```bash
ansible-playbook Install_monitoring_tools/Install_kube_state_metrics/kube_state_metrics_install_tasks.yaml
```

---

## 🟨 3.4 Install Grafana

```bash
ansible-playbook Install_monitoring_tools/Install_Grafana/grafana_install_tasks.yaml
```

Datasource is auto-installed using:

```
grafana-datasource-config.yaml
```

---

## 3.5 Install Alertmanager

```bash
ansible-playbook Install_monitoring_tools/Install_Alertmanager/alert_manager_install_tasks.yaml
```

Using configmap to specify the email and app passwords:

```
AlertManagerConfigmap.yaml
```

---

# 📦 **4. Build and Deploy FastAPI Application**

Your FastAPI To-Do App includes:

- `main.py` (FastAPI app with Prometheus metrics)
- HTML Template `index.html`
- CSS `style.css`
- Dockerfile (To build the image)
- Kubernetes manifests (deployment + service)
- Secrets.yaml (Save username and password of docker hub)

---


### Create the secrete.yaml:
- It will ask you for a password → this is your vault password.
```bash
ansible-vault create secrets.yml
```
Then a text editor opens → add your secrets:
   - smtp_username: "Your_Email"
   - smtp_password: "App Password From Account Manager"

Save and exit.
Now secrets.yml is fully encrypted.

### Deploy app:
```bash
ansible-playbook -i inventory.yaml To_do_app/app_apply_tasks.yaml ----ask-vault-pass
```


This applies:

- Deployment (Pods)  
- Service (NodePort)  

---

## ▶ Verify Deployment

```bash
kubectl get pods -n to-do-namespace
kubectl get svc -n to-do-namespace
```

---

# 🌐 **5. Access Application & Monitoring Interfaces**

## ✔ To-Do App:

```
http://<NODE_PUBLIC_IP>:<NODEPORT>
http://<NODE_PUBLIC_IP>:<30080>
```

---

## ✔ Prometheus Web UI:

```
http://<MASTER_IP>:30000
```

---

## ✔ Grafana:

```
http://<MASTER_IP>:32000
```

Default Credentials:

```
username: admin
password: admin
```

---

## ✔ Alertmanager:

```
http://<MASTER_IP>:31000
```

---

# 📈 **6. Application Metrics (Prometheus)**

The FastAPI app exposes metrics using:

```
Instrumentator().instrument(app).expose(app)
```

Metrics endpoint:

```
/metrics
```

Prometheus scrapes:

- HTTP request count  
- Latency  
- Exceptions  
- Uvicorn metrics  
- Custom app metrics  

---

# 🎯 Summary

This project demonstrates:

✔ Infrastructure-as-Code with Terraform  
✔ Configuration Management with Ansible  
✔ Kubernetes Cluster Setup (kubeadm)  
✔ Observability with Prometheus + Grafana + Alertmanager  
✔ Application Deployment on Kubernetes  
✔ Automated metrics exposure for monitoring  

---

