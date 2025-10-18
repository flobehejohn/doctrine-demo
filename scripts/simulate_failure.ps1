param([string]$LabelSelector = "app=doctrine-demo", [string]$Namespace = "default")
kubectl delete pod -n $Namespace -l $LabelSelector --grace-period=0 --force
