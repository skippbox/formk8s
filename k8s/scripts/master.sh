#!/bin/bash

sudo cp /tmp/etcd /etc/etcd/etcd.conf
sudo cp /tmp/config /etc/kubernetes/config
sudo cp /tmp/apiserver /etc/kubernetes/apiserver

for s in etcd kube-apiserver kube-controller-manager kube-scheduler; do
    sudo systemctl restart $s
    sudo systemctl enable $s
    sudo systemctl status $s
done

sudo etcdctl set coreos.com/network/config < /tmp/flannel-config.json

sudo systemctl restart flanneld
sudo systemctl enable flanneld
sudo systemctl status flanneld

sudo systemctl reboot
