
resource "null_resource" "get_first_master_ip" {
  depends_on = [local_file.ansible_inventory]
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
      sed -n '/\[masters_first\]/,/\[masters_others\]/p' inventory | awk '{print $2}' | grep  ansible_host= | cut -d '=' -f 2 > ${path.module}/temp/master_ip
      chmod 600 ${path.module}/k8_ssh_key.pem
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${path.module}/temp/master_ip ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/master_ip 
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${path.module}/k8s-deployment/ingress-nginx-nlb-4-10.0.yaml ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/ingress-nginx-nlb-4-10.0.yaml
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${path.module}/k8s-deployment/ingress-nginx-alb-4-10.0.yaml ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/ingress-nginx-alb-4-10.0.yaml
    EOT
  }
}

data "local_file" "master_ip" {
  filename = "${path.module}/temp/master_ip"
}
data "local_file" "k8_ssh_key" {
  filename = "${path.module}/k8_ssh_key.pem"
}

locals {
  master_ip = trimspace(data.local_file.master_ip.content)
  k8_ssh_key = trimspace(data.local_file.k8_ssh_key.content)
}


resource "aws_launch_template" "worker_launch_template" {
  depends_on = [null_resource.run_ansible]

  name_prefix   = "worker-lt-"
  image_id      = var.ami_id
  instance_type = var.worker_instance_type
  key_name      = aws_key_pair.k8_ssh.key_name
  vpc_security_group_ids = [aws_security_group.k8_nodes.id, aws_security_group.k8_workers.id]

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 30
      volume_type = "gp2"
    }
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    echo "Starting worker node initialization"

    # Update package list
    sudo apt-get update

    # Install Docker
    sudo apt-get install -y docker.io

    # Install APT Transport HTTPS
    sudo apt-get install -y apt-transport-https

    # Install curl
    sudo apt-get install -y curl

    # Create the keyrings directory if it doesn't exist
    sudo mkdir -p /etc/apt/keyrings

    # Create the keyrings directory if it doesn't exist
    sudo chmod 755 /etc/apt/keyrings

    # Get Kubernetes package key
    sudo sh -c 'curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg'

    # Install Kubernetes repository
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

    # Update package list again
    sudo apt-get update

    # Install Kubelet and Kubeadm
    sudo apt-get install -y kubelet kubeadm

    # Install cri-dockerd
    ARCH=$(dpkg --print-architecture)
    LATEST_CRI_DOCKERD=$(sudo curl -s https://api.github.com/repos/Mirantis/cri-dockerd/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    LATEST_CRI_DOCKERD_NO_V=$(sudo curl -s https://api.github.com/repos/Mirantis/cri-dockerd/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")' | cut -d 'v' -f 2)

    # Download cri-dockerd
    sudo curl -LO "https://github.com/Mirantis/cri-dockerd/releases/download/$LATEST_CRI_DOCKERD/cri-dockerd-$LATEST_CRI_DOCKERD_NO_V.$ARCH.tgz"

    # Extract and move to /usr/local/bin
    sudo tar -xzf "cri-dockerd-$LATEST_CRI_DOCKERD_NO_V.$ARCH.tgz" -C /usr/local/bin/

    sudo mkdir -p /etc/systemd/system/
    sudo chmod 755 /etc/systemd/system/

    # Get systemd unit files for cri-dockerd
    sudo curl -o /etc/systemd/system/cri-docker.service https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.service
    sudo curl -o /etc/systemd/system/cri-docker.socket https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.socket

    # Configure systemd for cri-dockerd
    sudo sed -i 's|/usr/bin/cri-dockerd|/usr/local/bin/cri-dockerd|' /etc/systemd/system/cri-docker.service

    # Reload systemd daemon
    sudo systemctl daemon-reload

    # Start and Enable the cri-dockerd service - cri-docker.service
    sudo systemctl enable --now cri-docker.service

    # Start and enable the cri-dockerd service and socket
    sudo systemctl enable --now cri-docker.service cri-docker.socket

    sudo cat "${local.k8_ssh_key}" > /tmp/k8_ssh_key.pem

    sudo chmod 600 /tmp/k8_ssh_key.pem

    # Get the worker node join command from the first master node
    sudo ssh -o StrictHostKeyChecking=no -i /tmp/k8_ssh_key.pem ubuntu@${local.master_ip} "sudo kubeadm token create --print-join-command"  > /tmp/join_commend

    JOIN_COMMAND=$(sudo cat /tmp/join_commend )

    # Execute the join command
    sudo $JOIN_COMMAND
  EOF
  )

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Worker Node"
    }
  }
}


resource "aws_autoscaling_group" "worker_asg" {
  launch_template {
    id      = aws_launch_template.worker_launch_template.id
    version = "$Latest"
  }

  vpc_zone_identifier = module.vpc.private_subnets

  min_size = var.min_worker_nodes
  max_size = var.max_worker_nodes
  desired_capacity = var.desired_worker_nodes

  health_check_type         = "EC2"
  health_check_grace_period = 300



  tag {
    key                 = "Name"
    value               = "worker-${aws_launch_template.worker_launch_template.id}"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}



resource "aws_autoscaling_policy" "scale_out" {
  name                   = "scale-out"
  scaling_adjustment      = 1
  adjustment_type         = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name  = aws_autoscaling_group.worker_asg.id
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "scale-in"
  scaling_adjustment      = -1
  adjustment_type         = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name  = aws_autoscaling_group.worker_asg.id
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  alarm_name                = "high_cpu_utilization"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_actions             = [aws_autoscaling_policy.scale_out.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.worker_asg.id
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_utilization" {
  alarm_name                = "low_cpu_utilization"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "20"
  alarm_actions             = [aws_autoscaling_policy.scale_in.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.worker_asg.id
  }
}

