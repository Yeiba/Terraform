This solution of setting up an **NFS server in one Kubernetes cluster** and using it for persistent volumes in another Kubernetes cluster, here’s a step-by-step guide that encapsulates both clusters:

### Cluster 1: NFS Server Setup in Kubernetes (Private Subnet)

#### 1. **Deploy NFS Server on the First Kubernetes Cluster:**

You will deploy an NFS server in this cluster.

1. **Create a StatefulSet for the NFS Server:**

   ```yaml
   apiVersion: apps/v1
   kind: StatefulSet
   metadata:
     name: nfs-server
     namespace: nfs
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: nfs-server
     serviceName: "nfs-server"
     template:
       metadata:
         labels:
           app: nfs-server
       spec:
         containers:
         - name: nfs-server
           image: itsthenetwork/nfs-server-alpine:latest
           ports:
           - name: nfs
             containerPort: 2049
           - name: mountd
             containerPort: 20048
           - name: rpcbind
             containerPort: 111
           volumeMounts:
           - name: nfs-volume
             mountPath: /nfsshare
     volumeClaimTemplates:
     - metadata:
         name: nfs-volume
       spec:
         accessModes: [ "ReadWriteOnce" ]
         resources:
           requests:
             storage: 10Gi
   ```
2. **Expose the NFS Server:**

   Create a `Service` of type **LoadBalancer** using an NLB (Network Load Balancer) to expose the NFS server to the second Kubernetes cluster.

   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: nfs-service
     namespace: nfs
     annotations:
       service.beta.kubernetes.io/aws-load-balancer-type: "nlb"  # Using NLB
   spec:
     selector:
       app: nfs-server
     ports:
       - protocol: TCP
         port: 2049  # NFS Port
         targetPort: 2049
     type: LoadBalancer
   ```

#### 2. **Configure NLB:**

Once the service is created, an NLB will be provisioned in AWS. Use the DNS name of the NLB to connect to this NFS server from other clusters.

### Cluster 2: NFS Client in Another Kubernetes Cluster

#### 3. **Install NFS Client Provisioner in the Second Cluster:**

The second cluster will use the NFS server from the first cluster for persistent storage.

1. **Install NFS Subdir External Provisioner Helm Chart:**

   First, add the NFS client provisioner Helm chart:

   ```bash
   helm repo add nfs-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
   ```
2. **Install NFS Client Provisioner:**

   Use the DNS name from the NLB created in Cluster 1 as the NFS server address.

   ```bash
   helm install nfs-client nfs-provisioner/nfs-subdir-external-provisioner \
     --set nfs.server=<NLB-DNS-NAME> \
     --set nfs.path=/
   ```

#### 4. **Create StorageClass in Cluster 2:**

Create a `StorageClass` to allow dynamic provisioning of Persistent Volume Claims (PVCs) in Cluster 2 using the NFS server from Cluster 1.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-client
provisioner: cluster.local/nfs-client
reclaimPolicy: Delete
mountOptions:
  - vers=4.1
```

#### 5. **Create Persistent Volume Claim (PVC):**

Now, you can create a Persistent Volume Claim that will use the NFS server for storage.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
  storageClassName: nfs-client
```

#### 6. **Use the PVC in Your Pods:**

You can now use the `nfs-pvc` in your applications by specifying it in your Pod definitions.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nfs-test-pod
spec:
  containers:
    - name: nfs-test-container
      image: nginx
      volumeMounts:
        - name: nfs-storage
          mountPath: /usr/share/nginx/html
  volumes:
    - name: nfs-storage
      persistentVolumeClaim:
        claimName: nfs-pvc
```

### Key Considerations:

1. **Security Groups:**
   Ensure that the security groups for both clusters allow inbound traffic on port **2049** for NFS.
2. **Firewall Rules:**
   Open the necessary port **2049** between the two clusters for NFS traffic.
3. **DNS and Access:**
   Ensure that the second cluster can access the NLB DNS name from Cluster 1, either via VPC peering, Transit Gateway, or private networking.

### Conclusion:

With this setup:

- **Cluster 1**: Acts as the NFS server hosting the persistent volumes, exposed via a Network Load Balancer (NLB).
- **Cluster 2**: Acts as the NFS client using the NFS volumes for persistent storage via the dynamic NFS provisioner.

This allows **Cluster 2** to use **Cluster 1's** NFS server for persistent storage using the NFS protocol with NLB for external access.
