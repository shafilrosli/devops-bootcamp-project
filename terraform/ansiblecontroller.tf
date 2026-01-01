############################################
# Ubuntu 24.04 AMI via SSM (Region-safe)
############################################

############################################
# Ansible Controller EC2 (Private)
############################################
resource "aws_instance" "ansible_controller" {
  ami                    = "ami-001c7178515f44952"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_subnet.id
  private_ip             = "10.0.0.135"
  vpc_security_group_ids = [aws_security_group.devops_private_sg.id]
  key_name               = "test"
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name
  associate_public_ip_address = false

  user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install -y software-properties-common
    add-apt-repository --yes --update ppa:ansible/ansible
    apt install -y ansible
  EOF

  tags = {
    Name = "devops-ansible-controller"
    Role = "Ansible"
  }
}