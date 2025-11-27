
# -------------------------------
# Create a VPC
# -------------------------------
resource "aws_vpc" "terraform_vpc" {
  cidr_block = var.vpc_cidr 
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "multi-az-vpc" }
  
}


# -------------------------------
# Create an Internet Gateway (for public subnet)
# This means the VPC is now “connected” to the Internet at the network level but not all subnets inside it are automatically exposed.
# You still need to configure their route tables.
# connects your VPC to the public Internet.
# Enables bidirectional traffic between instances with public IPs and the Internet.
# When your EC2 sends a packet: Source: 10.0.1.10 → Destination: 8.8.8.8
# It leaves the subnet → hits the IGW → the IGW replaces the source IP 10.0.1.10 with the public IP 3.90.55.100 before sending it out to the Internet.
# -------------------------------

resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.terraform_vpc.id
      tags = {
        Name = "Internet-Gateway"
    }

}

# -------------------------------
# Create a Public Subnet
# That map_public_ip_on_launch = true tells AWS to automatically assign a public IPv4 address to new EC2 instances in this subnet.IP is not Elastic (i.e., not permanent).It changes if you stop/start the instance.
#   Does not apply to: NAT Gateways, Load Balancers, RDS Databases, EIPs (Elastic IPs must be created manually)

# -------------------------------

resource "aws_subnet" "terraform_public_subnet" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone = var.az_a

      tags = {
        Name = "Public-Subnet"
        #kubernetes.io/cluster/kubernetes          = "shared"
        #kubernetes.io/role/elb                    = "1"
    }

}

# -------------------------------
# Create a Private Subnet a
# -------------------------------

resource "aws_subnet" "terraform_private_subnet_a" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = var.private_subnet_cidr_a
  availability_zone = var.az_a
  map_public_ip_on_launch = false
      tags = {
        Name = "Private-Subnet-A"
        #kubernetes.io/cluster/kubernetes          = "shared"
        #kubernetes.io/role/internal-elb           = "1"
    }


}


# -------------------------------
# Create a Private Subnet b
# -------------------------------

resource "aws_subnet" "terraform_private_subnet_b" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = var.private_subnet_cidr_b
  availability_zone = var.az_b
  map_public_ip_on_launch = false

      tags = {
        Name = "Private-Subnet-B"
    }


}


# -------------------------------
# Create a RDS Private Subnet Group
# -------------------------------
resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "rds_subnet_group"
  description = "Private subnets for RDS"
  subnet_ids  = [
    aws_subnet.terraform_private_subnet_a.id,
    aws_subnet.terraform_private_subnet_b.id
  ]
      tags = {
        Name = "RDS_Subnet_Group"
    }

}



# -------------------------------
# Create a Route table for Public Subnet
# -------------------------------


resource "local_file" "vpc_id_file" {
  content  = aws_vpc.terraform_vpc.id
  filename = "vpc_id.txt"
}


# -------------------------------
# Elastic IP for NAT Gateway
# An Elastic IP provides a static, public IPv4 address that you can attach to resources such as a NAT Gateway or EC2 instance.
# Without it, AWS might assign a random public IP that changes when the resource restarts.
# domain = "vpc" → This tells AWS that the Elastic IP is for use in a VPC (Virtual Private Cloud).
#   If this line was omitted, it would default to EC2-Classic (which is deprecated).
#   This ensures the IP can attach to modern AWS resources like a NAT Gateway or EC2 instance inside a VPC.
# -------------------------------

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  
}


# -------------------------------
# NAT Gateway (for private subnet outbound access if needed)
# allocation_id = aws_eip.nat_eip.id → Attaches the Elastic IP you created above (nat_eip) to this NAT Gateway, enabling it to route traffic between private instances and the internet.
# subnet_id = aws_subnet.public_subnet.id → Specifies which subnet the NAT Gateway will be created in.
#   NAT Gateways must be in a public subnet, because they need direct Internet Gateway access.
# -------------------------------
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.terraform_public_subnet.id
      tags = {
        Name = "NAT-Gateway"
    }

  
}


# -------------------------------
# Create a Route Table for Public Subnet
# “If a packet’s destination IP falls within this range (CIDR block), send it to this target (gateway).”
# Every subnet in your VPC must be associated with one route table — this defines whether that subnet is public (can reach Internet) or private (isolated).
# -------------------------------
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.terraform_vpc.id
  
  # Local traffic (inside VPC)
  # “All traffic whose destination is inside this VPC (10.0.0.0/16) should stay inside the VPC — don’t send it to any gateway.”
  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  # Internet traffic (goes out via IGW)
  # “If traffic is not for my VPC (not 10.0.0.0/16), send it out to the Internet through the IGW.”
  # 0.0.0.0/0 -> “All possible IPv4 addresses — from 0.0.0.0 to 255.255.255.255.”
  # “If the destination IP doesn’t match any more specific route, send it here.”
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_igw.id
    
  }
  tags = { Name = "Public_Route_Table"}

}







# -------------------------------
# Create a Route Table for Private Subnet
# -------------------------------
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.terraform_vpc.id
  
  # Local traffic (inside VPC)
  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "Private_Route_Table" }

}
# -------------------------------
# Associate Public Subnet with Route Table
# -------------------------------
resource "aws_route_table_association" "public_associate" {
  subnet_id      = aws_subnet.terraform_public_subnet.id
  route_table_id = aws_route_table.public_route_table.id

}


# -------------------------------
# Associate Private Subnet with Route Table
# -------------------------------
resource "aws_route_table_association" "private_associate_a" {
  subnet_id      = aws_subnet.terraform_private_subnet_a.id
  route_table_id = aws_route_table.private_route_table.id

}

resource "aws_route_table_association" "private_associate_b" {
  subnet_id      = aws_subnet.terraform_private_subnet_b.id
  route_table_id = aws_route_table.private_route_table.id

}

