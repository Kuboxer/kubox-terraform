# ===========================================
# ElastiCache 서브넷 그룹
# ===========================================
resource "aws_elasticache_subnet_group" "kubox_elasticache_subnet_group" {
  name       = "kubox-elasticache-subnet-group"
  subnet_ids = data.aws_subnets.elasticache_subnets.ids

  tags = {
    Name = "kubox-elasticache-subnet-group"
  }
}

# ===========================================
# ElastiCache Redis 클러스터
# ===========================================
resource "aws_elasticache_replication_group" "kubox_redis" {
  description          = "Redis cluster for Kubox application"
  replication_group_id = "kubox-redis-cache"
  
  # Redis 설정
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = "cache.t3.micro"
  port                 = 6379
  parameter_group_name = "default.redis7"
  
  # 클러스터 구성
  num_cache_clusters = 2
  automatic_failover_enabled    = true  # 자동 장애조치 활성화
  
  # 네트워크 설정
  subnet_group_name  = aws_elasticache_subnet_group.kubox_elasticache_subnet_group.name
  security_group_ids = [aws_security_group.kubox_elasticache_sg.id]
  
  # 보안 설정
  at_rest_encryption_enabled = true
  transit_encryption_enabled = false
  apply_immediately          = true

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "kubox-redis"
  }

  depends_on = [
    aws_security_group.kubox_elasticache_sg,
    aws_elasticache_subnet_group.kubox_elasticache_subnet_group
  ]
}

# ===========================================
# ElastiCache 서브넷 데이터 소스
# ===========================================
data "aws_subnets" "elasticache_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.kubox_vpc.id]
  }
  
  filter {
    name   = "tag:Name"
    values = ["*elasticache*"]
  }
}
