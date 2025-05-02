## Terraform 기반 인프라 실행부터 Ansible 배포까지의 전체 흐름

### 1. Terraform 인프라 실행

```bash
cd terraform/
terraform init
terraform apply -auto-approve
```

- Terraform이 완료되면, `outputs.tf`에서 정의한 IP를 출력하여 Ansible에서 사용할 수 있도록 준비합니다.

---

### 2. Route53 A레코드 수동 등록

- Terraform 실행 이후 출력된 Public IP를 기준으로 `Route53`에서 도메인을 수동으로 연결합니다.
  - 예시 도메인: `test.moongsan.com`
  - 연결 대상: `GCP VM 인스턴스의 Public IP`

---

### 3. Ansible 변수 설정

- Ansible에서 사용할 도메인 관련 설정을 `group_vars/all.yml`에 추가합니다:

```yaml
domain_name: test.moongsan.com
```

- 또는 서비스별로 분리하여 사용할 경우:

```yaml
frontend_domain: test.moongsan.com
backend_domain: test.moongsan.com
fastapi_domain: test.moongsan.com
```

---

### 4. Ansible 실행

- 원하는 태그만 실행할 수 있도록 태그 기반으로 플레이북 실행:

```bash
ansible-playbook -i inventory.ini playbook.yml --tags common,frontend,backend,fastapi
```

- 전체 실행 시:

```bash
ansible-playbook -i inventory.ini playbook.yml
```

---

### 5. 결과 확인

- 웹 브라우저 또는 curl을 통해 도메인 접근 확인:

```bash
curl -i https://test.moongsan.com
```

- 정상 응답 예시: `HTTP/1.1 200 OK`
