# Architecture Notes

## 네트워크

- VPC `10.0.0.0/16`, AZ 2개 (ap-northeast-2a, 2c)
- public subnet × 2 → ALB / Bastion
- private subnet × 2 → EKS 워커노드
- NAT Gateway 1개 (단일 NAT는 비용 절감 트레이드오프)

## EKS

- 버전 1.24
- managed node group 2개 (각 AZ에 t2.medium 1~2대), 총 desired 2
- `terraform-aws-modules/eks/aws` v19.10.0 사용

## CI/CD

Jenkinsfile 단계:
1. **Checkout** — GitHub HTTPS clone
2. **ECR Login** — `aws ecr get-login-password`
3. **Image Build** — `${BUILD_NUMBER}` + `latest` 동시 태깅
4. **Image Push** — push 후 로컬 이미지 삭제로 디스크 보호
5. **Manifest Update** — `sed`로 매니페스트의 이미지 태그 치환 후 git push (ArgoCD가 이 변경을 감지)
6. **Istio Sidecar Injection** — `istioctl kube-inject`로 사이드카 포함 매니페스트 생성

## 모니터링 4계층

| 계층 | 수집기 | 주요 메트릭 |
|---|---|---|
| Host | node-exporter | CPU, 메모리, 디스크 I/O |
| Container | cAdvisor (kubelet 내장) | 컨테이너별 리소스 사용량 |
| Application | 앱 자체 `/metrics` 엔드포인트 | 요청 수, 응답 시간 |
| Kubernetes | kube-state-metrics | Pod 상태, Deployment 상태 |

## 알람 룰 (Prometheus)

`monitoring/prometheus/prometheus-config-map.yaml` 참고. 핵심 룰:
- container memory > 55% → fatal
- container CPU > 1% (데모용 임계값) → fatal
- Alertmanager notification 실패 → critical
- Prometheus 타겟 0개 → critical
