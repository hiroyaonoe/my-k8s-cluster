# 新しいサービスのデプロイ方法
- `manifests`にディレクトリを作ってmainfestを配置(manifestsを外部レポジトリから取ってくるなら不要)
- `applications`にファイルを作ってApplicationを作成
- argocdからsync

# ArgoCDのGUIコンソールの見方
```
kubectl port-forward svc/argocd-server -n argocd --address 0.0.0.0 9000:443
```
`http://[server]:9000` にアクセス

# ArgoCDをインストールした手順
```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# argocdのcliツールをインストール
## adminのパスワード取得
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
kubectl port-forward svc/argocd-server --address 0.0.0.0 -n argocd 9000:443
argocd login localhost:9000
## username: admin, password: 上で取得したやつ
argocd account update-password
```

その後 Manage ArgoCD using ArgoCD へ

## Manage ArgoCD using ArgoCD
```
kubectl kustomize argocd/manifests/argocd | kubectl apply -n argocd -f -
```
以降はArgoCDでSync

app-of-appsによってapplicationsに置かれたApplicationはAuto Syncされる

# References
- https://argo-cd.readthedocs.io/en/stable/getting_started/
- https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/
https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#manage-argo-cd-using-argo-cd
- https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/#app-of-apps-pattern
