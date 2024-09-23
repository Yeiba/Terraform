# Kubernetes self managed auto scalling group cluster with Kubeadm on AWS using Terraform & Ansible.

### Tech Stack

Terraform, Ansible, Docker, cri-dockerd, kubeadm, Kubernetes, Ubuntu, AWS {VPC, EC2, NLB, ALB, ingress nginx controller}

This repo contain the all required automation code for setting up Kubernetes cluster using kubeadm in AWS cloud environment. I have tested all the scripts successfully on Ubuntu 18.04.

#### Infrastructure Provisioning

Terraform for all the infrastructure provisioning automation.

#### Kubernetes Cluster Setup

Ansible for all Server & Cluster configurations.

## Architecture Diagram

![alt text](https://raw.githubusercontent.com/lkravi/kube8aws/multi-master/architecture.png)

### Prerequisites

* You need to have your [AWS CLI configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).

## Usage

Clone this repo first then check the vars.tf for the AWS & Kubernetes cluster configurations. I already added default values for each variable. You can override any variable via command line or as a variable file.
