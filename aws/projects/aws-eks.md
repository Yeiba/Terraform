```
 aws sts get-caller-identity --profile eks-admin
```

```
aws eks update-kubeconfig \
--region us-east-2 \
--name staging-demo \
--profile eks-admin
```

```
kubectl config view --minify
```

```
kubectl auth can-i "*" "*"
```
