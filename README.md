# infra-eks-gitops

채용공고 검색 서비스의 EKS 인프라·CI/CD·모니터링 구성을 정리한 쇼케이스 레포입니다.
2023년 3인 팀 프로젝트에서 본인이 담당한 인프라 영역의 실제 매니페스트와 의사결정을 모았습니다.

> 운영 데모: <https://youtu.be/uPV7aNdBSFg>

---

## 전체 구성도

```
┌─────────────┐   git push   ┌─────────────┐   build/push   ┌─────────┐
│ Developer   │ ───────────▶ │ Jenkins     │ ─────────────▶ │  ECR    │
└─────────────┘              └──────┬──────┘                └────┬────┘
                                    │ manifest commit            │
                                    ▼                            ▼
                             ┌─────────────┐   pull/sync   ┌──────────┐
                             │ GitHub repo │ ◀──────────── │ ArgoCD   │
                             └─────────────┘               └────┬─────┘
                                                                │ apply
                                                                ▼
                                                         ┌──────────────┐
                                                         │   EKS 1.24   │
                                                         │  (Terraform) │
                                                         └──────┬───────┘
                                                                │
                                            ┌───────────────────┴───────────────┐
                                            ▼                                   ▼
                                  ┌──────────────────┐               ┌───────────────────┐
                                  │ Prometheus +     │               │ App: front/back   │
                                  │ Grafana + Alert  │ ──Slack/Email │ (Istio sidecar)   │
                                  └──────────────────┘               └───────────────────┘
```

> 다이어그램 PNG 자리: `docs/architecture.png` (추후 교체)

---

## 디렉토리 안내

| 경로 | 설명 |
|---|---|
| `terraform/` | VPC + EKS 1.24 + 노드그룹 + Bastion (`terraform-aws-modules` 기반) |
| `cicd/` | Jenkins 파이프라인 (Checkout → ECR Login → Build → Push → Manifest 업데이트 → Istio inject) |
| `gitops/argocd/` | ArgoCD 설치 스크립트와 매니페스트 |
| `monitoring/prometheus/` | Prometheus 서버, ConfigMap(스크랩 룰 + 알람 룰), RBAC, node-exporter |
| `monitoring/grafana/` | Grafana 배포 + 데이터소스 |
| `monitoring/alertmanager/` | Alertmanager + Slack/이메일 알림 템플릿 |
| `monitoring/metrics/` | kube-state-metrics용 ServiceAccount/Role |
| `docs/` | 아키텍처 의사결정과 트러블슈팅 기록 |

---

## 주요 결정

- **Spinnaker → ArgoCD**: Spinnaker는 별도 빌드 머신에서 16GB 메모리 OOM. ArgoCD는 EKS 내부에 가볍게 올라가고 GitOps 모델이 팀 워크플로우에도 맞아 교체.
- **Helm 대신 Raw YAML + Kustomize**: 차트 학습/디버깅 비용보다 매니페스트를 그대로 읽고 고칠 수 있는 쪽이 팀에 유리하다고 판단. 환경 분기만 Kustomize overlay로 처리.
- **모니터링 4계층 분리**: Host(node-exporter), Container(cAdvisor), Application(/metrics), K8s(kube-state-metrics)를 각각 다른 Grafana 대시보드로 분리해 장애 원인 추적 시간을 줄였음.

자세한 내용은 [docs/architecture.md](docs/architecture.md) · [docs/troubleshooting.md](docs/troubleshooting.md).

---

## 시크릿 처리

이 레포에는 평문 자격증명을 두지 않습니다. `.env.example`을 복사해 로컬 `.env`로 채워 쓰고, 운영에서는 다음으로 주입합니다.

- **Jenkins**: Credentials Plugin (`withCredentials` 블록)
- **Alertmanager**: K8s `Secret`을 별도로 만들어 `api_url_file` 참조 또는 init container의 `envsubst`로 ConfigMap 렌더링
- **Terraform**: AWS CLI profile + `*.tfvars` (gitignore)

---

## 지금 다시 한다면

2023년에 만든 구성을 2026년 시점에서 재평가하면 다음과 같이 바꿀 것:

- **EKS 1.24 → 1.31+**, IRSA로 ServiceAccount 단위 권한 부여
- **노드그룹 → Karpenter**: 스팟 활용 + provisioning 속도
- **Jenkins → GitHub Actions**: 빌드 머신 운영 비용 제거, OIDC로 AWS 권한 임시 발급
- **ArgoCD ApplicationSet**: dev/staging/prod 환경을 단일 정의로 관리
- **부하 테스트(k6) 선행 → HPA target + Cluster Autoscaler** 임계값을 근거 기반으로 설정
- **Bastion 제거 → SSM Session Manager**: 22 포트 자체를 닫음

---

## 회고 / 남은 과제

- 부하 테스트 없이 임계값을 정했음. 다음에는 k6로 RPS-리소스 상관관계를 먼저 측정하고 HPA target을 잡아야 함.
- Bastion 보안그룹을 학습 편의상 `0.0.0.0/0` 전체 허용으로 열어둠. 운영이면 사무실 IP CIDR + 22/443만 열어야 함.
- `tfstate` 원격 백엔드(S3 + DynamoDB lock) 미구성. 단일 작업자라 충분했지만 협업 시 필수.
