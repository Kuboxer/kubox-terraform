# Bastion 인스턴스용 보안그룹
resource "aws_security_group" "bastion_sg" {
  name        = "kubox-bastion-sg"
  description = "Security group for bastion instance"
  vpc_id      = aws_vpc.kubox_vpc.id

  # SSH 접속 (모든 IP - 개발용)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # 모든 아웃바운드 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name    = "kubox-bastion-sg"
    Project = var.project_name
    Type    = "Bastion"
  }
}

# Bastion 인스턴스
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  key_name      = "kubox"  # SSH 키페어 추가
  
  # 스팟 인스턴스 설정
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = "0.0104"  # t3.micro 온디맨드 가격
    }
  }
  
  # Public Subnet C에 배치
  subnet_id                   = aws_subnet.public_subnet_c.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true

  # 기본 설정
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker git
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ec2-user
              
              # kubectl 설치
              curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.31.0/2024-09-12/bin/linux/amd64/kubectl
              chmod +x ./kubectl
              sudo mv ./kubectl /usr/local/bin
              
              # AWS CLI v2 설치 (기본 설치되어 있음)
              
              echo "Bastion setup completed" > /home/ec2-user/setup.log
              EOF

  tags = {
    Name        = "kubox-bastion"
    Project     = var.project_name
    Environment = var.environment
    Purpose     = "Development and testing bastion host"
  }
}
