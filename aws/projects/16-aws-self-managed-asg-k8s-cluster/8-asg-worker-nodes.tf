
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

resource "null_resource" "get_join_command" {
  depends_on = [null_resource.run_ansible]
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
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip sudo kubeadm token create --print-join-command  > /tmp/join_command",
    ] 
  }

  provisioner "local-exec" {
    command = <<EOT
      sleep 20
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/join_command ${path.module}/temp/join_command
    EOT
  }
}

data "local_file" "join_command" {
  depends_on = [null_resource.get_join_command]
  filename = "${path.module}/temp/join_command"
}


locals {
  depends_on = [null_resource.get_join_command]
  join_command = trimspace(data.local_file.join_command.content)
}


resource "aws_launch_template" "worker_launch_template" {
  depends_on = [null_resource.get_join_command]

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
    # set -e

    echo -e "\e[1;32mStarting worker node initialization\e[0m"

    # Update package list
    echo -e "\e[1;32mUpdate package list\e[0m"
    sudo apt-get update -y

    # Install Docker
    echo -e "\e[1;32mInstall Docker\e[0m"
    sudo apt-get install -y docker.io

    # Install APT Transport HTTPS
    echo -e "\e[1;32mInstall APT Transport HTTPS\e[0m"
    sudo apt-get install -y apt-transport-https

    # Install curl
    echo -e "\e[1;32mInstall curl\e[0m"
    sudo apt-get install -y curl

    # Create the keyrings directory if it doesn't exist
    echo -e "\e[1;32mCreate the keyrings directory if it doesn't exist\e[0m"
    sudo mkdir -p /etc/apt/keyrings

    # chmod /etc/apt/keyrings
    echo -e "\e[1;32mchmod /etc/apt/keyrings\e[0m"
    sudo chmod 755 /etc/apt/keyrings

    # Get Kubernetes package key
    echo -e "\e[1;32mGet Kubernetes package key\e[0m"
    sudo sh -c 'curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --batch --yes --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg'

    # Install Kubernetes repository
    echo -e "\e[1;32mInstall Kubernetes repository\e[0m"
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

    # Update package list again
    echo -e "\e[1;32mUpdate package list again\e[0m"
    sudo apt-get update -y
    sudo apt-get install -y git wget curl docker.io make

    # Install Kubelet and Kubeadm
    echo -e "\e[1;32mInstall Kubelet and Kubeadm\e[0m"
    sudo apt-get install -y kubelet kubeadm

    # Start and enable Docker
    echo -e "\e[1;32mStart and enable Docker\e[0m"
    sudo systemctl enable --now docker

    # Install Go
    echo -e "\e[1;32mInstall Go\e[0m"
    GO_VERSION="1.22.0"
    wget "https://golang.org/dl/go$GO_VERSION.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go$GO_VERSION.linux-amd64.tar.gz"
    export PATH=$PATH:/usr/local/go/bin
    go version

    # Clone and build cri-dockerd
    echo -e "\e[1;32mClone and build cri-dockerd\e[0m"
    git clone https://github.com/Mirantis/cri-dockerd.git
    cd cri-dockerd

    # Check Go version requirement in go.mod
    echo -e "\e[1;32mCheck Go version requirement in go.mod\e[0m"
    GO_MOD_VERSION=$(grep -oP 'go \K\d+\.\d+' go.mod)
    echo "Go version required by cri-dockerd: $GO_MOD_VERSION"
    echo "Installed Go version: $GO_VERSION"

    # Build cri-dockerd
    echo -e "\e[1;32mBuild cri-dockerd\e[0m"
    mkdir -p  bin
    go build -o bin/cri-dockerd

    # Install cri-dockerd
    echo -e "\e[1;32mInstall cri-dockerd\e[0m"
    sudo mkdir -p /usr/local/bin
    sudo install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd

    # Verify the installation
    echo -e "\e[1;32mVerify the installation\e[0m"
    ls -l /usr/local/bin/cri-dockerd
    sudo /usr/local/bin/cri-dockerd --version

    # Install systemd units
    echo -e "\e[1;32mInstall systemd units\e[0m"
    sudo cp -a packaging/systemd/* /etc/systemd/system
    sudo sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
    sudo cp /etc/systemd/system/cri-docker.socket /etc/systemd/system/cri-docker.socket.service

    echo -e "\e[1;32mupdate the ExecStart\e[0m"
    sudo sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2736|' /etc/systemd/system/cri-docker.service

    echo -e "\e[1;32msudo systemctl daemon-reload\e[0m"
    sudo systemctl daemon-reload

    echo -e "\e[1;32msudo systemctl restart docker.service\e[0m"
    sudo systemctl restart docker.service

    echo -e "\e[1;32msudo systemctl enable --now cri-docker.socket\e[0m"
    sudo systemctl enable --now cri-docker.socket

    # sudo systemctl status docker.service
    # sudo systemctl status cri-docker.socket

    echo -e "\e[1;32mcd ~\e[0m"
    cd ~

    # Write the SSH key and master IP passed from Terraform
    echo -e "\e[1;32mWrite the SSH key and master IP passed from Terraform\e[0m"

    echo "${local.join_command}" | sudo tee /tmp/join_command

    export JOIN_COMMAND=$(cat /tmp/join_command) | sudo $JOIN_COMMAND

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

