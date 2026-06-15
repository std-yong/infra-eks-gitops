resource "aws_instance" "ubuntu_bastion" {

  ami = "ami-0e38c97339cddf4bd"
  availability_zone = "ap-northeast-2a"
  instance_type = "t2.micro"
  key_name = "rapa"
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  subnet_id = module.vpc.public_subnets[0]
  associate_public_ip_address = true

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("../rapa.pem")
    host = self.public_ip
  }

  provisioner "file" {
    source      = "./install.sh"
    destination = "/home/ubuntu/install.sh"
  }

  provisioner "file" {
    source      = "./install_istio.sh"
    destination = "/home/ubuntu/install_istio.sh"
  }

  provisioner "file" {
    source      = "./install_argocd.sh"
    destination = "/home/ubuntu/install_argocd.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sh /home/ubuntu/install.sh"
    ]
  }
  tags = {
      Name = "ubuntu_bastion"
  }
}
