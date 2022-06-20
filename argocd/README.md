# ArgoCDのGUIコンソールの見方
```
ssh -L 8080:localhost:8080 <server>
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
http://localhost:8080 にアクセス

# ArgoCDをインストールした手順
```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# argocdのcliツールをインストール
## adminのパスワード取得
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
kubectl port-forward svc/argocd-server -n argocd 8080:443
argocd login localhost:8080
## username: admin, password: 上で取得したやつ
argocd account update-password
```

## Manage ArgoCD using ArgoCD
```
kubectl kustomize argocd/app/argocd | kubectl apply -f -
kubectl apply -f argocd/app/argocd/application.yaml
```
以降はArgoCDでSync

# References
- https://argo-cd.readthedocs.io/en/stable/getting_started/
- https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/
https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#manage-argo-cd-using-argo-cd
