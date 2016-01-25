variable "ami" {
    default = {
        eu-west-1 = "ami-c9c075ba"
    }
}

variable "master_ami" {
    default = {
        eu-west-1 = "ami-c9c075ba"
    }
}

variable "key_name" {
    default = "k8s"
    description = "SSH key name in your AWS account for AWS instances."
}

variable "key_path" {
    default = "~/.ssh/id_rsa_k8s"
    description = "Path to the private key specified by key_name."
}

variable "region" {
    default = "eu-west-1"
    description = "The region of AWS, for AMI lookups."
}

variable "servers" {
    default = "3"
    description = "The number of k8s workers to launch."
}

variable "instance_type" {
    default = "m1.small"
    description = "The instance type to launch."
}

variable "master_instance_type" {
    default = "m1.small"
    description = "The instance type to launch."
}
