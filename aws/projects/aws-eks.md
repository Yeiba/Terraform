```
aws eks update-kubeconfig \
--region us-east-2 \
--name staging-demo \
--profile eks-admin
```

```
kubectl config view --minify
```
