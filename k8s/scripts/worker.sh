#!/bin/bash

sudo cp /tmp/config /etc/kubernetes/config
sudo cp /tmp/kubelet /etc/kubernetes/kubelet
sudo cp /tmp/proxy /etc/kubernetes/proxy
sudo cp /tmp/flanneld /etc/sysconfig/flanneld

for s in kube-proxy kubelet flanneld; do
    sudo systemctl restart $s
    sudo systemctl enable $s
    sudo systemctl status $s
done

sudo systemctl reboot
