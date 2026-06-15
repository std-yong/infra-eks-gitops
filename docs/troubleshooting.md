# Troubleshooting Log

프로젝트 중 마주친 이슈와 해결 과정.

---

## 1. ECR Login 실패

**증상**: Jenkins agent에서 `docker login` 단계가 `denied: Your authorization token has expired` 로 실패.

**원인**: ECR 토큰은 12시간 TTL인데 빌드 머신이 토큰을 캐시하고 있었음.

**해결**: 매 빌드마다 `aws ecr get-login-password | docker login --password-stdin` 으로 토큰 재발급. Jenkinsfile `Docker Login to ECR` 스테이지가 이 패턴.

---

## 2. Prometheus 포트 혼동

**증상**: scrape 타겟 `up == 0`. node-exporter는 떠 있는데 메트릭이 안 들어옴.

**원인**: node-exporter 기본 포트는 9100. NodePort로 노출하면서 31886을 외부 포트로 매핑했는데, ConfigMap의 scrape target에 노드 IP를 적으면서 NodePort를 쓰는지 ContainerPort를 쓰는지 혼동.

**해결**: NodePort로 노출한 경우 `<node-ip>:<nodePort>` 형식이 맞음. `monitoring/prometheus/prometheus-config-map.yaml`의 `node-exporter-static` job 참고.

---

## 3. 부하 테스트 부재

**증상**: HPA·노드 오토스케일링 임계값을 정할 근거가 없음.

**원인**: 일정상 Locust/k6 도입을 다음 스프린트로 미룸.

**다음 액션**: k6 스크립트로 RPS 곡선 → CPU/메모리 상관관계 측정 → HPA target utilization 산정.
