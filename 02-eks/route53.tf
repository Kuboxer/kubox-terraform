# ===========================================
# 기존 Route53 프라이빗 호스팅 존 참조
# ===========================================
data "aws_route53_zone" "kubox_private" {
  name         = "kubox.local"
  private_zone = true
}

# # ===========================================
# # 기존 호스팅 존에 새로운 VPC 연결
# # ===========================================
# resource "aws_route53_zone_association" "kubox_private_vpc" {
#   zone_id = data.aws_route53_zone.kubox_private.zone_id
#   vpc_id  = data.aws_vpc.kubox_vpc.id
# }

# ===========================================
# Redis CNAME 레코드
# ===========================================
resource "aws_route53_record" "redis" {
  zone_id = data.aws_route53_zone.kubox_private.zone_id
  name    = "redis.kubox.local"
  type    = "CNAME"
  ttl     = 300
  records = [aws_elasticache_replication_group.kubox_redis.primary_endpoint_address]
  
  depends_on = [
    aws_elasticache_replication_group.kubox_redis,
  ]
}

# ===========================================
# 향후 RDS용 레코드 (현재는 주석 처리)
# ===========================================
# resource "aws_route53_record" "mysql" {
#   zone_id = data.aws_route53_zone.kubox_private.zone_id
#   name    = "mysql.kubox.local"
#   type    = "CNAME"
#   ttl     = 300
#   records = [aws_db_instance.kubox_mysql.endpoint]  # RDS 생성 후 활성화
# }
