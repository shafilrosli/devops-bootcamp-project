############################################
# Ubuntu 24.04 AMI via SSM (Region-safe)
############################################

############################################
# Web Server EC2 (Public Subnet)
############################################
resource "aws_instance" "web_server" {
  ami                    = "ami-001c7178515f44952"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnet.id
  private_ip             = "10.0.0.5"
  vpc_security_group_ids = [aws_security_group.devops_public_sg.id]
  key_name               = "test"

 iam_instance_profile = aws_iam_instance_profile.ec2_ssm_profile.name

 user_data = <<-EOF
    #!/bin/bash
    set -e

    # Run Node Exporter
    docker run -d \
      --name node-exporter \
      -p 9100:9100 \
      --restart unless-stopped \
      prom/node-exporter
  EOF

  # Do not auto-assign public IP (Elastic IP used instead)
  associate_public_ip_address = false

  tags = {
    Name = "devops-web-server"
    Role = "Web"
  }
}

############################################
# Elastic IP (Allocate & Associate)
############################################
resource "aws_eip" "web_eip" {
  domain   = "vpc"
  instance = aws_instance.web_server.id

  tags = {
    Name = "devops-web-eip"
  }
}

