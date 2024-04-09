# Define provider
provider "aws" {
  region = "us-east-1"
}

variable "create_resource" {
  type = bool
  default = true
}

# Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Create Subnet
resource "aws_subnet" "public_subnet0" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public-subnet0-us-east-1a"
  }
}

resource "aws_subnet" "public_1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-us-east-1a"
  }
}
resource "aws_subnet" "public_2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-us-east-1b"
  }
}
resource "aws_subnet" "public_3" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-us-east-1c"
  }
}

# Create Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

# Associate Subnet with Route Table
resource "aws_route_table_association" "subnet_assoc" {
  subnet_id      = aws_subnet.public_subnet0.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_1" {
    subnet_id = aws_subnet.public_1.id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_2" {
    subnet_id = aws_subnet.public_2.id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_3" {
    subnet_id = aws_subnet.public_3.id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_subnet" "private_1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet-us-east-1a"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.5.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-subnet-us-east-1b"
  }
}

resource "aws_subnet" "private_3" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.6.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "private-subnet-us-east-1c"
  }
}

resource "aws_eip" "nat_gw_eip_1" {
  domain = "vpc"
}

resource "aws_eip" "nat_gw_eip_2" {
  domain = "vpc"
}

resource "aws_eip" "nat_gw_eip_3" {
  domain = "vpc"
}

resource "aws_nat_gateway" "gw_1" {
  allocation_id = aws_eip.nat_gw_eip_1.id
  subnet_id     = aws_subnet.public_1.id
}

resource "aws_nat_gateway" "gw_2" {
  allocation_id = aws_eip.nat_gw_eip_2.id
  subnet_id     = aws_subnet.public_2.id
}

resource "aws_nat_gateway" "gw_3" {
  allocation_id = aws_eip.nat_gw_eip_3.id
  subnet_id     = aws_subnet.public_3.id
}

resource "aws_route_table" "private_1" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.gw_1.id
    }

    tags = {
        Name = "private-route-table-1"
    }
}

resource "aws_route_table" "private_2" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.gw_2.id
    }

    tags = {
        Name = "private-route-table-2"
    }
}

resource "aws_route_table" "private_3" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.gw_3.id
    }

    tags = {
        Name = "private-route-table-3"
    }
}

resource "aws_route_table_association" "private_1" {
    subnet_id = aws_subnet.private_1.id
    route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private_2" {
    subnet_id = aws_subnet.private_2.id
    route_table_id = aws_route_table.private_2.id
}

resource "aws_route_table_association" "private_3" {
    subnet_id = aws_subnet.private_3.id
    route_table_id = aws_route_table.private_3.id
}

resource "random_password" "password" {
  length  = 32
  special = true
}

resource "aws_ssm_parameter" "opensearch_master_user" {
  name        = "/service/MASTER_USER"
  description = "opensearch_password for my service domain"
  type        = "SecureString"
  value       = "master,${random_password.password.result}"
}

resource "aws_security_group" "es" {
  name = "es-sg"
  description = "Allow inbound traffic to ElasticSearch from VPC CIDR"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = [
          aws_vpc.my_vpc.cidr_block
      ]
  }
}

resource "aws_iam_service_linked_role" "es_service_linked_role" {
  aws_service_name = "es.amazonaws.com"
}

data "aws_caller_identity" "current" {}

resource "aws_opensearch_domain" "es" {
  count = var.create_resource ? 1 : 0
  domain_name = "yuvaraj-es-domain"
  engine_version = "OpenSearch_1.0"

  cluster_config {
    instance_type = "r6g.large.search"
    zone_awareness_enabled = false
  }
  
  ebs_options {
      ebs_enabled = true
      volume_size = 10
  }

  advanced_security_options {
    enabled = true
    master_user_options {
      master_user_name     = "master"
      master_user_password = "masteryuvaraj"
    }
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }
  
  access_policies = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": "es:*",
          "Principal": "*",
          "Effect": "Allow",
          "Resource": "arn:aws:es:us-east-1:${data.aws_caller_identity.current.account_id}:domain/yuvaraj-es-domain/*"
      }
  ]
}
  CONFIG

  snapshot_options {
      automated_snapshot_start_hour = 23
  }

  tags = {
      Domain = "yuvaraj-es-domain"
  }
}

# Create Security Group
resource "aws_security_group" "my_security_group" {

  name = "my_security_group"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create EC2 instance
resource "aws_instance" "my_ec2_instance" {
  count = var.create_resource ? 1 : 0
  ami                    = "ami-0c101f26f147fa7fd"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet0.id
  security_groups        = [aws_security_group.my_security_group.id]
  key_name               = "eac"
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.ec2_s3_profile.name

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World!" > /tmp/hello.txt
              # Add more initialization commands here
              aws s3 cp s3://yletter-artifacts/config-server.jar /tmp/
              aws s3 cp s3://yletter-artifacts/config-client.jar /tmp/
              sudo yum install java-17-amazon-corretto-headless -y
              java -jar /tmp/config-server.jar > /tmp/config.server.out.txt &
              java -jar /tmp/config-client.jar > /tmp/config.client.out.txt &
              EOF

  tags = {
    Name = "MyEC2Instance"
  }
}

# Define IAM policy granting full access to S3
resource "aws_iam_policy" "s3_cc_full_access_policy" {
  name        = "s3-cc-full-access-policy"
  description = "Policy granting full access to S3"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect"    : "Allow",
        "Action"    : "s3:*",
        "Resource"  : "*"
      },
      {
        "Effect"    : "Allow",
        "Action"    : "codeCommit:*",
        "Resource"  : "*"
      }
    ]
  })
}

# Create IAM role and attach the S3 full access policy
resource "aws_iam_role" "ec2_s3_cc_role" {
  name               = "ec2-s3-cc-role"
  assume_role_policy = jsonencode({
    "Version"               : "2012-10-17",
    "Statement" : [
      {
        "Effect"    : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action"    : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "ec2_s3_profile"
  role = aws_iam_role.ec2_s3_cc_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_s3_cc_role_policy_attachment" {
  role       = aws_iam_role.ec2_s3_cc_role.name
  policy_arn = aws_iam_policy.s3_cc_full_access_policy.arn
}
