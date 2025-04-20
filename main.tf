provider "aws" {
  region = "us-east-1"      # the region you want to create cluster

}


resource "aws_instance" "k8_master_node" {
  ami                                  = "ami-123456"      # provide ami for amazon Linux servers
  associate_public_ip_address          = false
  availability_zone                    = "us-east-1c"
  disable_api_stop                     = false
  disable_api_termination              = false
  ebs_optimized                        = false
  get_password_data                    = false
  hibernation                          = false
  host_id                              = null
  instance_initiated_shutdown_behavior = "stop"
  instance_lifecycle                   = null
  instance_type                        = "t2.medium"
  ipv6_addresses                       = []
  key_name                             = "Docker_key"      # replace with you key
  monitoring                           = false
  outpost_arn                          = null
  password_data                        = null
  placement_group                      = null
  placement_partition_number           = 0
  public_dns                           = null
  public_ip                            = null
  secondary_private_ips                = []
  source_dest_check                    = true
  spot_instance_request_id             = null
  subnet_id                            = "subnet-qweefq122"    # replace with your subnet id
  iam_instance_profile                 = "s3bucketuploader"    # replace with your instance role 
  tags = {
    "Application owner" = "appOwner"
    "Name"              = "MasterNode2"
    "InCluster"         = "yes"
  }
  tags_all = {
    "Application owner" = "appOwner"
    "Name"              = "sWorker2Node"
  }
  tenancy = "default"
  vpc_security_group_ids = [
    "sg-1234jkk45",   # give your security group id where ports are opened for k8 master node server
  ]

  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }


  credit_specification {
    cpu_credits = "standard"
  }

  enclave_options {
    enabled = false
  }

  maintenance_options {
    auto_recovery = "default"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "disabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
    instance_metadata_tags      = "disabled"
  }

  private_dns_name_options {
    enable_resource_name_dns_a_record    = true
    enable_resource_name_dns_aaaa_record = false
    hostname_type                        = "ip-name"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -eux

    # Update system
    sudo yum update -y

    # Install Docker
    sudo yum install -y docker
    sudo systemctl enable --now docker

    # Add Kubernetes repo
    cat <<EOT | sudo tee /etc/yum.repos.d/kubernetes.repo
    [kubernetes]
    name=Kubernetes
    baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
    enabled=1
    gpgcheck=1
    repo_gpgcheck=1
    gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
    EOT

    # Install Kubernetes components
    sudo yum install -y kubelet-1.29.0 kubeadm-1.29.0 kubectl-1.29.0 --disableexcludes=kubernetes
    sudo systemctl enable --now kubelet
    sudo systemctl start kubelet        
    sudo kubeadm init 
    # Create kube config directory for ec2-user
    sudo mkdir -p /home/ec2-user/.kube
    sudo cp -i /etc/kubernetes/admin.conf /home/ec2-user/.kube/config
    sudo chown ec2-user:ec2-user /home/ec2-user/.kube/config
    export KUBECONFIG=/etc/kubernetes/admin.conf

    # sudo mkdir -p $HOME/.kube
    # sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    # sudo chown $(id -u):$(id -g) $HOME/.kube/config
    kubectl apply -f https://docs.projectcalico.org/v3.16/manifests/calico.yaml   
    

   
    

EOF


}
resource "aws_eip" "master_eip" {
  domain = "vpc"
}
resource "aws_eip_association" "master_eip_assoc" {
  instance_id   = aws_instance.k8_master_node.id
  allocation_id = aws_eip.master_eip.id
}
