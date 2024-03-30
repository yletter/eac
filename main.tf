# Define provider
provider "aws" {
  region = "us-east-1"
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
resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

# Create Route Table
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

# Associate Subnet with Route Table
resource "aws_route_table_association" "subnet_assoc" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
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
  ami                    = "ami-0c101f26f147fa7fd"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.my_subnet.id
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
resource "aws_iam_policy" "s3_full_access_policy" {
  name        = "s3-full-access-policy"
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
resource "aws_iam_role" "ec2_s3_role" {
  name               = "ec2-s3-role"
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
  role = aws_iam_role.ec2_s3_role.name
}
resource "aws_iam_role_policy_attachment" "ec2_s3_role_policy_attachment" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = aws_iam_policy.s3_full_access_policy.arn
}
