resource "aws_security_group" "bastion_sg" {
    name = "bastion_sg"
    description = "inbound all"
    vpc_id = module.vpc.vpc_id

    ingress {
        description = "inbound 0.0.0.0"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        
    }

    egress = [

        {
            description = "outbound all"
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
            ipv6_cidr_blocks = []
            aws_security_groups = []
            prefix_list_ids = []
            self = false
            security_groups = []
        }
    ]
    tags = {
        Name = "Inbound & outbound allow all"
    }
}

resource "aws_security_group_rule" "allow_ingress" {
  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.eks.cluster_security_group_id
}


