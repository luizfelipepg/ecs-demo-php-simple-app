#!/bin/bash
# Setup for Kops cluster 
source /opt/k8s/logit.sh
>/var/log/kops.log

PATH=$PATH:/usr/local/sbin

log ""
log "======================================================================"
log "Start of K8s cluster creation........................................."
log "`service awslogs start`"
log "`service codedeploy-agent start`"
log "`service docker start`"
S3_BUCKET="p7handsondays-$(aws sts get-caller-identity --output text --query 'Account')-$(date +%H%M%S)"

# Create bucket 
aws s3api create-bucket --bucket $S3_BUCKET --region ap-southeast-2 --create-bucket-configuration LocationConstraint=ap-southeast-2
log "KOPS_STATE_STORE bucket $S3_BUCKET"

# Save state store bucket name to file for K8s deletion
echo "$S3_BUCKET" > /opt/k8s/state-store

#Setup env vars
export KOPS_FEATURE_FLAGS="+DrainAndValidateRollingUpdate"
export AWS_DEFAULT_REGION=ap-southeast-2
export KOPS_STATE_STORE=s3://$S3_BUCKET
export NAME=cluster.k8s.local
export NODE_SIZE=${NODE_SIZE:-t2.micro}
export MASTER_SIZE=${MASTER_SIZE:-t2.medium}

# Create SSH key
log "Creating SSH key for kops"
rm -f ~/.ssh/id_rsa*
ssh-keygen -t rsa -f ~/.ssh/id_rsa -q -P ""

log "`kops create cluster --name=${NAME} --cloud=aws --zones=ap-southeast-2a --node-count=2 --node-size $NODE_SIZE --master-zones=ap-southeast-2a --master-size=$MASTER_SIZE --state=$KOPS_STATE_STORE --networking=calico --yes`"

sleep 30
EXIT=0
while [ "$EXIT" = "0"  ]
do
   READY=$(kops validate cluster cluster.k8s.local | grep "Your cluster cluster.k8s.local is ready")
   if [ "$READY" != "" ]
   then
      log "Cluster state is $READY"
      EXIT=1
   else
      log "Cluster is not ready......................."
      sleep 30
   fi
done

kubectl apply -f /opt/k8s/dashboard.yaml
sleep 5
kubectl apply -f /opt/k8s/app.yaml
sleep 10

log "Getting your cluster UI URL and login details"
PASSWORD=`kubectl config view --minify | grep "password" | awk -F":" '{ print $2 }'`
SERVER=`kubectl config view --minify | grep "server" | awk -F" " '{ print $2 }'`
log "URL: $SERVER/ui"
log "user:     admin"
log "password: $PASSWORD"
log ""
WEBSITE=`kubectl describe svc website1 | grep "LoadBalancer Ingress" | awk -F":     " '{ print $2 }'`
log "Website URL"
log "http://$WEBSITE"
