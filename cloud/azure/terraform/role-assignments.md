## Azure role assignments (examples)

```bash
# Grant AKS kubelet identity pull access to ACR
az role assignment create --assignee <kubeletObjectId> --role AcrPull --scope <acrId>

# Allow a CI service principal to push images to ACR
az role assignment create --assignee <sp-appId> --role AcrPush --scope <acrId>
```
