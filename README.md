# -Kubernetes
### **Complete Process for Installing Kubernetes on AWS EC2 Instances**  

Follow these steps to set up a **Kubernetes Cluster** on AWS EC2 instances.

---

### **Step 1: Create RSA Key Pair**  
- Go to **AWS Management Console** → **EC2** → **Key Pairs**.  
- Create an **RSA Key Pair** for SSH access.  
- Download the **.pem** file and keep it secure.

---

### **Step 2: Configure Security Groups**  
Create two security groups:  

#### **2.1 Master Security Group (`k8s-master-sg`)**  
- Allow **SSH (Port 22)** from your IP.  
- Allow **All Traffic** from the **Worker Node Security Group**.  

#### **2.2 Worker Security Group (`k8s-node-sg`)**  
- Allow **SSH (Port 22)** from your IP.  
- Allow **All Traffic** from the **Master Node Security Group**.  

---

### **Step 3: Launch EC2 Instances**  

#### **3.1 Launch Master Node**  
- Launch an **EC2 instance** with the following configurations:  
  - **Instance Type:** t2.micro  
  - **Name Tag:** `k8s-master`  
  - **OS:** Ubuntu  
  - Select the **RSA Key Pair** created earlier.  
  - Attach the **Master Security Group** (`k8s-master-sg`).  
  - Go to **Advanced Details → User Data** and paste the script content from `kubemaster.sh`.  

---

#### **3.2 Launch Worker Node**  
- Launch another **EC2 instance** with the following configurations:  
  - **Instance Type:** t2.micro  
  - **Name Tag:** `k8s-node01`  
  - **OS:** Ubuntu  
  - Select the **RSA Key Pair** created earlier.  
  - Attach the **Worker Security Group** (`k8s-node-sg`).  
  - Go to **Advanced Details → User Data** and paste the script content from `kubenode.sh`.

---

### **Step 4: Initialize Kubernetes Cluster**  

#### **4.1 Get the Join Command on Master Node**  
Once the **Master Node** is up, connect via SSH:  
```sh
ssh -i your-key.pem ubuntu@<master-ip>
```
Then run:  
```sh
kubeadm token create --print-join-command
```
This command will generate output like:  
```sh
kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

---

### **Step 5: Join Worker Node to Cluster**  

On the **Worker Node**, connect via SSH:  
```sh
ssh -i your-key.pem ubuntu@<worker-ip>
```
Execute the **join command** copied from the master node:  
```sh
sudo kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

---

### **Step 6: Verify Cluster Setup**  
On the **Master Node**, verify that both nodes are connected:  
```sh
kubectl get nodes
```
Expected Output:  
```
NAME         STATUS   ROLES          AGE   VERSION
k8s-master   Ready    control-plane   10m   v1.30.0
k8s-node01   Ready    <none>          5m    v1.30.0
```

---

### **Step 7: Test Kubernetes Deployment**  
Deploy a simple **Nginx Pod** to verify the setup:  
```sh
kubectl create deployment nginx --image=nginx
kubectl get pods -o wide
```
If the pod is running, your Kubernetes cluster is successfully set up! 🎯🚀
