#############################################
# INSECURE TERRAFORM CONFIGURATION
# PURPOSE: SECURITY SCANNING POC ONLY
#############################################

provider "aws" {
  region = "us-east-1"

  # HARDCODED AWS CREDENTIALS (BAD PRACTICE)
  access_key = "AKIAEXAMPLEACCESSKEY"
  secret_key = "VerySecretAccessKey123456"
}

#############################################
# PUBLIC S3 BUCKET
#############################################

resource "aws_s3_bucket" "public_bucket" {
  bucket = "my-insecure-public-bucket-demo"

  tags = {
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.public_bucket.id

  # ALL PUBLIC ACCESS ENABLED
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

#############################################
# S3 BUCKET WITHOUT ENCRYPTION
#############################################

resource "aws_s3_bucket_server_side_encryption_configuration" "disabled_encryption" {
  bucket = aws_s3_bucket.public_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#############################################
# OPEN SECURITY GROUP
#############################################

resource "aws_security_group" "open_security_group" {
  name        = "open-security-group"
  description = "Allows unrestricted access"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    # OPEN TO INTERNET
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"

    # OPEN TO INTERNET
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    # ALL OUTBOUND TRAFFIC
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#############################################
# EC2 INSTANCE WITH PUBLIC IP
#############################################

resource "aws_instance" "public_ec2" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  # PUBLIC IP ENABLED
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.open_security_group.id
  ]

  tags = {
    Name = "InsecurePublicInstance"
  }
}

#############################################
# RDS WITHOUT ENCRYPTION
#############################################

resource "aws_db_instance" "insecure_db" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"

  db_name  = "mydb"
  username = "admin"

  # HARDCODED PASSWORD
  password = "Password123!"

  publicly_accessible = true

  # ENCRYPTION DISABLED
  storage_encrypted = false

  skip_final_snapshot = true
}

#############################################
# OVERLY PERMISSIVE IAM POLICY
#############################################

resource "aws_iam_policy" "admin_policy" {
  name = "AdminAccessPolicy"

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

#############################################
# SENSITIVE VARIABLE WITH DEFAULT VALUE
#############################################

variable "db_password" {
  description = "Database password"

  # HARDCODED SECRET
  default = "SuperSecretPassword!"
}

#############################################
# OUTPUT SENSITIVE DATA
#############################################

output "database_password" {
  value = aws_db_instance.insecure_db.password

  # SENSITIVE DATA EXPOSED
  sensitive = false
}