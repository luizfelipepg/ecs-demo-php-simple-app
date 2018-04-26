#!/bin/bash
source /opt/k8s/logit.sh
S3_BUCKET=`cat /opt/k8s/state-store`
export KOPS_STATE_STORE=s3://$S3_BUCKET
export NAME=cluster.k8s.local
echo "$KOPS_STATE_STORE $NAME"
log "`/usr/local/sbin/kops delete cluster $NAME --yes`"
