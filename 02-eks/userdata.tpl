#!/bin/bash
echo "Starting EKS node bootstrap..." >> /var/log/eks-bootstrap.log
echo "Cluster: ${cluster_name}" >> /var/log/eks-bootstrap.log
echo "Endpoint: ${endpoint}" >> /var/log/eks-bootstrap.log

# EKS bootstrap script
/etc/eks/bootstrap.sh ${cluster_name} --apiserver-endpoint ${endpoint} --b64-cluster-ca ${ca_data}

echo "Bootstrap completed with exit code: $?" >> /var/log/eks-bootstrap.log
