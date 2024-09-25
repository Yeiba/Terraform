resource "aws_subnet" "private_zone1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_private_ip_range_zone1
  availability_zone = var.zone1

  tags = {
    "Name"                                                 = "${var.env}-private-${var.zone1}"
    "kubernetes.io/role/internal-elb"                      = "1"
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned"
  }
}

resource "aws_subnet" "private_zone2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_private_ip_range_zone2
  availability_zone = var.zone2

  tags = {
    "Name"                                                 = "${var.env}-private-${var.zone2}"
    "kubernetes.io/role/internal-elb"                      = "1"
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned"
  }
}

resource "aws_subnet" "public_zone1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_public_ip_range_zone1
  availability_zone       = var.zone1
  map_public_ip_on_launch = true

  tags = {
    "Name"                                                 = "${var.env}-public-${var.zone1}"
    "kubernetes.io/role/elb"                               = "1"
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned"
  }
}

resource "aws_subnet" "public_zone2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_public_ip_range_zone2
  availability_zone       = var.zone2
  map_public_ip_on_launch = true

  tags = {
    "Name"                                                 = "${var.env}-public-${var.zone2}"
    "kubernetes.io/role/elb"                               = "1"
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned"
  }
}