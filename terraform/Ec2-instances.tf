# resource Creates or manages something in the real world (EC2 instance, VPC, S3 bucket, etc.)
#       resource "aws_instance" "web" { ... }


# data resource allows Terraform to query existing resources or external data and use that information in your configuration.
# Reads existing information from outside Terraform (from AWS, the Internet, or another file)
#      data "aws_ami" "amazon-linux" { ... } or data "http" "myip" { ... }
# A data block looks similar to a resource block, but it doesn’t create anything — it retrieves something that already exists.
# Suppose you want to launch an EC2 instance using the latest Amazon Linux AMI, but you don’t know its ID.Terraform can look it up using a data resource
# Query External Data to get information from outside your cloud provider, like:
#   a JSON file


# locals defines temporary variables (local values) you can reuse inside your Terraform code. 
#       Who provides the value -> Terraform itself (computed or derived)
#       When to use: When you want to avoid repeating logic or compute something dynamically
#       Example use case: Combine strings, extract IPs, calculate CIDRs, reuse computed values
#       Example: local.admin_ip is derived from data.http.myip.body
#       Default overrideable?: No ❌ (fixed inside the config)


# variable Input values that can be passed from outside Terraform (by user, CLI, tfvars file, or environment). 
#       Who provides the value -> You (the user)
#       When to use: When you want to customize the configuration (e.g., instance type, region)
#       Example use case: Instance type, key pair, region, database name
#       Example: local.admin_ip is derived from data.http.myip.body
#       Default overrideable?: Yes ✅ (can be overridden)




# -------------------------------
# Get My Public IP Address for SSH Access
# data "http" "myip":
#   Does not create anything on AWS — it simply fetches data from the Internet.
#   This uses Terraform’s HTTP data source, which performs an HTTP GET request and reads the result.
#   Terraform sends a GET request to: https://checkip.amazonaws.com, which simply returns your public IP address in plain text.
#   Terraform stores that response in memory under: data.http.myip.body
# -------------------------------


#data "http" "myip" { 
#  url = "https://checkip.amazonaws.com"
#}
# chomp() removes the newline at the end.
# Terraform then appends /32, turning it into proper CIDR notation: a single IP address.
#locals {
#  admin_ip = "${chomp(data.http.myip.response_body)}/32" # You can use that string (via local.admin_ip) in your security group to allow SSH access only from your current public IP.
#}


resource "aws_security_group" "common_sg" {
    name        = "kubeadm_demo_sg"
    vpc_id      = aws_vpc.terraform_vpc.id

    # incoming traffic (what’s allowed into the instance)
    # If the two numbers are the same (e.g., from_port = 22, to_port = 22), it means “just that single port.”
    ingress {  
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }

    ingress{
    description = "HTTPS from anywhere"
    from_port  = 443
    to_port    = 443
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]


    }
    # SSH ingress rule
    ingress {
        description = "SSH from anywhere"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]  # Restrict SSH access to my public IP only. 
    }


    ingress {
        description = "Allow all traffic within the security group"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        self        = true
    }


    # outgoing traffic (what’s allowed out of the instance)
    # My EC2 can send traffic anywhere on any port, using any protocol.
    # “All protocols” → doesn’t really have a single port range that makes sense
    # So when you mix protocol = "-1" (all protocols) with port numbers, AWS just ignores the port range and interprets the rule as:“For every protocol, allow everything.”
    # In this case, AWS completely ignores the port range (from_port and to_port) — no matter what numbers you put there.
    # When you decide (specify) the protocol — for example protocol = "tcp" or "udp" instead of "-1" — then AWS does not ignore the ports anymore.

    egress {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"  # -1 means AWS’s way of saying “all protocols” (TCP, UDP, ICMP, etc.).
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "COMMON-SG"
    }

}

resource "aws_security_group" "master_node_sg" {
    name        = "master-node-sg"
    description = "Allow HTTP and SSH traffic"
    vpc_id      = aws_vpc.terraform_vpc.id
    

    ingress {
        description = "Kubelet API from anywhere"
        from_port   = 6443
        to_port     = 6443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Kube-scheduler from anywhere"
        from_port   = 10259
        to_port     = 10259
        protocol    = "tcp"

        cidr_blocks = ["0.0.0.0/0"]
    }


    ingress {
        description = "Kube-controller-manager"
        from_port   = 10257
        to_port     = 10257
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "etcd-server"
        from_port   = 2379
        to_port     = 2380
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "MASTER-NODE-SG"
    }

}



# -------------------------------
# Each instance inside those subnets has its own Security Group
# A VPC is your entire network — like your company’s private data center in AWS.
# Inside it, you can have many subnets (public & private).
# Each subnet can host different types of instances:
#   Public subnet → frontend / web servers
#   Private subnet → backend / database (RDS, etc.)
# Now inside this VPC, we use:
#   Security Groups (SGs) → control traffic at instance level
#   Network ACLs (NACLs) → control traffic at subnet level
# -------------------------------
resource "aws_security_group" "worker_node_sg" {
    name        = "worker-node-sg"
    description = "Allow HTTP and SSH traffic"
    vpc_id      = aws_vpc.terraform_vpc.id
    

    ingress {
        description = "Kubelet API from anywhere"
        from_port   = 10250
        to_port     = 10252
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    ingress {
        description = "Node-port-services"
        from_port   = 30000
        to_port     = 32767
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]

    }
    

    tags = {
      Name = "WORKER-NODE-SG"
    }

}


resource "aws_security_group" "node_exporter_sg" {
    name        = "node-exporter-sg"
    description = "Allow HTTP and SSH traffic"
    vpc_id      = aws_vpc.terraform_vpc.id
    

    ingress {
        description = "Kubelet API from anywhere"
        from_port   = 9100
        to_port     = 9100
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    ingress {
        description = "Node-port-services"
        from_port   = 9200
        to_port     = 9200
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]

    }
    

    tags = {
      Name = "NODE-EXPORTER-SG"
    }

}

resource "aws_security_group" "kube_state_metrics_sg" {
    name        = "kube-state-metrics-sg"
    description = "Allow HTTP and SSH traffic"
    vpc_id      = aws_vpc.terraform_vpc.id
    

    ingress {
        description = "Kubelet API from anywhere"
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    ingress {
        description = "Node-port-services"
        from_port   = 8081
        to_port     = 8081
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]

    }
    

    tags = {
      Name = "KUBE-STATE-METRICS-SG"
    }

}


# Flannel, which is a CNI (Container Network Interface) plugin used in Kubernetes clusters for pod-to-pod communication across nodes.
resource "aws_security_group" "kubeadm_demo_sg_flannel" {
    name        = "kubeadm_demo_sg_flannel"
    vpc_id      = aws_vpc.terraform_vpc.id

    ingress {
        description = "udp backend from anywhere"
        from_port   = 8285
        to_port     = 8285
        protocol    = "udp"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
    ingress {
        description = "udp vxlan backend from anywhere"
        from_port   = 8472
        to_port     = 8472
        protocol    = "udp"
        cidr_blocks = ["0.0.0.0/0"]

    }


    tags = {
      Name = "kubeadm_demo_sg_flannel"
    }

}




# --------------------------------------------------------
# RDS SECURITY GROUP (for DB in Private Subnet)
# Using security_groups instead of cidr_blocks because “Allow traffic from any host inside that subnet (10.0.1.x).”
# That’s good for public access (e.g., web servers, SSH from home, etc.), but not for private, internal connections (like EC2 → RDS), because the internal IPs may change.
# security_groups Allow inbound traffic from any instance that belongs to this other Security Group (frontend_sg).
# That’s more dynamic and secure because:
#   You don’t need to hardcode or guess IP addresses.
#   It automatically includes all EC2s attached to that SG.
#   It updates automatically if you recreate or replace instances.
# --------------------------------------------------------
resource "aws_security_group" "rds_sg" {
    name        = "rds-sg"
    description = "Allow MySQL traffic from web servers"
    vpc_id      = aws_vpc.terraform_vpc.id

    # incoming traffic (what’s allowed into the instance)
    ingress {
        description = "MySQL from web servers"
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        security_groups = [aws_security_group.worker_node_sg.id]  # Allow MySQL traffic only from instances in the web-sg security group
        # Only traffic originating from instances attached to frontend_sg will be accepted.
    }

    # outgoing traffic (what’s allowed out of the instance)
    # you don’t need to specify a particular cidr_blocks or security_groups in that egress rule 
    # because Security Groups in AWS are stateful — meaning return traffic is automatically allowed.
    # AWS automatically applies this behind the scenes: Egress: allow all, protocol=-1, 0.0.0.0/0
    #egress {
    #    description = "Allow all outbound traffic"
    #    from_port   = 0
    #    to_port     = 0
    #    protocol    = "-1"
    #    cidr_blocks = ["0.0.0.0/0"]
    #}

    tags = {
        Name = "RDS-SG"
    }
}




# RSA key of size 4096 bits
resource "tls_private_key" "private_key_rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096

  
}

# -------------------------------
# 2️⃣ Save private key to a file
# No “unknown value” timing issues
# -------------------------------
resource "local_file" "private_key" {
  content  = tls_private_key.private_key_rsa.private_key_pem
  filename = "./privatekey.pem"
  file_permission = "0400"
}

# -------------------------------
# 3️⃣ Save public key to a file
# -------------------------------
resource "local_file" "public_key" {
  content  = tls_private_key.private_key_rsa.public_key_pem
  filename = "./publickey.pem"
  file_permission = "0400"
}



# -------------------------------
# Creates an AWS key pair so you can SSH into EC2 instances.
# Registers the public key in AWS as a key pair
# the public key in OpenSSH format (used by AWS)
# -------------------------------
resource "aws_key_pair" "ansible_key" {
  key_name   = var.key_name
  public_key = tls_private_key.private_key_rsa.public_key_openssh


  tags = {
        Name = "ansible-key"
    }

}


# -------------------------------
# Use Elastic IP for Public Access for EC2 Instance
# -------------------------------
#resource "aws_eip" "ec2_eip" {
#  domain = "vpc"
#}

# Allocate one Elastic IP per worker node
#resource "aws_eip" "worker_eip" {
#  count  = var.worker_count
#  domain = "vpc"

#  tags = {
#    Name = "worker-eip-${count.index + 1}"
#  }
#}


#resource "local_file" "save_elastic_ip_of_master_node" {
#  content  = aws_eip.ec2_eip.public_ip
#  filename = "./master_node_elastic_ip.txt"
#  file_permission = "0755"
#}


# Save all worker Elastic IPs to a local text file
#resource "local_file" "save_elastic_ip_of_worker_nodes" {
  # Join all worker public IPs into a multi-line string
#  content = join("\n", [
#    for eip in aws_eip.worker_eip : "worker-${eip.tags.Name} ${eip.public_ip}"
#  ])

#  filename        = "./worker_nodes_elastic_ip.txt"
#  file_permission = "0755"
#}
# -------------------------------
# Create an EC2 Master Instance inside the Public Subnet
# vpc_security_group_ids use when You’ve created your own VPC with Terraform
# security_groups use when You’re using the default VPC provided by AWS
# -------------------------------

resource "aws_instance" "master" {
  
  ami           = var.ami_id # Amazon Linux 2 AMI (HVM), SSD Volume Type - us-east-1
  instance_type = var.instance_type
  subnet_id     = aws_subnet.terraform_public_subnet.id
  key_name      = aws_key_pair.ansible_key.key_name    # Make sure this key pair exists in your AWS account in the specified region
  vpc_security_group_ids = [
    aws_security_group.master_node_sg.id, 
    aws_security_group.common_sg.id, 
    aws_security_group.kubeadm_demo_sg_flannel.id,
    aws_security_group.kube_state_metrics_sg.id]  # Attach the security group created above
    
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"   # General-purpose SSD (recommended)
    volume_size = 20     # Size in GB
    delete_on_termination = true
  }


  tags = {
    Name = "master"
  }


    # ✅ Connection for provisioners
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user" # or "ubuntu" for Ubuntu AMIs
    private_key = tls_private_key.private_key_rsa.private_key_pem
    timeout     = "2m"
  }
    # Allow Terraform to SSH and run setup commands
  provisioner "remote-exec" {
    inline = [
        "sudo yum update -y",
        "sudo yum install -y python3 python3-pip",
        "echo 'Ansible & Python installed'",
        # Create ansible user (ignore if already exists)
        #"sudo useradd ansible || true",

        # Set password (unique per worker)
        #"echo 'ansible:master' | sudo chpasswd",

        # Append the sudo rule to the existing /etc/sudoers.d file
        #"echo 'ansible ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers.d > /dev/null"
    ]

  }

  provisioner "local-exec" {
    command = "echo 'master ${self.public_ip}' >> ./hosts.txt"
  } 

  #lifecycle {
  #  prevent_destroy = true
  #}
}

# -------------------------------
# Create an EC2 Worker Instance inside the Public Subnet
# -------------------------------


resource "aws_instance" "worker" {
  count         = var.worker_count
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.terraform_public_subnet.id
  key_name      = aws_key_pair.ansible_key.key_name    # Make sure this key pair exists in your AWS account in the specified region
  vpc_security_group_ids = [
  aws_security_group.worker_node_sg.id, 
  aws_security_group.common_sg.id, 
  aws_security_group.kubeadm_demo_sg_flannel.id,
  aws_security_group.node_exporter_sg.id]  # Attach the security group created above

  associate_public_ip_address = true
  tags = {
    Name = "k8s_worker_${count.index + 1}"
  }


  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user" # or "ubuntu" for Ubuntu AMIs
    private_key = tls_private_key.private_key_rsa.private_key_pem
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
        "sudo yum update -y",
        "sudo yum install -y python3 python3-pip",

        # Create ansible user (ignore if already exists)
        #"sudo useradd ansible || true",

        # Set password (unique per worker)
        #"echo 'ansible:worker${count.index + 1}' | sudo chpasswd",

        # Append the sudo rule to the existing /etc/sudoers.d file
        #"echo 'ansible ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers.d > /dev/null"
    ]

  }

  provisioner "local-exec" {
    command = "echo 'worker-${count.index + 1} ${self.public_ip}' >> ./hosts.txt"
  } 

  #lifecycle {
  #  prevent_destroy = true
  #}
}


# -------------------------------
# Associate the Elastic IP with the EC2 Instance
# -------------------------------
#resource "aws_eip_association" "web_eip_assoc" {
#  instance_id   = aws_instance.master.id
#  allocation_id = aws_eip.ec2_eip.id
#}

# Associate each EIP with its corresponding worker instance
#resource "aws_eip_association" "worker_eip_assoc" {
#  count         = var.worker_count
#  instance_id   = aws_instance.worker[count.index].id
#  allocation_id = aws_eip.worker_eip[count.index].id
#}



#resource "aws_db_instance" "rds_instance" {
#  identifier             = "my-rds-db"
#  engine                 = "mysql"               # or "postgres", "mariadb", etc.
#  engine_version         = "8.0"                 # MySQL version
#  instance_class         = "db.t3.micro"         # small free-tier eligible type
#  allocated_storage      = 20                   # GB
#  storage_type           = "gp3"                 # General-purpose SSD
#  username               = "admin"               # Master username
#  password               = "StrongPass123!"      # Master password
#  db_name                = "myappdb"             # Optional DB name
#  port                   = 3306

  # Connect to the right network and security
#  vpc_security_group_ids = [aws_security_group.rds_sg.id]
#  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name

  # Security + access configuration
#  publicly_accessible    = false                 # Keep private (no public IP)
#  multi_az               = true                  # Set to true for HA (if using 2 subnets)
#  skip_final_snapshot    = true                  # For testing (don’t require snapshot on destroy)
#  backup_retention_period = 7                    # Keep daily backups (1 day)
#  deletion_protection     = false                # For production, set true

#  tags = {
#    Name = "MyRDSInstance"
#    Environment = "Dev"
#  }

  #lifecycle {
  #  prevent_destroy = true
  #}

#}


