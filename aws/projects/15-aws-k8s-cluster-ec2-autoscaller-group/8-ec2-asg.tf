# EC2 Instance for Kubernetes Master
resource "aws_instance" "k8s_master" {
  count                  = var.master_count  # Change to 3 master nodes
  ami                    = var.ami_id
  instance_type          = var.master_instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public_zone1.id # Master should be in the public subnet
  security_groups        = [aws_security_group.k8s_sg.name]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    # Update the package list
    sudo apt-get update -y
    
    # Install Docker
    sudo apt-get install -y docker.io

    # Add Kubernetes repo and install kubeadm, kubelet, and kubectl
    sudo apt-get update && sudo apt-get install -y apt-transport-https curl
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    
    # Enable Docker and Kubelet services
    sudo systemctl enable docker.service
    sudo systemctl enable kubelet.service

    # Initialize Kubernetes Master
    sudo kubeadm init --pod-network-cidr=10.244.0.0/16

    # Set up kubectl for the ubuntu user
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    # Apply Flannel network plugin for pod networking
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
  EOF

  tags = {
    Name = "k8s_master"
  }
}

# Launch configuration for Auto Scaling Group (Worker Nodes)
resource "aws_launch_configuration" "worker_lc" {
  name          = "worker-lc"
  image_id      = var.ami_id
  instance_type = var.worker_instance_type
  security_groups = [aws_security_group.k8s_sg.id]
  key_name      = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    # Update the package list
    sudo apt-get update -y
    
    # Install Docker
    sudo apt-get install -y docker.io

    # Add Kubernetes repo and install kubeadm, kubelet, and kubectl
    sudo apt-get update && sudo apt-get install -y apt-transport-https curl
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    
    # Enable Docker and Kubelet services
    sudo systemctl enable docker.service
    sudo systemctl enable kubelet.service

    # Join worker node to the Kubernetes cluster
    sudo kubeadm join <KUBE_MASTER_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
  EOF
}

# Auto Scaling Group for Worker Nodes
resource "aws_autoscaling_group" "k8s_worker_asg" {
  launch_configuration = aws_launch_configuration.worker_lc.id
  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity
  vpc_zone_identifier  = [aws_subnet.private_zone1.id, aws_subnet.private_zone2.id]  # Private subnets

  tag {
    key                 = "Name"
    value               = "k8s_worker"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Scale up policy
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.k8s_worker_asg.id
}

# Scale down policy
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.k8s_worker_asg.id
}