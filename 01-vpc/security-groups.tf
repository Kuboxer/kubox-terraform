# ===========================================
# RDS 보안그룹 - MySQL/Aurora(3306) 포트만 허용
# ===========================================
resource "aws_security_group" "kubox_rds_sg" {
  name        = "kubox-rds-sg"
  description = "Security group for RDS database"
  vpc_id      = aws_vpc.kubox_vpc.id

  # Bastion에서 SSH 접근 허용 (22번 포트)
  ingress {
    description     = "SSH access from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # EKS에서 MySQL 접근 허용 (3306번 포트)
  ingress {
    description = "MySQL/Aurora access from EKS cluster nodes"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # EKS 노드들이 있는 private subnet CIDR
  }

  # Bastion에서 MySQL 접근 허용 (3306번 포트)
  ingress {
    description     = "MySQL/Aurora access from Bastion"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kubox-rds-sg"
    Description = "RDS security group - MySQL access from EKS cluster and Bastion"
  }
}

# ===========================================
# ElastiCache 보안그룹 - Redis(6379) 포트만 허용
# ===========================================
resource "aws_security_group" "kubox_elasticache_sg" {
  name        = "kubox-elasticache-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = aws_vpc.kubox_vpc.id

  # EKS에서 Redis 접근 허용 (6379번 포트)
  ingress {
    description = "Redis access from EKS cluster nodes"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # EKS 노드들이 있는 private subnet CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kubox-elasticache-sg"
    Description = "ElastiCache security group - Redis access from EKS cluster"
  }
}