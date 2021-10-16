variable "region" {
  default = "eu-west-1"
}
variable "image_id" {
  default = "ami-05cd35b907b4ffe77"
}

variable "key_name" {
  default = "ec2-keypair"
}
variable "instance_type" {
  default = "t2.micro"
}
variable "name_prefix" {
  default = "terra1_"
}
variable "autoscaling_capacity" {
  default = 2
}
variable "autoscaling_max_size" {
  default = 3
}
variable "autoscaling_min_size" {
  default = 2
}

variable "init_script" {
  default = <<EOF
IyEvYmluL2Jhc2gKIyBVc2UgdGhpcyBmb3IgeW91ciB1c2VyIGRhdGEgKHNjcmlwdCBmcm9tIHRv
cCB0byBib3R0b20pCiMgaW5zdGFsbCBodHRwZCAoTGludXggMiB2ZXJzaW9uKQp5dW0gdXBkYXRl
IC15Cnl1bSBpbnN0YWxsIC15IGh0dHBkCnN5c3RlbWN0bCBzdGFydCBodHRwZApzeXN0ZW1jdGwg
ZW5hYmxlIGh0dHBkCmVjaG8gIjxoMT5IZWxsbyBXb3JsZCBmcm9tICQoaG9zdG5hbWUgLWYpPC9o
MT4iID4gL3Zhci93d3cvaHRtbC9pbmRleC5odG1s
EOF
}

variable "availability_zones" {
    default = ["eu-west-1a", "eu-west-1b"]
}

variable "security_groups" {
    default = ["sg-04cbc9fc53450397e", "sg-0d2c02f4547301136"]
}
  