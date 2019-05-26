//wybieramy region
provider "aws" {
  region = "eu-central-1"
}

resource "aws_instance" "example" {
  //zauwzmy, ze ami nalezy do regionu
  ami           = "ami-8504fdea"
  instance_type = "t2.micro"

  //jesli chcemy miec dostep ssh, potrzebujemy keypair
  key_name = "${aws_key_pair.deployer.key_name}"

  //konfiguracja port
  vpc_security_group_ids = [
    "${aws_security_group.instance.id}",
  ]

  tags {
    Name = "terraform-example"
  }

  //skrypt ktory zostanie uruchomiony po wlaczeniu instancji ec2
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
}

//konfiguracja protow ssh i 8080 dla www  
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

//musimy wygenerowac publiczny klucz(mozna do tego uzyc terraform)
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC2lJWyn1UuzYVqde8jOO7j9rcDZ16Ymw+4xBHGUphUNmKNKTM+YJsvPozv86nBBVfQzbSMa+a2F4CUGpRhXFTiP736L3EBHAsHNDfzCphGx2W1igqK2yd24YjhGlw9qqiKs4oDAhqmqAQImvTPRfM0Cp9A1hUDvi3DSGoFwvRd1A4cBDr79kEpzThqmqVisyty34hfY8YWmmURPOFv+LzSldUA75iuQRw9A/RZ5kmaF9Ifdo72gFVb+t15L0bu4FslAib89kid4ovGLGqctyz1zX7LKItI0U67TkXClmz14Q1oV8DuabVgy8o40v6+lwAEbkefQ62NH0rtOL2DPz9SHI6o2vcHsn6jbSUA8zOHa7nuDLOvxtp+/pOggQWce85FxcCuE7tFxzyaf6mXm9Vcs6w0Nq81yQnU+BL446YxzW3fvjaxTluyQzUOWtqyl+K5hpyN2BxJ9efeTyfCIF+bH1XKUWE9W0KCjTEfg1w7PAjEGU5QwB6nqiL35TLR575dh3cetEFmGsCrWSH2gNytO7ipmgcIoP3l0862av1Bc0KZcq8dKhEBOfUKtyFpR9siYVajS5Ap5gfXSYXM/RavZnnZ0nBp3u+du7yy3ct2GVUW5kAMxQdEhdxX9qI9jGmhd5L/Zg3UYmFbbVNOXBen+NS5Hrty7vJXrZtbGLcbdw== cgepfert@gmail.com"
}
