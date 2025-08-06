# ===========================================
# VPC 생성
# ===========================================
resource "aws_vpc" "kubox_vpc" {
  cidr_block           = "10.0.0.0/16"    # IP 대역: 10.0.0.1 ~ 10.0.255.254
  enable_dns_hostnames = true             # DNS 이름 사용 가능하게
  enable_dns_support   = true             # DNS 해석 가능하게
  
  tags = {
    Name = "kubox-vpc"  # AWS 콘솔에서 보이는 이름
  }
}

# ===========================================
# 서브넷 생성
# ===========================================
# Public Subnet A (us-east-2a) - NAT Gateway용
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.kubox_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "public-subnet-a"
    Description = "NAT Gateway subnet"
  }
}

# Public Subnet C (us-east-2c)
resource "aws_subnet" "public_subnet_c" {
  vpc_id                  = aws_vpc.kubox_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-2c"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "public-subnet-c"
  }
}

# Private Subnet A (us-east-2a) - EKS용
resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.kubox_vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-2a"
  
  tags = {
    Name = "private-subnet-a"
    Description = "EKS worker nodes subnet"
  }
}

# Private Subnet C (us-east-2c) - EKS용
resource "aws_subnet" "private_subnet_c" {
  vpc_id            = aws_vpc.kubox_vpc.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "us-east-2c"
  
  tags = {
    Name = "private-subnet-c"
    Description = "EKS worker nodes subnet"
  }
}

# RDS Subnet A (us-east-2a) - RDS Primary
resource "aws_subnet" "rds_subnet_a" {
  vpc_id            = aws_vpc.kubox_vpc.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "us-east-2a"
  
  tags = {
    Name = "rds-subnet-a"
    Description = "RDS primary database subnet"
  }
}

# RDS Subnet C (us-east-2c) - RDS Secondary
resource "aws_subnet" "rds_subnet_c" {
  vpc_id            = aws_vpc.kubox_vpc.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = "us-east-2c"
  
  tags = {
    Name = "rds-subnet-c"
    Description = "RDS secondary database subnet"
  }
}

# ElastiCache Subnet A (us-east-2a)
resource "aws_subnet" "elasticache_subnet_a" {
  vpc_id            = aws_vpc.kubox_vpc.id
  cidr_block        = "10.0.31.0/24"
  availability_zone = "us-east-2a"
  
  tags = {
    Name = "elasticache-subnet-a"
    Description = "ElastiCache Redis subnet"
  }
}

# ElastiCache Subnet C (us-east-2c)
resource "aws_subnet" "elasticache_subnet_c" {
  vpc_id            = aws_vpc.kubox_vpc.id
  cidr_block        = "10.0.32.0/24"
  availability_zone = "us-east-2c"
  
  tags = {
    Name = "elasticache-subnet-c"
    Description = "ElastiCache Redis subnet"
  }
}

# ===========================================
# Internet Gateway 생성
# ===========================================
resource "aws_internet_gateway" "kubox_igw" {
  vpc_id = aws_vpc.kubox_vpc.id
  
  tags = {
    Name = "kubox-igw"
  }
}

# ===========================================
# 탄력적 IP 및 NAT Gateway 생성
# ===========================================
# 탄력적 IP (Amazon의 IPv4 주소 풀)
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  
  tags = {
    Name = "nat-eip"
  }
}

# NAT Gateway (public-subnet-a에 배치)
resource "aws_nat_gateway" "kubox_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_a.id
  
  # Internet Gateway가 먼저 생성되어야 함
  depends_on = [aws_internet_gateway.kubox_igw]
  
  tags = {
    Name = "kubox-nat"
  }
}

# ===========================================
# 라우팅 테이블(RT) 생성 및 연결
# ===========================================

# 퍼블릭 Route Table
resource "aws_route_table" "kubox_public_rt" {
  vpc_id = aws_vpc.kubox_vpc.id
  
  # 모든 외부 트래픽을 Internet Gateway로 라우팅
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kubox_igw.id
  }
  
  tags = {
    Name = "kubox-public-rt"
  }
}

# 프라이빗 Route Table
resource "aws_route_table" "kubox_private_rt" {
  vpc_id = aws_vpc.kubox_vpc.id
  
  # 모든 외부 트래픽을 NAT Gateway로 라우팅
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.kubox_nat.id
  }
  
  tags = {
    Name = "kubox-private-rt"
  }
}

# RDS Route Table (내부 통신용 - 외부 라우팅 없음)
resource "aws_route_table" "kubox_rds_rt" {
  vpc_id = aws_vpc.kubox_vpc.id
  
  tags = {
    Name = "kubox-rds-rt"
    Description = "Internal communication only"
  }
}

# ElastiCache Route Table (내부 통신용 - 외부 라우팅 없음)
resource "aws_route_table" "kubox_elasticache_rt" {
  vpc_id = aws_vpc.kubox_vpc.id
  
  tags = {
    Name = "kubox-elasticache-rt"
    Description = "Internal communication only"
  }
}

# ===========================================
# 서브넷과 라우팅 테이블 연결
# ===========================================

# Public 서브넷들을 Public Route Table에 연결
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.kubox_public_rt.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_subnet_c.id
  route_table_id = aws_route_table.kubox_public_rt.id
}

# Private 서브넷들을 Private Route Table에 연결
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.kubox_private_rt.id
}

resource "aws_route_table_association" "private_c" {
  subnet_id      = aws_subnet.private_subnet_c.id
  route_table_id = aws_route_table.kubox_private_rt.id
}

# RDS 서브넷들을 RDS Route Table에 연결
resource "aws_route_table_association" "rds_a" {
  subnet_id      = aws_subnet.rds_subnet_a.id
  route_table_id = aws_route_table.kubox_rds_rt.id
}

resource "aws_route_table_association" "rds_c" {
  subnet_id      = aws_subnet.rds_subnet_c.id
  route_table_id = aws_route_table.kubox_rds_rt.id
}

# ElastiCache 서브넷들을 ElastiCache Route Table에 연결
resource "aws_route_table_association" "elasticache_a" {
  subnet_id      = aws_subnet.elasticache_subnet_a.id
  route_table_id = aws_route_table.kubox_elasticache_rt.id
}

resource "aws_route_table_association" "elasticache_c" {
  subnet_id      = aws_subnet.elasticache_subnet_c.id
  route_table_id = aws_route_table.kubox_elasticache_rt.id
}
