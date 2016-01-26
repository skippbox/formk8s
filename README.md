Terraform plan for Atomic based k8s cluster
===========================================

This is a terraform plan to create a Kubernetes cluster on AWS based on Atomic OS. You will need a AWS account and [terraform](https://www.terraform.io) installed on your system.

Currently only AWS is supported, PR to add additional cloud providers welcome.

A single master is created which runs a one node etcd, flannel is used to create an overaly network used by Kubernetes.
Configuration of systemd units is done by copying files to the instances or using templates. Nodes auto-register with the master.

Currently, the API server is not secured by TLS and authorization is not implemented. This is to be used for dev and test.

Usage
-----

    $ git clone https://github.com/skippbox/formk8s.git
    $ cd formk8s

The k8s plan is inside a module, load it

    $ terraform get

And now apply the plan (will take a minute):

    $ terraform apply
    module.k8s.aws_security_group.k8s: Creating...
    description:                         "" => "Kubernetes traffic"

    ...

    Outputs:

        master  = ec2-52-17-199-53.eu-west-1.compute.amazonaws.com
        workers = ec2-52-48-45-230.eu-west-1.compute.amazonaws.com,ec2-52-49-117-239.eu-west-1.compute.amazonaws.com    

Connect to the head node which has the `kubectl` cli in its path and check that all nodes have joined the Kubernetes cluster:

    $ ssh -i ~/.ssh/id_rsa_k8s centos@ec2-52-17-199-53.eu-west-1.compute.amazonaws.com
    [centos@ip-172-31-40-236 ~]$ kubectl get nodes
    NAME                                          LABELS                                                               STATUS
    127.0.0.1                                     kubernetes.io/hostname=127.0.0.1                                     Ready
    ip-172-31-36-209.eu-west-1.compute.internal   kubernetes.io/hostname=ip-172-31-36-209.eu-west-1.compute.internal   Ready
    ip-172-31-42-27.eu-west-1.compute.internal    kubernetes.io/hostname=ip-172-31-42-27.eu-west-1.compute.internal    Ready

The IP addresses of the instances you create will be different.

Testing
-------

You can log into each node and check that the Flannel overlay is properly setup and try creating a replication controller.
For instance to run a nginx replicaton controller:

    [centos@ip-172-31-40-236 ~]$ kubectl run nginx --image=nginx
    [centos@ip-172-31-40-236 ~]$ kubectl get rc
    CONTROLLER   CONTAINER(S)   IMAGE(S)   SELECTOR    REPLICAS
    nginx        nginx          nginx      run=nginx   1

Once the image is downloaded the pod will enter running state

    [centos@ip-172-31-40-236 ~]$ kubectl get pods
    NAME          READY     STATUS    RESTARTS   AGE
    nginx-vkqte   1/1       Running   0          1m

You can now expose this replication controller to the outside, using a service. For testing you can use a NodePort type of service, since the security group currently opens every port (not recommended though).

    [centos@ip-172-31-40-236 ~]$ cat s.yaml
    apiVersion: v1
    kind: Service
    metadata: 
      labels: 
        name: nginx
      name: nginx
    spec: 
      type: NodePort
      ports:
      - port: 80
        targetPort: 80
      selector: 
        run: nginx

    [centos@ip-172-31-40-236 ~]$ kubectl create -f s.yaml 
    You have exposed your service on an external port on all nodes in your
    cluster.  If you want to expose this service to the external internet, you may
    need to set up firewall rules for the service port(s) (tcp:30606) to serve traffic.

If you open your browser on the IP of the node running the pod and port 30606, you will see the homepage of nginx.

Tuning
------

The main k8s plan is `k8s.tf` and looks like this:

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

Change the key name, path, region, number of servers etc in this file.

Additional defaults are set in the module file `k8s/variables.tf`

Support
-------

If you experience problems with `formk8s` or want to suggest improvements please file an [issue](https://github.com/skippbox/formk8s/issues).
