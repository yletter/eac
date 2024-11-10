resource "aws_instance" "master-node" {
  ami           = "ami-005fc0f236362e99f" # Replace with your desired AMI ID
  instance_type = "t2.micro"

  tags = {
    Name = "master"
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

