# ===========================================
# 현재 운영중인 EKS 보안그룹 참조
# ===========================================
data "aws_security_group" "existing_eks_cluster_sg" {
  filter {
    name   = "group-name"
    values = ["eks-cluster-sg-kubox-cluster-*"]
  }
  
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.kubox_vpc.id]
  }
  
  depends_on = [aws_eks_cluster.kubox_cluster]
}

# ===========================================
# RDS 보안그룹 - MySQL/Aurora(3306) 포트만 허용
# ===========================================
resource "aws_security_group" "kubox_rds_sg" {
  name        = "kubox-rds-sg"
  description = "Security group for RDS database"
  vpc_id      = data.aws_vpc.kubox_vpc.id

  ingress {
    description     = "MySQL/Aurora access from EKS cluster nodes"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [data.aws_security_group.existing_eks_cluster_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kubox-rds-sg"
    Description = "RDS security group - MySQL access only from EKS cluster"
  }
}

# ===========================================
# ElastiCache 보안그룹 - Redis(6379) 포트만 허용
# ===========================================
resource "aws_security_group" "kubox_elasticache_sg" {
  name        = "kubox-elasticache-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = data.aws_vpc.kubox_vpc.id

  ingress {
    description     = "Redis access from EKS cluster nodes"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [data.aws_security_group.existing_eks_cluster_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kubox-elasticache-sg"
    Description = "ElastiCache security group - Redis access only from EKS cluster"
  }
}