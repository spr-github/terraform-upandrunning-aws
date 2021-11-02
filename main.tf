provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "exemple" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  user_data     = <<-EOF
  #!/bin/bash
  echo "Hello, World" > index.html
  nohup busybox httpd -f -p 8080 &
  EOF
  vpc_security_group_ids = [aws_security_group.instance.id]

  tags = {
    Name = "terraform-example"
  }
}
resource "aws_security_group" "instance" {
  name = "terraform-exemple-instance"
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "value"
    from_port = 8080
    # ipv6_cidr_blocks = [ "::/0" ]
    # prefix_list_ids = ["anything"]
    protocol = "tcp"
    # security_groups = [ "value" ]
    # self = false
    to_port = 8080
  }

}