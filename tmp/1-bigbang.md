# 1단계: Big Bang 방식 수작업 배포 설계

## 수작업(Big Bang) 배포 방식의 한계 분석

### 도입 배경
- 단일 VM 위에서 React, Spring Boot, FastAPI, MySQL을 직접 실행
- 초기 자동화보다 빠른 프로토타입 배포를 목표로 함
- 배포 빈도가 낮고, 팀 인원이 소수인 상황이라 일괄 배포 전략이 현실적으로 용이함

### 실제 운영 중 겪은 한계점 및 장애 사례

| 분류 | 사례 | 내용 |
|------|------|------|
| **인프라 리스크** | `apt-get` 잠금 충돌 | VM에서 백그라운드로 `apt`가 동작 중이어서 ansible이 실패함 (dpkg 락 충돌 발생) |
| **배포 실패 대응력** | FastAPI 서비스 죽음 | systemd에서 `ExecStart` 잘못 작성해 배포 후 FastAPI가 계속 죽었음 (쉘 리디렉션 사용 오류) |
| **접속 불가 오류** | 502 Bad Gateway | Spring → FastAPI 통신 중 포트 미열림 / 프로세스 죽음으로 인한 Gateway 오류 발생 |
| **의존성 문제** | Spring 빌드 실패 | `application.properties`에 선언된 환경변수 미설정으로 `@Value` 주입 실패 발생 |
| **깃 레포 관리** | Git unsafe repo | Ansible로 clone된 디렉토리가 안전하지 않아 git 명령어 실행이 차단됨 (`safe.directory` 미등록) |
| **CI 연동 부재** | 변경 미감지 | 코드가 변경됐는데도 `git pull`이 동작하지 않아 최신 코드 반영 실패 (Ansible 내 변화 감지 안 됨) |
| **Log 문제** | 로그 무한 누적 | FastAPI 로그가 무한히 누적됨 → `logrotate` 도입 전 디스크 용량 경고 우려 |
| **롤백 불가능** | `rollback.sh` 없음 | 배포 후 오류 발생 시 재배포밖에 방법이 없어 긴 장애시간 발생 가능성 내포 |

### 개선 방향 제안
- `rollback.sh` 작성하여 `.bak` 기반의 빠른 복구 가능하게 하기
- 환경변수 `.env` 혹은 Ansible 변수 활용으로 Spring 구성 오류 방지
- logrotate 및 GCS 연동 고려 (장기 보존용)
- 각 서비스 상태를 `curl`로 자동 확인하는 테스트 스크립트 작성
- CI 도입 전까지는 수동 체크리스트 기반으로 모든 배포 단계 기록 유지

---

## 수동 배포 체크리스트

| 단계 | 담당자 | 설명 | 명령어 예시 |
|------|--------|------|-------------|
| 1 | 클라우드 엔지니어 | VM SSH 접속 | `ssh -i key.pem ubuntu@VM_IP` |
| 2 | 클라우드 엔지니어 | 백업 및 로그 확인 | `cp *.jar *.jar.bak`, `tail -n 100 *.log` |
| 3 | 클라우드 엔지니어 | 백엔드 빌드 | `cd mock_backend && ./gradlew clean build -x test` |
| 3-1 | 클라우드 엔지니어 | React 빌드 및 배포 | `cd mock_frontend && npm run build && cp -r dist/* /var/www/react` |
| 4 | 클라우드 엔지니어 | 백엔드 실행 | `nohup java -jar build/libs/*.jar > ~/backend.log 2>&1 &` |
| 5 | 클라우드 엔지니어 | FastAPI 실행 | `systemctl restart fastapi`, `curl localhost:8000/ai/hello` |
| 5-1 | 클라우드 엔지니어 | FastAPI 롤백 준비 | `cp -r /home/ubuntu/mock_fastapi /home/ubuntu/mock_fastapi.bak` |
| 6 | 클라우드 엔지니어 | nginx 설정 반영 | `nginx -t && systemctl reload nginx` |
| 7 | QA | 통합 확인 | `curl https://test.moongsan.com/api/hello` 등 |
| 8 | 전원 | 장애 발생 시 대응 | `/home/ubuntu/rollback.sh` 실행 (추후 작성 필요) |

---

### 추가 사항: Frontend / FastAPI

- **React**는 Vite 기반 정적 파일로 구성되어 있으므로, `/var/www/react` 디렉토리 전체를 `.bak`으로 복사하여 롤백할 수 있습니다.
- **FastAPI**는 `systemd` 서비스로 관리되며, 포트 충돌 등의 장애가 있을 경우 `rollback_ai.sh` 스크립트를 통해 `/home/ubuntu/mock_fastapi`를 롤백합니다.
- 두 서비스 모두 `curl`을 활용한 헬스체크 후 백업을 수행합니다:
  - `curl -sf https://test.moongsan.com` → React
  - `curl -sf http://localhost:8000/ai/hello` → FastAPI

---

## 참고 사항
- 모든 로그는 `/home/ubuntu/*.log`에 저장되며, 수동으로 모니터링해야 함
- 시스템 종료 또는 배포 실패 시 재기동은 *자동이 아님*
- 모든 배포 이후 결과는 `curl` 또는 `log` 기준으로 수동 확인함
