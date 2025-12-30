################################
# Web Server Security Group
# (Public)
################################
resource "aws_security_group" "devops_public_sg" {
  name        = "devops-public-sg"
  description = "Security group for public web server"
  vpc_id      = aws_vpc.devops_vpc.id

  # HTTP - Allow from anywhere
  ingress {
    description = "Allow HTTP from any IP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH - Allow from VPC subnet only
  ingress {
    description = "Allow SSH from VPC subnet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-public-sg"
  }
}

################################
# Ansible Controller & Monitoring
# (Private)
################################
resource "aws_security_group" "devops_private_sg" {
  name        = "devops-private-sg"
  description = "Security group for Ansible Controller & Monitoring Server"
  vpc_id      = aws_vpc.devops_vpc.id

  # SSH - Allow from VPC subnet only
  ingress {
    description = "Allow SSH from VPC subnet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-private-sg"
  }
}
