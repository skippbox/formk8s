# A Terraform plan to start a k8s cluster with Atomic

resource "aws_security_group" "k8s" {
  name = "k8s"
  description = "Kubernetes traffic"

  ingress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "template_file" "kubelet" {
    template = "${path.module}/scripts/kubelet"

    vars {
        master_ip = "${aws_instance.master.private_ip}"
    }

    depends_on = ["aws_instance.master"]
}

resource "template_file" "config" {
    template = "${path.module}/scripts/config"

    vars {
        master_ip = "${aws_instance.master.private_ip}"
    }

    depends_on = ["aws_instance.master"]
}

resource "template_file" "flanneld" {
    template = "${path.module}/scripts/flanneld"

    vars {
        master_ip = "${aws_instance.master.private_ip}"
    }

    depends_on = ["aws_instance.master"]
}

resource "aws_instance" "master" {

    ami = "${lookup(var.master_ami, var.region)}"
    instance_type = "${var.master_instance_type}"
    key_name = "${var.key_name}"
    security_groups = ["${aws_security_group.k8s.name}"]

    connection {
        user = "centos"
        key_file = "${var.key_path}"
    }

    provisioner "file" {
        source = "${path.module}/scripts/etcd"
        destination = "/tmp/etcd"
    }

    provisioner "file" {
        source = "${path.module}/scripts/apiserver"
        destination = "/tmp/apiserver"
    }

    provisioner "file" {
        source = "${path.module}/scripts/flannel-config.json"
        destination = "/tmp/flannel-config.json"
    }

    provisioner "remote-exec" {
        scripts = [
            "${path.module}/scripts/master.sh",
        ]
    }

    tags {
        Name = "master"
    }
}

resource "aws_instance" "worker" {

    depends_on = ["aws_instance.master"]

    ami = "${lookup(var.ami, var.region)}"
    instance_type = "${var.instance_type}"
    key_name = "${var.key_name}"
    count = "${var.servers}"
    security_groups = ["${aws_security_group.k8s.name}"]
    
    connection {
        user = "centos"
        key_file = "${var.key_path}"
    }

    provisioner "file" {
        source = "${path.module}/scripts/proxy"
        destination = "/tmp/proxy"
    }

    provisioner "remote-exec" {
        inline = [
            "cat <<'EOF' > /tmp/config\n${template_file.config.rendered}\nEOF",
            "cat <<'EOF' > /tmp/kubelet\n${template_file.kubelet.rendered}\nEOF",
            "cat <<'EOF' > /tmp/flanneld\n${template_file.flanneld.rendered}\nEOF"
        ]
    }

    provisioner "remote-exec" {
        scripts = [
            "${path.module}/scripts/worker.sh",
        ]
    }

    tags {
        Name = "worker-${count.index}"
    }
}
