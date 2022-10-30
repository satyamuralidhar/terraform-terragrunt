resource "random_id" "random" {
  byte_length = 2
  
}
#-----------------------------------------
#cretaing a virtual network 
#-----------------------------------------

resource "aws_vpc" "main" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "${var.env}-vpc"
  }
}

#---------------------------------------
#subnet creation of vnet
#----------------------------------------
resource "aws_subnet" "subnet" {
  vpc_id = "${aws_vpc.main.id}"
  count = "${length(var.subnet)}"
  availability_zone = "${element(var.azs,count.index)}"
  //element(list,index)
  cidr_block = "${element(var.subnet,count.index)}"
  //map_public_ip_on_launch = "${aws_subnet.subnet[0].id == true ? true : false}"
  tags = {
    "Name" = "subnet-${count.index+1}"
  }
}

#---------------------------------------
#creating route table
#--------------------------------------- 

resource "aws_route_table" "route" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  depends_on = [
    aws_vpc.main,
    aws_subnet.subnet,
    aws_internet_gateway.gw
  ]
}

#-------------------------------------------
#route table creation
#-------------------------------------------

resource "aws_route_table_association" "table_association" {
  count = length(var.subnet)
  subnet_id = "${aws_subnet.subnet[0].id}"
  route_table_id = "${aws_route_table.route.id}"
  //gateway_id = "${aws_internet_gateway.gw.id}"
}

#----------------------------------------
#internet gateways
#----------------------------------------

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  depends_on = [
    aws_vpc.main,
    aws_subnet.subnet
  ]
}

#-------------------------------------------
#creating security group
#-------------------------------------------


resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow http traffic"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tagging,
    {
    Name = "allow_traffic-${random_id.random.dec}"
    }
  )
  depends_on = [
    aws_internet_gateway.gw,
    aws_vpc.main,
    aws_subnet.subnet
  ]
}

#--------------------------------------------
#creating linux vm
#--------------------------------------------

resource "aws_instance" "linux_instance" {
  ami = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  security_groups = [ "${aws_security_group.web_sg.id}" ]
  subnet_id = "${aws_subnet.subnet[0].id}"
  associate_public_ip_address = true
  #create a webserver nginx
  tags = {
    Name = "Webserver-${var.env}"
  }
  depends_on = [
    aws_security_group.web_sg
  ]

}

#-----------------------------------
#generate a privatekey to loginto instance
#-----------------------------------

resource "tls_private_key" "generated_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
  depends_on = [
  aws_instance.linux_instance
]
}

#-------------------------------
#create a key form aws 
#-------------------------------

resource "aws_key_pair" "generated_key" {
  
  # Name of key: Write the custom name of your key
  key_name   = "ec2-key"
  
  # Public Key: The public will be generated using the reference of tls_private_key.terrafrom_generated_private_key
  public_key = tls_private_key.generated_private_key.public_key_openssh
 
  # Store private key :  Generate and save private key(aws_keys_pairs.pem) in current directory 
  provisioner "local-exec" {   
    command = <<-EOT
      echo '${tls_private_key.generated_private_key.private_key_pem}' > aws_keys_pairs.pem
      chmod 400 aws_keys_pairs.pem
    EOT
  }

  depends_on = [
  aws_instance.linux_instance,
  tls_private_key.generated_private_key

]

}
