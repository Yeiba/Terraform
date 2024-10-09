# **Self-managed Kubernetes cluster**:

### **1. EC2 Instances (t3.medium)**

- **Instance Cost**: $0.0108 per hour (Linux, on-demand pricing for t3.medium in the US-East region).
- **Monthly Cost (per instance)** = $0.0108/hour * 24 hours/day * 30.4 days/month = **$7.87/month** per t3.medium instance.

#### **Master Nodes (3 instances)**

- **Total Cost (3 master nodes)** = 3 * $7.87 = **$23.61/month**.

#### **Worker Nodes (3–20 instances)**

- **Minimum Setup (3 worker nodes)** = 3 * $7.87 = **$23.61/month**.
- **Maximum Setup (20 worker nodes)** = 20 * $7.87 = **$157.40/month**.

#### **Bastion Host (1 instance)**

- **Total Cost (1 bastion host)** = 1 * $7.87 = **$7.87/month**.

---

### **2. Load Balancers**

- **Application Load Balancer (ALB)**:

  - **Fixed Cost**: $16.85/month.
  - **Data Processed**: $0.008 per LCU-hour.
  - **Total Cost for ALB** (estimate) = **$22.88/month**.
- **Network Load Balancer (NLB)**:

  - **Fixed Cost**: $25.20/month.
  - **Data Processed**: $0.006 per NLCU-hour.
  - **Total Cost for NLB** (estimate) = **$93.95/month**.

---

### **3. S3 Bucket**

- **Storage Cost**: $0.023 per GB.
- **Requests and Data Transfer Costs**: Based on average usage, assume:
  - 100,000 PUT, COPY, POST, and LIST requests = $0.005 per 1,000 requests.
  - 1 GB data transfer out = $0.09/GB.

#### **Total S3 Cost (for typical usage)**

- **Estimate** = **$32.58/month** (storage, requests, and data transfer combined).

---

### **4. Total Monthly Cost Summary**

The following table outlines the **minimum** and **maximum** setup costs:


| **Component**                                | **Minimum Setup** (3 master, 3 worker) | **Maximum Setup** (3 master, 20 worker) |
| -------------------------------------------- | -------------------------------------- | --------------------------------------- |
| EC2 Instances (3x master nodes)              | $23.61                                 | $23.61                                  |
| EC2 Instances (3–20x worker nodes)          | $23.61 (3 workers)                     | $157.40 (20 workers)                    |
| EC2 Instance (1x bastion host)               | $7.87                                  | $7.87                                   |
| ALB (Application Load Balancer)              | $22.88                                 | $22.88                                  |
| NLB (Network Load Balancer)                  | $93.95                                 | $93.95                                  |
| S3 Bucket (Storage, Requests, Data Transfer) | $32.58                                 | $32.58                                  |

---

### **Final Total**:


| **Setup**                                           | **Cost**           |
| --------------------------------------------------- | ------------------ |
| **Minimum Setup** (3 master nodes, 3 worker nodes)  | **\$285.30/month** |
| **Maximum Setup** (3 master nodes, 20 worker nodes) | **\$818.42/month** |

---

The final monthly cost ranges between **$285.30** (for 3 worker nodes) to **$818.42** (for 20 worker nodes), depending on your specific cluster configuration.


# EKS self-managed Kubernetes cluster

Let’s calculate the cost for using **EKS (Amazon Elastic Kubernetes Service)** with the same setup, where the EKS service replaces the **3 master nodes** and the **bastion host** from your self-managed Kubernetes cluster.

Here are the resources involved:

- **EKS Control Plane**: No need to provision EC2 instances for master nodes or a bastion host, as AWS manages the control plane. EKS charges a flat fee.
- **Worker Nodes**: EC2 instances (t3.medium) for worker nodes.
- **Load Balancers**: One ALB and one NLB.
- **S3 Bucket**: For media storage.

---

### **1. EKS Control Plane**

- **EKS Control Plane Pricing**:
  - **$0.10 per hour** for each EKS cluster.
  - **Monthly Cost for EKS Cluster** = $0.10/hour * 24 hours/day * 30.4 days/month = **$72.96/month**.

---

### **2. EC2 Instances (Worker Nodes)**

- **t3.medium EC2 Instances**: The worker nodes are the same t3.medium instances used in the self-managed Kubernetes cluster.
- **Instance Cost**: $0.0108 per hour.

#### **Worker Nodes (3–20 instances)**

- **Minimum Setup (3 worker nodes)** = 3 * $7.87 = **$23.61/month**.
- **Maximum Setup (20 worker nodes)** = 20 * $7.87 = **$157.40/month**.

---

### **3. Load Balancers**

- **Application Load Balancer (ALB)**:

  - **Fixed Cost**: $16.85/month.
  - **Data Processed**: $0.008 per LCU-hour.
  - **Total Cost for ALB** = **$22.88/month**.
- **Network Load Balancer (NLB)**:

  - **Fixed Cost**: $25.20/month.
  - **Data Processed**: $0.006 per NLCU-hour.
  - **Total Cost for NLB** = **$93.95/month**.

---

### **4. S3 Bucket**

- **Storage Cost**: $0.023 per GB.
- **Requests and Data Transfer Costs**:
  - 100,000 PUT, COPY, POST, and LIST requests = $0.005 per 1,000 requests.
  - 1 GB data transfer out = $0.09/GB.

#### **Total S3 Cost (for typical usage)**

- **Estimate** = **$32.58/month** (storage, requests, and data transfer combined).

---

### **5. Total Monthly Cost Summary**

The following table outlines the **minimum** and **maximum** setup costs:


| **Component**                                    | **Minimum Setup** (3 worker nodes) | **Maximum Setup** (20 worker nodes) |
| ------------------------------------------------ | ---------------------------------- | ----------------------------------- |
| **EKS Control Plane**                            | $72.96                             | $72.96                              |
| **EC2 Instances (3–20x worker nodes)**          | $23.61                             | $157.40                             |
| **ALB (Application Load Balancer)**              | $22.88                             | $22.88                              |
| **NLB (Network Load Balancer)**                  | $93.95                             | $93.95                              |
| **S3 Bucket (Storage, Requests, Data Transfer)** | $32.58                             | $32.58                              |

---

### **Final Total**:


| **Setup**                           | **Cost**           |
| ----------------------------------- | ------------------ |
| **Minimum Setup** (3 worker nodes)  | **\$245.98/month** |
| **Maximum Setup** (20 worker nodes) | **\$379.77/month** |

---

### **Comparison with Self-Managed Kubernetes Cluster**:

- **Self-Managed Kubernetes (Minimum Setup)**: **$285.30/month**.
- **Self-Managed Kubernetes (Maximum Setup)**: **$818.42/month**.
- **EKS Cluster (Minimum Setup)**: **$245.98/month**.
- **EKS Cluster (Maximum Setup)**: **$379.77/month**.

The EKS cluster option is generally cheaper, especially as the worker node count increases, since you’re no longer responsible for managing the master nodes and the bastion host, reducing complexity and costs.


# EKS Auto Scaling Group

Let's recalculate the costs with **Auto Scaling Groups (ASG)** for the worker nodes. An Auto Scaling Group dynamically adjusts the number of worker nodes based on the demand, so instead of calculating for a static number of worker nodes (3–20), we’ll use an average to estimate the costs.

For this scenario, let's assume:

- **Minimum worker nodes**: 3 instances (for base capacity).
- **Maximum worker nodes**: 20 instances (for peak demand).
- **Average worker nodes**: We’ll estimate an average usage of **10 worker nodes** over time to balance between the minimum and maximum load.

### **1. EKS Control Plane**

- **EKS Control Plane Pricing**:
  - **$0.10 per hour** for each EKS cluster.
  - **Monthly Cost for EKS Cluster** = $0.10/hour * 24 hours/day * 30.4 days/month = **$72.96/month**.

---

### **2. EC2 Instances (Worker Nodes with Auto Scaling)**

- **t3.medium EC2 Instances**:
  - **Instance Cost**: $0.0108 per hour.
  - **Monthly Cost for 1 t3.medium** = $0.0108/hour * 24 hours/day * 30.4 days/month = **$7.87/month**.

#### **Auto Scaling Group (Estimated Average: 10 worker nodes)**

- **Worker Nodes Cost**: Average of 10 nodes.
  - **Monthly Cost** = 10 * $7.87 = **$78.70/month**.

---

### **3. Load Balancers**

- **Application Load Balancer (ALB)**:

  - **Fixed Cost**: $16.85/month.
  - **Data Processed**: $0.008 per LCU-hour.
  - **Total Cost for ALB** = **$22.88/month** (includes usage and fixed costs).
- **Network Load Balancer (NLB)**:

  - **Fixed Cost**: $25.20/month.
  - **Data Processed**: $0.006 per NLCU-hour.
  - **Total Cost for NLB** = **$93.95/month** (includes usage and fixed costs).

---

### **4. S3 Bucket**

- **Storage Cost**: $0.023 per GB.
- **Requests and Data Transfer Costs**:
  - 100,000 PUT, COPY, POST, and LIST requests = $0.005 per 1,000 requests.
  - 1 GB data transfer out = $0.09/GB.

#### **Total S3 Cost (for typical usage)**

- **Estimate** = **$32.58/month** (for storage, requests, and data transfer).

---

### **5. Total Monthly Cost Summary**

Let’s calculate the costs based on the **average number of worker nodes (10)** due to the Auto Scaling Group:


| **Component**                                     | **Cost** |
| ------------------------------------------------- | -------- |
| **EKS Control Plane**                             | $72.96   |
| **EC2 Instances (Auto Scaling, 10 worker nodes)** | $78.70   |
| **ALB (Application Load Balancer)**               | $22.88   |
| **NLB (Network Load Balancer)**                   | $93.95   |
| **S3 Bucket (Storage, Requests, Data Transfer)**  | $32.58   |

---

### **Final Total with Auto Scaling Group**:


| **Setup**                                                   | **Cost**           |
| ----------------------------------------------------------- | ------------------ |
| **EKS Cluster with Auto Scaling (Average 10 worker nodes)** | **\$301.07/month** |

---

### **Cost Analysis**:

- **EKS with Auto Scaling** is **\$301.07/month** based on an average of 10 worker nodes.
- Compared to the **manual scaling (from 3 to 20 nodes)** where costs ranged from **$245.98 to $379.77/month**, Auto Scaling helps keep costs predictable while dynamically adapting to load.


# Requests

To estimate the number of requests that your architecture can handle, we need to look at several factors:

1. **Worker Node Capacity**: Each **t3.medium** instance in your EKS worker node pool will handle a certain number of requests based on CPU, memory, and other factors.

   - **t3.medium** instances have 2 vCPUs and 4 GB RAM.
   - On average, a t3.medium instance can handle **500 to 1000 requests per second**, depending on the workload (static vs. dynamic content, application complexity, etc.).
2. **Auto Scaling**:
   With auto-scaling enabled, the number of worker nodes will vary between **3 and 20**, with an average of **10 nodes** (as we assumed).

### **Calculation**:

Let’s break it down into a few scenarios based on the number of worker nodes and the average requests each node can handle:

#### **Base Load (Minimum 3 worker nodes)**:

- **Requests per second (low estimate)**:
  \( 3 \, \text{nodes} \times 500 \, \text{requests/second} = 1500 \, \text{requests/second} \)
- **Requests per second (high estimate)**:
  \( 3 \, \text{nodes} \times 1000 \, \text{requests/second} = 3000 \, \text{requests/second} \)

#### **Average Load (Average 10 worker nodes)**:

- **Requests per second (low estimate)**:
  \( 10 \, \text{nodes} \times 500 \, \text{requests/second} = 5000 \, \text{requests/second} \)
- **Requests per second (high estimate)**:
  \( 10 \, \text{nodes} \times 1000 \, \text{requests/second} = 10000 \, \text{requests/second} \)

#### **Peak Load (Maximum 20 worker nodes)**:

- **Requests per second (low estimate)**:
  \( 20 \, \text{nodes} \times 500 \, \text{requests/second} = 10000 \, \text{requests/second} \)
- **Requests per second (high estimate)**:
  \( 20 \, \text{nodes} \times 1000 \, \text{requests/second} = 20000 \, \text{requests/second} \)

---

### **Daily and Monthly Request Handling**:

We can now extrapolate the request-handling capacity to a daily and monthly scale.

#### **Average Load (10 worker nodes)**:

- **Requests per second**: 5,000 to 10,000 requests/second.
- **Requests per day**:
  \( 5000 \, \text{requests/second} \times 60 \, \text{seconds/minute} \times 60 \, \text{minutes/hour} \times 24 \, \text{hours/day} \)
  = **432 million to 864 million requests/day**.
- **Requests per month**:
  \( 432 \, \text{million requests/day} \times 30.4 \, \text{days/month} = 13.1 \, \text{billion requests/month} \).
  \( 864 \, \text{million requests/day} \times 30.4 \, \text{days/month} = 26.3 \, \text{billion requests/month} \).

---

### **Peak Load (20 worker nodes)**:

- **Requests per second**: 10,000 to 20,000 requests/second.
- **Requests per day**:
  \( 10000 \, \text{requests/second} \times 60 \times 60 \times 24 \)
  = **864 million to 1.73 billion requests/day**.
- **Requests per month**:
  \( 864 \, \text{million requests/day} \times 30.4 = 26.3 \, \text{billion requests/month} \).
  \( 1.73 \, \text{billion requests/day} \times 30.4 = 52.6 \, \text{billion requests/month} \).

---

### **Summary of Request Handling Capacity**:


| **Scenario**                | **Requests/Second** | **Requests/Day**               | **Requests/Month**           |
| --------------------------- | ------------------- | ------------------------------ | ---------------------------- |
| **Base Load (3 nodes)**     | 1,500 – 3,000      | 129.6 million – 259.2 million | 3.94 billion – 7.87 billion |
| **Average Load (10 nodes)** | 5,000 – 10,000     | 432 million – 864 million     | 13.1 billion – 26.3 billion |
| **Peak Load (20 nodes)**    | 10,000 – 20,000    | 864 million – 1.73 billion    | 26.3 billion – 52.6 billion |

This estimation assumes typical workloads and can vary depending on the type of application (CPU-bound, I/O-bound) and the actual request complexity.
