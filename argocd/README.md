# 新しいサービスのデプロイ方法
- `manifests`にディレクトリを作ってmainfestを配置(manifestsを外部レポジトリから取ってくるなら不要)
- `applications`にファイルを作ってApplicationを作成
- argocdからsync

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
kubectl kustomize argocd/manifests/argocd | kubectl apply -f -
```
以降はArgoCDでSync

app-of-appsによってapplicationsに置かれたApplicationはAuto Syncされる

# References
- https://argo-cd.readthedocs.io/en/stable/getting_started/
- https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/
https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#manage-argo-cd-using-argo-cd
- https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/#app-of-apps-pattern
