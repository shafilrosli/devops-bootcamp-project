############################################
# Ubuntu 24.04 AMI via SSM (Region-safe)
############################################
############################################
# Monitoring Server EC2 (Private Only)
############################################
resource "aws_instance" "monitoring_server" {
  ami                    = "ami-001c7178515f44952"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_subnet.id
  private_ip             = "10.0.0.7"
  vpc_security_group_ids = [aws_security_group.devops_private_sg.id]
  key_name               = "test"

iam_instance_profile = aws_iam_instance_profile.ec2_ssm_profile.name
  # Explicitly prevent public IP
  associate_public_ip_address = false

  tags = {
    Name = "devops-monitoring-server"
    Role = "Monitoring"
  }
}
