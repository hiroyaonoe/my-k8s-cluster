# 新しいサービスのデプロイ方法
- `manifests`にディレクトリを作ってmainfestを配置(manifestsを外部レポジトリから取ってくるなら不要)
- `applications`にファイルを作ってApplicationを作成
- argocdからsync

# GUIコンソールエンドポイント一覧
`etc/hosts`を書き換えておくこと

| service    | endpoint                               |
|:----------:|:--------------------------------------:|
| argocd     | https://argocd.k8s.internal.onoe.dev    |
| grafana    | http://grafana.k8s.internal.onoe.dev    |
| prometheus | http://prometheus.k8s.internal.onoe.dev |

# Calicoのインストール手順
(ref: https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart)
```
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml
kubectl create -f argocd/manifests/calico/custom-resources.yaml

watch kubectl get pods -n calico-system

kubectl taint nodes --all node-role.kubernetes.io/control-plane-

calicoctl get node
```
### 再インストールのTips
https://komeiy.hatenablog.com/entry/2019/07/28/232356
https://github.com/projectcalico/calico/issues/8368#issuecomment-2120873448

```
kubectl get ns calico-system -o json > mygitignore/calico-system.json
# Remove finalizer from mygitignore/calico-system.json
kubectl replace --raw "/api/v1/namespaces/calico-system/finalize" -f mygitignore/calico-system.json
```

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

### Syncされない場合
```
ssh ubuntu -L 8080:localhost:8080
kubectl port-forward svc/argocd-server --address 0.0.0.0 -n argocd 8080:443
```
で`http://localhost:8080/`にアクセスして、prometheus-crdsから順に手動でSyncする

# ingress-nginx
```
kubectl label nodes onoe-ubuntu ingress-ready=true
```
# Grafana
```
# Username: admin Password:
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
prom-operator
```

# local-storage
```
NUM=1
sudo mkdir -p /mnt/disks/ssd${NUM}; sudo chmod 777 /mnt/disks/ssd${NUM}
```

# mandoloncello-nfs
```
sudo apt install nfs-kernel-server
sudo mkdir -p /export/nfs
sudo chmod 777 /export/nfs
cat << EOF >> /etc/exports
/export/nfs 192.168.0.0/24(rw,no_root_squash,no_subtree_check)
EOF
sudo systemctl enable nfs-blkmap.service --now
sudo exportfs -a
```

# References
- https://argo-cd.readthedocs.io/en/stable/getting_started/
- https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/
https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#manage-argo-cd-using-argo-cd
- https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/#app-of-apps-pattern

## ingress-nginx, argocd, kind
- https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#option-2-multiple-ingress-objects-and-hosts 
- https://m1yam0t0.com/posts/2021/04/argocd-in-kind/

## Cilium
- https://docs.cilium.io/en/stable/gettingstarted/kind/

# Kubevirt Multus
- https://kubevirt.io/user-guide/network/interfaces_and_networks/
- https://kubevirt.io/user-guide/user_workloads/startup_scripts/
- https://kubevirt.io/2018/attaching-to-multiple-networks.html
