variable "InfraId" {
  default = "devpanel-drupal8-quickstart"
}

resource "tls_private_key" "main_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_password" "db_password" {
  length          = 16
  special         = false
}

resource "aws_key_pair" "ssh_key" {
  key_name = var.InfraId
  public_key = tls_private_key.main_key_pair.public_key_openssh
} 

resource "aws_cloudformation_stack" "drupal8-quickstart-in-new-vpc" {
  name              = "drupal8-quickstart-in-new-vpc"
  capabilities      = ["CAPABILITY_IAM"]
  parameters        = {
    AvailabilityZones         = "us-east-1a,us-east-1b"
    BastionAMIOS              = "Ubuntu-Server-20.04-LTS-HVM"
    KeyPair                   = aws_key_pair.ssh_key.key_name
    RemoteAccessCIDR          = "192.168.1.0/24"
    #
    # Database
    DBMasterUserPassword      = random_password.db_password.result
    # Drupal 
    DrupalSiteAdminEmail      = "binhvo@devpanel.com"
    DrupalSiteAdminPassword   = "devpanel"
    DrupalDbPassword          = random_password.db_password.result
    # Notification Email
    AutoScalingNotificationEmail  = "binhvo@devpanel.com"
  }
  template_body     = file("cfm/drupal-master.template.yaml")
  timeout_in_minutes = 60
  timeouts {
    create = "60m"
  }
}