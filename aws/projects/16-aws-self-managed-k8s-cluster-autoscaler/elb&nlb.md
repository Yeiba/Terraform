To attach the NGINX Ingress Controller to an Application Load Balancer (ALB) after provisioning, follow these steps:

### 1. **Enable the NGINX Ingress Controller to Use AWS ALB as a Service**

You need to configure the NGINX Ingress Controller to expose itself via the ALB. In Kubernetes, you can use a Service of type `LoadBalancer` to do this.

1. First, make sure you have the NGINX Ingress Controller installed. If not, install it using the following command:

   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
   ```
2. Next, configure the NGINX Ingress Controller's service to be of type `LoadBalancer`, which will allow AWS to automatically attach the ALB to it. Here's an example of how you can modify the NGINX Ingress Controller Service definition:

### 2. **Edit NGINX Ingress Controller Service**

If the NGINX Ingress Controller is deployed, you need to modify its Service to be of type `LoadBalancer` and add the necessary annotations to use the AWS ALB.

1. Find the `ingress-nginx-controller` service by running:

   ```bash
   kubectl get svc -n ingress-nginx
   ```
2. Edit the service:
3. Using NodePort Instead of LoadBalancer
   If your environment does not support an external load balancer (e.g., a self-managed Kubernetes cluster), you can change the ingress-nginx-controller service to use NodePort instead of LoadBalancer. Here’s how you can do it:

   ```bash
   kubectl edit svc ingress-nginx-controller -n ingress-nginx
   ```
4. Modify the service YAML file to include these fields:

kubectl edit svc ingress-nginx-controller -n ingress-nginx

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"  # Use "nlb" for Network Load Balancer or "elb" for classic Load Balancer
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
    service.beta.kubernetes.io/aws-load-balancer-subnets: subnet-XXXA,subnet-XXXXB
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:your-cert-arn-here
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "http"
    service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "https"
    service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: "3600"
spec:
  type: LoadBalancer
  ports:
    - name: http
      port: 80
      targetPort: 80
    - name: https
      port: 443
      targetPort: 443
  selector:
    app.kubernetes.io/name: ingress-nginx
```

network load balencer

```yaml

apiVersion: v1
kind: Service
metadata:
  name: nginx-ingress
  namespace: ingress-nginx
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
spec:
  externalTrafficPolicy: Local
  type: LoadBalancer
  ports:
    - name: http
      port: 80
      targetPort: 80
    - name: https
      port: 443
      targetPort: 443
  selector:
    app: nginx-ingress

```

- **`service.beta.kubernetes.io/aws-load-balancer-type`**: Set this annotation to `nlb` (Network Load Balancer) or `elb` (Application Load Balancer).
- **`service.beta.kubernetes.io/aws-load-balancer-ssl-cert`**: This specifies the Amazon Resource Name (ARN) of your TLS/SSL certificate in AWS Certificate Manager (ACM).
- **`service.beta.kubernetes.io/aws-load-balancer-backend-protocol`**: Defines that the backend should use HTTP to communicate.
- **`service.beta.kubernetes.io/aws-load-balancer-ssl-ports`**: Specifies which ports should handle SSL traffic, typically port `443`.

### 3. **Wait for the ALB to Attach to the NGINX Ingress Controller**

Once the service is updated, Kubernetes will provision an AWS Application Load Balancer and attach it to the NGINX Ingress Controller.

1. Check the status of the service and verify that the ALB has been created:

   ```bash
   kubectl get svc -n ingress-nginx
   ```
2. You should see an external IP address associated with the service. This is the DNS name of the ALB.

### 4. **Configure DNS (Optional)**

If you want to associate a domain name with the ALB, you can create an `A` or `CNAME` record in your DNS provider pointing to the external DNS name of the load balancer.

### 5. **Deploy Ingress Resources**

Once the ALB is attached to the NGINX Ingress Controller, you can define Ingress resources to expose your services.

Here's an example of an Ingress resource:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  namespace: default
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - host: example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-service
                port:
                  number: 80
  tls:
    - hosts:
        - example.com
      secretName: tls-secret  # A Kubernetes secret that stores the SSL certificate
```

This Ingress definition routes traffic for `example.com` to `my-service` and uses SSL/TLS for secure communication.

### Summary of Steps

1. Modify the NGINX Ingress Controller service to be of type `LoadBalancer`.
2. Add AWS-specific annotations to provision an ALB with SSL termination.
3. Wait for the ALB to attach to the NGINX Ingress Controller.
4. Optionally configure DNS records to point to the ALB.
5. Deploy Ingress resources to route traffic to your services through the ALB.

This approach ensures that your NGINX Ingress Controller is exposed through an ALB with SSL termination.

Yes, you can attach a **Network Load Balancer (NLB)** to the **Ingress NGINX Controller's external IP address** in a Kubernetes cluster. This is a common setup when you want to use the NLB for Layer 4 (TCP/UDP) routing, combined with NGINX Ingress for Layer 7 (HTTP/HTTPS) routing. Here's how you can achieve this setup and what it entails.

### How It Works:

1. **Network Load Balancer (NLB)**:

   - The NLB operates at Layer 4, handling TCP/UDP traffic. It can forward traffic to the Kubernetes nodes running the NGINX Ingress Controller.
   - The NLB can be configured to point to the external IP addresses of the Kubernetes nodes where the NGINX Ingress Controller is running.
   - The NLB forwards the traffic to the Ingress Controller, which handles Layer 7 routing (e.g., HTTP/HTTPS).
2. **Ingress NGINX Controller**:

   - The NGINX Ingress Controller operates at Layer 7 (application layer). It receives the traffic from the NLB and applies routing rules (e.g., path-based, host-based routing).
   - The Ingress Controller manages the traffic for the services running inside your Kubernetes cluster.
   - You typically expose the NGINX Ingress Controller using a **Service of type LoadBalancer** or **Service of type NodePort**.

### Steps to Attach NLB to NGINX Ingress Controller:

1. **Create NGINX Ingress Controller**:
   If you don't already have the NGINX Ingress Controller deployed, you can install it using Helm or YAML manifests. Make sure to expose it using a `Service` with **type LoadBalancer** or **type NodePort**.

   - **Type LoadBalancer**: Automatically provisions an AWS Elastic Load Balancer (typically an NLB in the case of AWS) and attaches it to your Ingress Controller.
   - **Type NodePort**: Exposes the Ingress Controller on a specific port across all the nodes, which can then be manually attached to an NLB.

   Example for Helm installation:

   ```bash
   helm install ingress-nginx ingress-nginx \
     --repo https://kubernetes.github.io/ingress-nginx \
     --namespace ingress-nginx \
     --set controller.service.type=LoadBalancer
   ```
2. **Set NLB Annotations (AWS Specific)**:
   To ensure the Ingress NGINX Controller uses an NLB, you can add annotations to the Ingress Service. These annotations inform AWS to provision an NLB instead of an Application Load Balancer (ALB).

   Example of a `Service` manifest with NLB-specific annotations:

   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: ingress-nginx-controller
     namespace: ingress-nginx
     annotations:
       service.beta.kubernetes.io/aws-load-balancer-type: "nlb"  # Use NLB
       service.beta.kubernetes.io/aws-load-balancer-internal: "true"  # (Optional) If you want to make the NLB internal
   spec:
     type: LoadBalancer
     ports:
       - name: http
         port: 80
         targetPort: http
       - name: https
         port: 443
         targetPort: https
     selector:
       app.kubernetes.io/name: ingress-nginx
   ```

   - `service.beta.kubernetes.io/aws-load-balancer-type: "nlb"`: This tells AWS to use a Network Load Balancer instead of an Application Load Balancer.
   - `service.beta.kubernetes.io/aws-load-balancer-internal: "true"`: (Optional) If you want the NLB to be internal and not publicly accessible.
3. **Manual NLB Attachment (NodePort Service)**:
   If you use a `NodePort` service for the NGINX Ingress Controller, you need to manually create the NLB and configure its target groups to point to the Kubernetes worker nodes on the NodePort range (typically 30000-32767).

   Steps:

   - Manually create an NLB in the AWS console or via Terraform/CloudFormation.
   - Create target groups pointing to the Kubernetes worker node IPs on the NodePort of the NGINX Ingress Controller.
   - Update your NLB listeners to forward traffic (TCP/UDP) to the target groups.
   - Configure health checks to monitor the health of the Ingress Controller on the NodePort.

### Benefits of Using NLB with NGINX Ingress Controller:

1. **Improved Performance**: NLBs are optimized for high throughput and low latency at Layer 4, making them ideal for handling large amounts of traffic.
2. **High Availability**: The NLB distributes traffic across multiple availability zones, ensuring high availability for your services.
3. **Security**: If needed, you can create an **internal** NLB (accessible only within your VPC) and route traffic securely to your private Kubernetes nodes.
4. **Protocol Flexibility**: NLB supports TCP/UDP traffic, so if you're using protocols other than HTTP/HTTPS (such as gRPC), NLB is a good choice.

### Considerations:

- **Health Checks**: Ensure that your NLB is configured with proper health checks to monitor the health of the NGINX Ingress Controller.
- **Costs**: Using an NLB with the NGINX Ingress Controller incurs costs for both the load balancer and the resources in your cluster. Ensure you optimize the configuration based on traffic needs.
- **Sticky Sessions**: NLB does not natively support sticky sessions (session affinity), so if you need session persistence, you might need additional configuration on the NGINX side.

### Example Diagram:

```plaintext
+-------------+           +------------+             +-----------------+
|  Public ALB |  ----->   |   Public    |  ----->     | NGINX Ingress   |
|   (Layer 7) |           |   NLB       |             |  Controller     |
|             |           | (Layer 4)   |             | (Private Subnet)|
+-------------+           +------------+             +-----------------+
                                                   Target: EC2 Worker Nodes
                                                   (Private Subnet)
```

### Conclusion

Following these steps will set up Grafana and Prometheus in your Kubernetes cluster and enable access to Grafana via the ALB using Ingress. If you encounter any issues or have further questions, feel free to ask!

```
sudo helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
sudo helm repo update
sudo helm install metrics-server metrics-server/metrics-server --namespace kube-system


sudo helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
sudo helm repo update

sudo helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --set grafana.enabled=true \
  --set grafana.replicaCount=3 \
  --set prometheus.prometheusSpec.replicas=3 \
  --set grafana.ingress.enabled=true \
  --set grafana.ingress.ingressClassName=nginx-alb
```

To get the username and password for logging into Grafana, you'll need to retrieve them from the Kubernetes secrets created by the Helm chart. Here's how you can do that:

1. First, find the name of the Grafana secret:

```bash
kubectl get secrets | grep grafana
```

Look for a secret named something like `prometheus-stack-grafana`. The exact name may vary depending on your release name.

2. Once you have the secret name, you can decode the username and password:

For the username:

```bash
kubectl get secret prometheus-stack-grafana -o jsonpath="{.data.admin-user}" | base64 --decode
```

For the password:

```bash
kubectl get secret prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
```

Replace `prometheus-stack-grafana` with the actual name of your Grafana secret if it's different.

3. If you want to see both at once, you can use:

```bash
echo "Username: $(kubectl get secret prometheus-stack-grafana -o jsonpath="{.data.admin-user}" | base64 --decode)"
echo "Password: $(kubectl get secret prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)"
```

Remember that the default username is typically "admin", but the password is usually randomly generated for security reasons.

4. If you want to change the password, you can do so through the Grafana UI after logging in, or by updating the Kubernetes secret and restarting the Grafana pod.

Important security note: Be cautious with how you handle these credentials, especially the password. Avoid storing them in plain text or sharing them insecurely.

Would you like me to explain how to change the password or set up a more secure authentication method for Grafana?

### Conclusion:

Yes, attaching an **NLB** to the **Ingress NGINX Controller's external IP address** is a valid approach and can be implemented efficiently in AWS using Kubernetes annotations. This setup allows you to combine the low-latency routing of NLB with the advanced HTTP routing capabilities of the NGINX Ingress Controller.


# jenkins


You're correct! The command to retrieve the initial admin password for Jenkins should be executed on a specific pod, not the service. Here’s how you can do it:

1. **Get the name of the Jenkins pod:**

   ```bash
   kubectl get pods --namespace default -l app=jenkins
   ```
2. **Execute the command on the specific pod:**
   Replace `<jenkins-pod-name>` with the name of the Jenkins pod you found in the previous step.

   ```bash
   kubectl exec --namespace default -it <jenkins-last-pod-name> -- cat /var/jenkins_home/secrets/initialAdminPassword
   ```

This should correctly retrieve the initial admin password for Jenkins. If you still have issues, please check the logs of the pod or ensure Jenkins has started successfully.
