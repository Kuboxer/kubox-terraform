# VPC 정보
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.kubox_vpc.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = aws_vpc.kubox_vpc.cidr_block
}

# 서브넷 정보
output "public_subnet_ids" {
  description = "IDs of public subnets"
  value = {
    public_subnet_a = aws_subnet.public_subnet_a.id
    public_subnet_c = aws_subnet.public_subnet_c.id
  }
}

output "private_subnet_ids" {
  description = "IDs of private subnets for EKS"
  value = {
    private_subnet_a = aws_subnet.private_subnet_a.id
    private_subnet_c = aws_subnet.private_subnet_c.id
  }
}

output "rds_subnet_ids" {
  description = "IDs of RDS subnets"
  value = {
    rds_subnet_a = aws_subnet.rds_subnet_a.id
    rds_subnet_c = aws_subnet.rds_subnet_c.id
  }
}

output "elasticache_subnet_ids" {
  description = "IDs of ElastiCache subnets"
  value = {
    elasticache_subnet_a = aws_subnet.elasticache_subnet_a.id
    elasticache_subnet_c = aws_subnet.elasticache_subnet_c.id
  }
}

# 네트워킹 구성 요소
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.kubox_igw.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.kubox_nat.id
}

output "nat_eip_public_ip" {
  description = "Public IP of NAT Gateway"
  value       = aws_eip.nat_eip.public_ip
}

# 라우팅 테이블 정보
output "route_table_ids" {
  description = "IDs of all route tables"
  value = {
    public_rt      = aws_route_table.kubox_public_rt.id
    private_rt     = aws_route_table.kubox_private_rt.id
    rds_rt         = aws_route_table.kubox_rds_rt.id
    elasticache_rt = aws_route_table.kubox_elasticache_rt.id
  }
}

# 서브넷 그룹별 목록 (RDS, ElastiCache에서 사용)
output "rds_subnet_group" {
  description = "List of subnet IDs for RDS subnet group"
  value = [
    aws_subnet.rds_subnet_a.id,
    aws_subnet.rds_subnet_c.id
  ]
}

output "elasticache_subnet_group" {
  description = "List of subnet IDs for ElastiCache subnet group"
  value = [
    aws_subnet.elasticache_subnet_a.id,
    aws_subnet.elasticache_subnet_c.id
  ]
}

output "eks_subnet_group" {
  description = "List of subnet IDs for EKS"
  value = [
    aws_subnet.private_subnet_a.id,
    aws_subnet.private_subnet_c.id
  ]
}

# 배포 정보 요약
output "deployment_summary" {
  description = "Deployment information summary"
  value = {
    vpc_name         = "kubox-vpc"
    vpc_cidr         = "10.0.0.0/16"
    availability_zones = ["us-east-2a", "us-east-2c"]
    subnet_count = {
      public      = 2
      private     = 2  # EKS용
      rds         = 2
      elasticache = 2
    }
    nat_gateway_subnet = "public-subnet-a"
    created_at         = timestamp()
  }
}

# Bastion 정보
output "bastion_public_ip" {
  description = "Public IP of bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion host"
  value       = "ssh -i your-key.pem ec2-user@${aws_instance.bastion.public_ip}"
}
