resource "aws_instance" "master-node" {
  ami           = "ami-005fc0f236362e99f" # Replace with your desired AMI ID
  instance_type = "t2.micro"
  tags = {
    Name = "master"
  }
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name
  key_name = "keypairNov2024" # Replace with your key pair name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  user_data = <<EOF123
#!/bin/bash
echo Hello World Yuvaraj 
echo Hello World Yuvaraj > /tmp/test.txt
pwd >> /tmp/test.txt

swapoff -a
sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab

lsmod | grep br_netfilter 
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sudo sysctl --system

sudo apt-get update  
sudo apt-get install -y  apt-transport-https ca-certificates curl software-properties-common gnupg2

sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

EOF123

}

resource "aws_instance" "worker1" {
  ami           = "ami-005fc0f236362e99f" # Replace with your desired AMI ID
  instance_type = "t2.micro"
  tags = {
    Name = "worker1"
  }
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name
  key_name = "keypairNov2024" # Replace with your key pair name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
}

resource "aws_instance" "worker2" {
  ami           = "ami-005fc0f236362e99f" # Replace with your desired AMI ID
  instance_type = "t2.micro"
  tags = {
    Name = "worker2"
  }
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name
  key_name = "keypairNov2024" # Replace with your key pair name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress  {
    from_port    =  2222
    to_port      =  2222
    protocol    =  "tcp"
    cidr_blocks  =  ["0.0.0.0/0"]
  }
  
  ingress  {
    from_port    =  5986
    to_port      =  5986
    protocol    =  "tcp"
    cidr_blocks  =  ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2-ssm-role"

  assume_role_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
  {
    Action = "sts:AssumeRole"
    Effect = "Allow"
    Principal = {
      Service = "ec2.amazonaws.com"
    }
  },
  ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  role = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm_instance_profile" {
  name = "ec2-ssm-instance-profile"
  role = aws_iam_role.ec2_ssm_role.name
}