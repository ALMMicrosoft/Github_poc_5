provider "aws" {
  region = "us-east-1"
}

# PUBLIC S3 BUCKET
resource "aws_s3_bucket" "public_bucket" {
  bucket = "my-insecure-poc-bucket"

  tags = {
    Name = "InsecureBucket"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.public_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# SECURITY GROUP OPEN TO WORLD
resource "aws_security_group" "open_sg" {
  name = "open-security-group"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# HARDCODED SECRET
variable "db_password" {
  default = "Password123!"
}