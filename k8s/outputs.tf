output "master_address" {
    value = "${aws_instance.master.0.public_dns}"
}
output "worker_addresses" {
    value = ["${join(",", aws_instance.worker.*.public_dns)}"]
}
