                                _                             
                   ___ ___   __| | ___ _ __   ___  _ __ _ __  
                  / __/ _ \ / _` |/ _ \ '_ \ / _ \| '__| '_ \ 
                 | (_| (_) | (_| |  __/ |_) | (_) | |  | | | |
                  \___\___/ \__,_|\___| .__/ \___/|_|  |_| |_|
                                      |_|   



AWS EKS + Kubernetes using eksctl and terraform

Description:
1)This repo contains a kubernetes manifest to expose a node application.
2)Horizontol pod autoscaling
3)Custom image pushing on ECR 



we will be using
- kubectl (cli)
- terraform (cli)
- awscli
- aws-iam-authenticator
- eksctl


Directory ./app contains a simple nodejs json server.

In the root directory, Dockerfile, I have used to create a docker image.

Assumption
-awscli is already configured.


Cluster Creation using eksctl 
eksctl create cluster --name mad-titan --region us-east-2 --nodegroup-name my-nodes --node-type t3.micro --managed

Cluster Creation using terraform
cd eks-terraform
terraform init
terraform plan
terraform apply


After cluster creation using eksctl or terraform, any of one:

eksctl create two node by default to see them use following command.

yashwant@optimus:~/awsTask$ kubectl get nodes
NAME                                           STATUS   ROLES    AGE   VERSION
ip-192-168-2-80.us-east-2.compute.internal     Ready    <none>   12m   v1.14.9-eks-1f0ca9
ip-192-168-75-213.us-east-2.compute.internal   Ready    <none>   13m   v1.14.9-eks-1f0ca9

We can use --nodes n to have desired number of nodes
or scale using 
eksctl scale nodegroup --cluster=<clusterName> --nodes=<desiredCount> --name=<nodegroupName>



To check kubeconfig use,
eksctl utils write-kubeconfig --cluster=test-eks --kubeconfig=./kubeconfigs/cluster-config.yaml

if using terraform then ,
terraform output kubeconfig



** if getting error Invalid choice: 'eks', maybe you meant:
then update awscli


To check perfoemance I have used cli utility 'siege'.


Now, following are the steps I have used to create the deployment.

Deploy Metrics server

I have already clone the repo https://github.com/kubernetes-sigs/metrics-server (directory metrics-server).

tweaked a little at line 33
command:
    - /metrics-server
    - --kubelet-insecure-tls

cd metrics-server/deploy/kubernetes
kubectl apply -f .

To check deployed metrics server use
kubectl -n kube-system get pods

To check logs 
kubectl -n kube-system logs metrics-server-6dcfc5d9b4-ssb79


Now, back to root of repo 
cd ../../..

Create deployment

kubectl apply -f json-server-api-deployment.yml 
kubectl expose deployment json-server-api --type=LoadBalancer --name=json-server-api-service
kubectl get service json-server-api-service

Now go to the external ip.

http://ext-ip:3000/movies

you will see a json responce.


To autoscale the deployment (autoscaling/v2beta2):
First delete previously exposed service.

kubectl delete service json-server-api-service 

kubectl create -f hpa.yaml

Again expose the service.

Now to see whole scenario use
watch kubectl get all

&  kubectl top pods


Apart from all that I tried to use image hosted on ECR
1)Push image to ECR
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 782390919651.dkr.ecr.us-east-2.amazonaws.com/getting-started
docker build -t getting-started .
docker tag getting-started:latest 782390919651.dkr.ecr.us-east-2.amazonaws.com/getting-started:latest
docker push 782390919651.dkr.ecr.us-east-2.amazonaws.com/getting-started:latest

2)Pull image from ECR (to-do)
to pass imagepull secret need to setup a cronjob