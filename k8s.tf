module "k8s" {
    source = "./k8s"
    key_name = "k8s"
    key_path = "~/.ssh/id_rsa_k8s"
    region = "eu-west-1"
    servers= "2"
    instance_type = "t2.micro"
    master_instance_type = "t2.micro"
}

output "master" {
    value = "${module.k8s.master_address}"
}

output "workers" {
    value = "${module.k8s.worker_addresses}"
}
