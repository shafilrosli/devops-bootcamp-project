############################################
# EXISTING SSM ROLE (DO NOT CREATE)
############################################
data "aws_iam_role" "ec2_ssm_role" {
  name = "EC2-SSM-Role"
}

############################################
# INSTANCE PROFILE (REUSED BY ALL SERVERS)
############################################
resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "EC2-SSM-Instance-Profile"
  role = data.aws_iam_role.ec2_ssm_role.name
}