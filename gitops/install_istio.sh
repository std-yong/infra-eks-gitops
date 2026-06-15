#!/bin/bash

curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.17.1 TARGET_ARCH=x86_64 sh -

export PATH="$PATH:/root/istio-1.17.1/bin"

cat <<EOF > istio-operator.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: istiocontrolplane
spec:
  profile: default
  components:
    egressGateways:
    - name: istio-egressgateway
      enabled: true
      k8s:
        hpaSpec:
          minReplicas: 2
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        hpaSpec:
          minReplicas: 2
    pilot:
      enabled: true
      k8s:
        hpaSpec:
          minReplicas: 2
  meshConfig:
    enableTracing: true
    defaultConfig:
      holdApplicationUntilProxyStarts: true
    accessLogFile: /dev/stdout
    outboundTrafficPolicy:
      mode: REGISTRY_ONLY
EOF
echo '# IstioOperator YAML 파일을 생성'

yes | istioctl install -f istio-operator.yaml
echo '# IstioOperator 리소스를 생성'

sleep 4

# 확인
kubectl get pods -n istio-system


kubectl label namespace default istio-injection=enabled
echo '# istio-injection 자동 주입 설정'


kubectl get namespace -L istio-injection
echo '# istio-injection 목록 확인'