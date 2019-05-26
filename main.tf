provider "aws" {
  region= "eu-central-1"
}

resource "aws_instance" "example" {
  ami = "ami-8504fdea"
  instance_type = "t2.micro"
}
