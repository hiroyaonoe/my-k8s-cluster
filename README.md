# my-k8s-cluster
## 新しいサービスのデプロイ方法
- `manifests`にディレクトリを作ってmainfestを配置(manifestsを外部レポジトリから取ってくるなら不要)
- `applications`にファイルを作ってApplicationを作成
- argocdからsync

## GUIコンソールエンドポイント一覧
`*.internal.onoe.dev`を`192.168.0.100`でDNS解決できるように(Tailscaleなどで)設定するか、`etc/hosts`を参考に`/etc/hosts`を書き換えておくこと

| service    | endpoint                                  |
|:----------:|:-----------------------------------------:|
| argocd     | https://argocd.k8s.internal.onoe.dev/     |
| grafana    | https://grafana.k8s.internal.onoe.dev/    |
| prometheus | https://prometheus.k8s.internal.onoe.dev/ |
| kibana     | https://kibana.k8s.internal.onoe.dev/     |
| netdata    | https://netdata.k8s.internal.onoe.dev/    |
| otel-demo  | https://otel-demo.k8s.internal.onoe.dev/  |
| vault      | https://vault.k8s.internal.onoe.dev/      |

## クラスタの作成方法
`kubeadm/tmp_kubernetes.sh`を参考にコマンドを実行してクラスタを作成する
### Calicoをインストール
(ref: https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart)
```
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml
kubectl create -f argocd/manifests/calico/custom-resources.yaml

watch kubectl get pods -n calico-system

kubectl taint nodes --all node-role.kubernetes.io/control-plane-

calicoctl get node
```


### ArgoCDをインストール
Manage ArgoCD using ArgoCD
ingress-nginxやmonitoring関連はapplyできないが問題ない
app-of-app.yamlだけ適用に失敗するのでもう一度applyする
```
kubectl create namespace argocd
kubectl apply -n argocd -k argocd/manifests/argocd
```

argocdのcliツールをインストール
#### adminのパスワード取得
```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
kubectl port-forward svc/argocd-server --address 0.0.0.0 -n argocd 8080:443
argocd login localhost:8080
## username: admin, password: 上で取得したやつ
argocd account update-password
```

app-of-appsによってapplicationsに置かれたApplicationはAuto Syncされる

(prometheus-crdsを最初にsyncしないと上手くいかないので注意)

#### Syncされない場合
```
ssh ubuntu -L 8080:localhost:8080
kubectl port-forward svc/argocd-server --address 0.0.0.0 -n argocd 8080:443
```
で`http://localhost:8080/`にアクセスして、prometheus-crdsから順に手動でSyncする

### ingress-nginxの設定
```
kubectl label nodes mandoloncello ingress-ready=true
```
### Grafanaの設定
```
# Username: admin Password:
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
prom-operator
```

### Vaultの設定
```bash
# https://developer.hashicorp.com/vault/docs/platform/k8s/helm/run#cli-initialize-and-unseal
kubectl exec -it vault-0 -n vault -- /bin/sh
# https://support.hashicorp.com/hc/en-us/articles/8552873602451-Vault-on-Kubernetes-and-context-deadline-exceeded-errors
VAULT_CLIENT_TIMEOUT=300s vault operator init
```

## Tips
### Calico再インストールのTips
https://komeiy.hatenablog.com/entry/2019/07/28/232356
https://github.com/projectcalico/calico/issues/8368#issuecomment-2120873448

```
kubectl get ns calico-system -o json > mygitignore/calico-system.json
# Remove finalizer from mygitignore/calico-system.json
kubectl replace --raw "/api/v1/namespaces/calico-system/finalize" -f mygitignore/calico-system.json
```

### Multus/Calicoが壊れた時
`/etc/cni/net.d/`配下のファイルのうち、関係あるものだけ消す
`/opt/cni/bin/multus-shim`を消す
```bash
# kubectl create job tmp-kill-multus-$(export LC_ALL=C; cat /dev/urandom | tr -dc a-z0-9 | head -c10) --from=cronjob/kill-multus -n kube-system
sudo rm /etc/cni/net.d/00-multus.conf
sudo rm /opt/cni/bin/multus-shim
```
関係ありそうなMultus/CalicoのPodを削除して再起動する
ContainerCreatingで止まっているPodも削除して再起動する
Multus/Calicoのクリーンインストールはめんどいので最終手段にする

### local-storage
```
NUM=1
sudo mkdir -p /mnt/disks/ssd${NUM}; sudo chmod 777 /mnt/disks/ssd${NUM}
```

### mandoloncello-nfs
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

## Kubevirt Multus
- https://kubevirt.io/user-guide/network/interfaces_and_networks/
- https://kubevirt.io/user-guide/user_workloads/startup_scripts/
- https://kubevirt.io/2018/attaching-to-multiple-networks.html
