#!/bin/bash

kubectl create namespace argocd
echo '네임스페이스 생성'

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo '설치'

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
echo '외부 접속을 위해 type을 로드밸런서로 변경'

sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
echo 'argo cli 설치'
sleep 4

sudo chmod +x /usr/local/bin/argocd
echo '실행 권한'

kubectl  get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" -n argocd | base64 -d; echo
echo '초기 패스워드'

kubectl get svc -n argocd argocd-server
echo '서비스 확인(외부주소)'
echo 'metallb.yml, metal-cm.yml 생성 후 확인'