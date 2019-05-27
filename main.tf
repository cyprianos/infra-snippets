provider "aws" {
  region = "eu-central-1"
}

variable "server_port" {
  description = "HTTP server port"
  default     = 8080
}

output "elb_dns_name" {
  value = aws_elb.example.dns_name
}

data "aws_availability_zones" "all" {
}

resource "aws_launch_configuration" "example" {
  image_id      = "ami-8504fdea"
  instance_type = "t2.micro"

  key_name = aws_key_pair.deployer.key_name

  security_groups = [
    aws_security_group.instance.id,
  ]

  user_data = <<-EOF
              #!/bin/bash
              echo "Siema" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
EOF


  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.id
  availability_zones = data.aws_availability_zones.all.names
  load_balancers = [aws_elb.example.name]
  health_check_type = "ELB"
  min_size = 2
  max_size = 3
  desired_capacity = 2

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_key_pair" "deployer" {
  key_name = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC2lJWyn1UuzYVqde8jOO7j9rcDZ16Ymw+4xBHGUphUNmKNKTM+YJsvPozv86nBBVfQzbSMa+a2F4CUGpRhXFTiP736L3EBHAsHNDfzCphGx2W1igqK2yd24YjhGlw9qqiKs4oDAhqmqAQImvTPRfM0Cp9A1hUDvi3DSGoFwvRd1A4cBDr79kEpzThqmqVisyty34hfY8YWmmURPOFv+LzSldUA75iuQRw9A/RZ5kmaF9Ifdo72gFVb+t15L0bu4FslAib89kid4ovGLGqctyz1zX7LKItI0U67TkXClmz14Q1oV8DuabVgy8o40v6+lwAEbkefQ62NH0rtOL2DPz9SHI6o2vcHsn6jbSUA8zOHa7nuDLOvxtp+/pOggQWce85FxcCuE7tFxzyaf6mXm9Vcs6w0Nq81yQnU+BL446YxzW3fvjaxTluyQzUOWtqyl+K5hpyN2BxJ9efeTyfCIF+bH1XKUWE9W0KCjTEfg1w7PAjEGU5QwB6nqiL35TLR575dh3cetEFmGsCrWSH2gNytO7ipmgcIoP3l0862av1Bc0KZcq8dKhEBOfUKtyFpR9siYVajS5Ap5gfXSYXM/RavZnnZ0nBp3u+du7yy3ct2GVUW5kAMxQdEhdxX9qI9jGmhd5L/Zg3UYmFbbVNOXBen+NS5Hrty7vJXrZtbGLcbdw== cgepfert@gmail.com"
}

resource "aws_elb" "example" {
  name = "terraform-asg-example"
  availability_zones = data.aws_availability_zones.all.names

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = var.server_port
    instance_protocol = "http"
  }

  security_groups = [aws_security_group.elb.id]

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:${var.server_port}/"
  }
}

resource "aws_security_group" "elb" {
  name = "terraform-example-elb"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

