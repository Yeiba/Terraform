resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-west-2.s3" # Use the service name for S3
  vpc_endpoint_type = "Gateway" # Gateway type for S3

  route_table_ids = [aws_route_table.private.id]

  tags = {
    Name = "s3-endpoint"
  }
}