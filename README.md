Terraform state storage 
Create bucket:
aws s3api create-bucket --bucket devops-bootcamp-terraform-shafilrosli --region ap-southeast-5 --create-bucket-configuration LocationConstraint=ap-southeast-5
Enable Versioning:
aws s3api put-bucket-versioning  --bucket bucket devops-bootcamp-terraform-shafilrosli  --versioning-configuration Status=Enabled
Create DynamoDB for Locking: 
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
Create backend.tf: 
terraform {
  backend "s3" {
    bucket         = "devops-bootcamp-terraform-shafilrosli"
    key            = "dev/terraform.tfstate"
    region         = "ap-southeast-5"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}


Initialise Terraform: 
terraform init
Verify state in S3:
aws s3 ls s3://devops-bootcamp-terraform-shafilrosli/dev/
58783 terraform.tfstate

Creating AWS Instance, VPC, SSH Key, Security Group, use existing SSM Role and installing Ansible in AWS Instance (ansiblecontroller) using Terraform. 
-terraform init
-terraform plan
-terraform apply --auto-approve
Connect to (devops-ansible-controller) instance using Session Manager and do the following command: 
-mkdir ansible && cd ansible
-nano test.pem
-nano ansible.cfg
-nano inventory.ini 
-nano playbook.yaml
Run command: chmod 400 test.pem to change ownership.
Then, generate public key for test.pem using: ssh-keygen –y -f test.pem>test.pem.pub
Then run: cat test.pem.pub to expose public key. 
Connect to webserver and run this: 
-mkdir .ssh && cd .ssh
-nano authorized_keys
-paste public key and save to authorized_keys
-run sudo –i
-run below command: 
ls -ld /home/ssm-user
ls -ld /home/ssm-user/.ssh
ls -l /home/ssm-user/.ssh/authorized_keys
chown -R ssm-user:ssm-user /home/ssm-user/.ssh
chmod 700 /home/ssm-user/.ssh
chmod 600 /home/ssm-user/.ssh/authorized_keys
exit
Go back to ansiblecontroller instance and run ssh -i test.pem ssm-user@10.0.0.5
Connection will be made from ansible and webserver instance. 
Run below command in ansible controller: 
ansible all -i inventory.ini -m ping
ansible-playbook --syntax-check -i inventory.ini playbook.yaml
ansible-playbook -i inventory.ini playbook.yaml
-this is to install docker to all instance.

On local computer, do as follows: 

git clone git@github.com:Infratify/lab-final-project.git
cd lab-final-project
-create repo in ECR AWS: 
aws ecr create-repository \
  --repository-name devops-bootcamp-final-project-shafilrosli \
  --region ap-southeast-5
Login into ECR:
aws ecr get-login-password --region ap-southeast-5 | \
docker login --username AWS --password-stdin \
496844335034.dkr.ecr.ap-southeast-5.amazonaws.com/devops-bootcamp-final-project-shafil
Tag local image to ECR: 
docker tag lab-final-project-final-project:latest 496844335034.dkr.ecr.ap-southeast-5.amazonaws.com/devops-bootcamp-final-project-shafilrosli:latest
Push local image to ECR: 
docker push 496844335034.dkr.ecr.ap-southeast-5.amazonaws.com/devops-bootcamp-final-project-shafilrosli:latest
Verify images: 
aws ecr list-images \
  --repository-name devops-bootcamp-final-project-shafilrosli \
  --region ap-southeast-5

Pull Docker Images from ECR to WebServer
Login to ECR:
aws ecr get-login-password --region ap-southeast-5 | docker login --username AWS --password-stdin 496844335034.dkr.ecr.ap-southeast-5.amazonaws.com/devops-bootcamp-final-project-shafilrosli
newgrp docker
Pull ECR images into webserver:
docker pull 496844335034.dkr.ecr.ap-southeast-5.amazonaws.com/devops-bootcamp-final-project-shafilrosli:latest
docker images
Run Docker images:
docker run -d -p 80:80 496844335034.dkr.ecr.ap-southeast-5.amazonaws.com/devops-bootcamp-final-project-shafilrosli:latest
docker ps
Remove and run the images follow the .env files that have updated information:
docker rm -f devops-bootcamp-final-project-shafilrosli && docker run -d   --name devops-bootcamp-final-project-shafilrosli   --env-file /home/ssm-user/webserver/.env   -p 80:80  496844335034.dkr.ecr.ap-southeast-5.amazonaws.com/devops-bootcamp-final-project-shafilrosli:latest 

Prometheus and Grafana:

Verify node exporter is running and listening on port 9100 in webserver:
sudo ss -tulnp | grep 9100
tcp   LISTEN 0      4096               *:9100            *:*    users:(("node_exporter",pid=1113,fd=3))

Install Prometheus and Grafana in monitoring server using docker-compose.yml: 

version: "3.9"

services:
  node-exporter:
    image: quay.io/prometheus/node-exporter:latest
    container_name: node-exporter
    network_mode: "host"   # allows Prometheus to scrape host metrics
    pid: "host"            # needed for host metrics
    restart: unless-stopped

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
    network_mode: "host"   # same network so Prometheus can reach node-exporter
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    network_mode: "host"   # allows SSM port forwarding to access Grafana
    restart: unless-stopped
    volumes:
      - grafana-data:/var/lib/grafana

volumes:
  grafana-data:

Create Prometheus.yml in monitoring server to get information from webserver: 

global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node-exporter-webserver'
    static_configs:
      - targets: ['10.0.0.5:9100']  # Replace with your webserver private IP



Cloudflare Setup for https://monitoring.shafilrosli.com/: 

Install Cloudflare Tunnel in monitoring server: 

wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

Check Cloudflare version: 

cloudflared –version

Login Cloudflare: 

cloudflared login

Create tunnel: 

cloudflared tunnel create monitoring-tunnel

Create config.yml: 

tunnel: monitoring-tunnel
credentials-file: /home/ssm-user/.cloudflared/5f38daa6-a03a-4730-bc26-3237865820d0.json

ingress:
  - hostname: monitoring.shafilrosli.com
    service: http://localhost:3000
  - service: http_status:404

Run tunnel: 

cloudflared tunnel run monitoring-tunnel

Create DNS route on the monitoring server: 

cloudflared tunnel route dns monitoring-tunnel monitoring.shafilrosli.com

Verify DNS in Cloudflare Dashboard: 

 Fix permission for config.yml: 

sudo chmod 644 /etc/cloudflared/config.yml
sudo chmod 644 /home/ssm-user/.cloudflared/5f38daa6-a03a-4730-bc26-3237865820d0.json

Install cloudflared as a service: 

sudo cloudflared service install

Start and enable the service: 

sudo systemctl enable cloudflared
sudo systemctl start cloudflared

Make sure tunnel is active: 

cloudflared tunnel info monitoring-tunnel

Test : https://monitoring.shafilrosli.com/

Should be running as expected!

Cloudflare Setup for https://web.shafilrosli.com/:

Add DNS record 
Use Elastic IP for IPv4.
Set Cloudflare SSL mode to flexible: 
Go to https://web.shafilrosli.com/ and should able to view the webpage.

