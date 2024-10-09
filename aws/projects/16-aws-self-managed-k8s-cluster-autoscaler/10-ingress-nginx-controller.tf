
resource "null_resource" "move_manifest_files" {
  triggers = {
    always_run = timestamp()
  }

  connection {
    type        = "ssh"
    host        = aws_instance.bastion.public_ip
    user        = var.ssh_user
    private_key = tls_private_key.ssh.private_key_pem
    insecure    = true
    agent       = false
  }
  
  provisioner "local-exec" {
    command = <<EOT
      sleep 20
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${path.module}/k8s-deployment/ingress-nginx-nlb-4-10.0.yaml ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/ingress-nginx-nlb-4-10.0.yaml
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${path.module}/k8s-deployment/ingress-nginx-alb-4-10.0.yaml ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/ingress-nginx-alb-4-10.0.yaml
    EOT
  }
}

resource "null_resource" "get_pod_ip_ingress_port" {
  depends_on = [aws_autoscaling_group.worker_asg]
  triggers = {
    always_run = timestamp()
  }

  connection {
    type        = "ssh"
    host        = aws_instance.bastion.public_ip
    user        = var.ssh_user
    private_key = tls_private_key.ssh.private_key_pem
    insecure    = true
    agent       = false
  }


  provisioner "remote-exec" {
    inline = [
      "export ip=$(cat /tmp/master_ip)",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip sudo helm repo add flannel https://flannel-io.github.io/flannel/",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip sudo helm install flannel flannel/flannel --namespace kube-system --set podCidr=192.168.0.0/16",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip sleep 440",
      # "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl create ns ingress-nginx-nlb",
      # "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl create ns ingress-nginx-alb",
      "scp -o StrictHostKeyChecking=no /tmp/ingress-nginx-nlb-4-10.0.yaml ${var.ssh_user}@$ip:/tmp/ingress-nginx-nlb-4-10.0.yaml",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl apply -f /tmp/ingress-nginx-nlb-4-10.0.yaml",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip sleep 20",
      "scp -o StrictHostKeyChecking=no /tmp/ingress-nginx-alb-4-10.0.yaml ${var.ssh_user}@$ip:/tmp/ingress-nginx-alb-4-10.0.yaml",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl apply -f /tmp/ingress-nginx-alb-4-10.0.yaml",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip sleep 120",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl get svc -n ingress-nginx-nlb | head -n 2 | grep ingress-nginx-controller | awk '{print $5}' | cut -d ',' -f 1 | cut -d '/' -f 1 | cut -d ':' -f 2 > /tmp/nlb_http_port",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl get svc -n ingress-nginx-nlb | head -n 2 | grep ingress-nginx-controller | awk '{print $5}' | cut -d ',' -f 2 | cut -d '/' -f 1 | cut -d ':' -f 2 > /tmp/nlb_https_port",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl get svc -n ingress-nginx-alb | head -n 2 | grep ingress-nginx-controller | awk '{print $5}' | cut -d ',' -f 1 | cut -d '/' -f 1 | cut -d ':' -f 2 > /tmp/alb_http_port",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl get svc -n ingress-nginx-alb | head -n 2 | grep ingress-nginx-controller | awk '{print $5}' | cut -d ',' -f 2 | cut -d '/' -f 1 | cut -d ':' -f 2 > /tmp/alb_https_port",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip sleep 120",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl get pods -n ingress-nginx-nlb -o wide | head -n 4 | grep ingress-nginx-controller | awk '{print $7}' > /tmp/nlb_pod_ip",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip sleep 20",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl get pods -n ingress-nginx-alb -o wide | head -n 4 | grep ingress-nginx-controller | awk '{print $7}' > /tmp/alb_pod_ip",
      "cat /tmp/nlb_pod_ip",
      "cat /tmp/alb_pod_ip",
      "export nlb_pod_ip=$(cat /tmp/nlb_pod_ip)",
      "export alb_pod_ip=$(cat /tmp/alb_pod_ip)",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl get nodes -o wide | grep -w $nlb_pod_ip | awk '{print $6}' > /tmp/nlb_pod_ip",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip sleep 20",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl get nodes -o wide | grep -w $alb_pod_ip | awk '{print $6}' > /tmp/alb_pod_ip",
      "cat /tmp/nlb_http_port",
      "cat /tmp/nlb_https_port",
      "cat /tmp/nlb_pod_ip",
      "cat /tmp/alb_http_port",
      "cat /tmp/alb_https_port",
      "cat /tmp/alb_pod_ip",
    ] 
  }

  provisioner "local-exec" {
    command = <<EOT
      sleep 20
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/nlb_http_port ${path.module}/temp/nlb_http_port
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/nlb_https_port ${path.module}/temp/nlb_https_port
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/nlb_pod_ip ${path.module}/temp/nlb_pod_ip
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/alb_http_port ${path.module}/temp/alb_http_port
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/alb_https_port ${path.module}/temp/alb_https_port
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/alb_pod_ip ${path.module}/temp/alb_pod_ip
    EOT
  }
}

data "local_file" "nlb_pod_ip" {
  depends_on = [null_resource.get_pod_ip_ingress_port]
  filename = "${path.module}/temp/nlb_pod_ip"
}
data "local_file" "nlb_http_port" {
  depends_on = [null_resource.get_pod_ip_ingress_port]
  filename = "${path.module}/temp/nlb_http_port"
}
data "local_file" "nlb_https_port" {
  depends_on = [null_resource.get_pod_ip_ingress_port]
  filename = "${path.module}/temp/nlb_https_port"
}

#================================================================

data "local_file" "alb_pod_ip" {
  depends_on = [null_resource.get_pod_ip_ingress_port]
  filename = "${path.module}/temp/alb_pod_ip"
}
data "local_file" "alb_http_port" {
  depends_on = [null_resource.get_pod_ip_ingress_port]
  filename = "${path.module}/temp/alb_http_port"
}
data "local_file" "alb_https_port" {
  depends_on = [null_resource.get_pod_ip_ingress_port]
  filename = "${path.module}/temp/alb_https_port"
}

locals {
  nlb_http_port  = tonumber(trimspace(data.local_file.nlb_http_port.content))
  nlb_https_port = tonumber(trimspace(data.local_file.nlb_https_port.content))
  nlb_pod_ip = trimspace(data.local_file.nlb_pod_ip.content)

  alb_http_port  = tonumber(trimspace(data.local_file.alb_http_port.content))
  alb_https_port = tonumber(trimspace(data.local_file.alb_https_port.content))
  alb_pod_ip = trimspace(data.local_file.alb_pod_ip.content)
}
