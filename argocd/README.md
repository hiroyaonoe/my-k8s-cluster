# 新しいサービスのデプロイ方法
- `manifests`にディレクトリを作ってmainfestを配置(manifestsを外部レポジトリから取ってくるなら不要)
- `applications`にファイルを作ってApplicationを作成
- argocdからsync

# GUIコンソールエンドポイント一覧
`etc/hosts`を書き換えておくこと

| service    | endpoint                               |
|:----------:|:--------------------------------------:|
| argocd     | https://argocd.onoe-ubuntu.internal    |
| grafana    | http://grafana.onoe-ubuntu.internal    |
| prometheus | http://prometheus.onoe-ubuntu.internal |

# ArgoCDのインストール手順
```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# argocdのcliツールをインストール
## adminのパスワード取得
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
kubectl port-forward svc/argocd-server --address 0.0.0.0 -n argocd 8080:443
argocd login localhost:8080
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

(prometheus-crdsを最初にsyncしないと上手くいかないので注意)

# References
- https://argo-cd.readthedocs.io/en/stable/getting_started/
- https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/
https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#manage-argo-cd-using-argo-cd
- https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/#app-of-apps-pattern

## ingress-nginx, argocd, kind
- https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#option-2-multiple-ingress-objects-and-hosts 
- https://m1yam0t0.com/posts/2021/04/argocd-in-kind/
