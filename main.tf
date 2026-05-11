provider "aws" {
  region = "us-east-1"
}

#################################################
# PUBLIC S3 BUCKET
#################################################

resource "aws_s3_bucket" "public_bucket" {
  bucket = "my-insecure-demo-bucket-12345"
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.public_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

#################################################
# SECURITY GROUP OPEN TO WORLD
#################################################

resource "aws_security_group" "open_sg" {
  name = "open-security-group"

  ingress {
    description = "SSH open to world"

    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP open to world"

    from_port   = 80
    to_port     = 80
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }
}

#################################################
# PUBLIC EC2
#################################################

resource "aws_instance" "public_vm" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.open_sg.id
  ]
}

#################################################
# HARDCODED SECRET
#################################################

variable "db_password" {
  default = "Password123!"
}

#################################################
# WEAK IAM POLICY
#################################################

resource "aws_iam_policy" "admin_policy" {
  name = "admin-policy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "*"
        ]

        Resource = "*"
      }
    ]
  })
}