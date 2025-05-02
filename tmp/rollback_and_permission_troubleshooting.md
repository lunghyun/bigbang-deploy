## 백엔드 롤백 및 권한 관련 트러블슈팅

### 롤백 실패로 인한 서비스 중단 이슈

#### 문제 발생 상황
- `rollback.sh` 실행 중 `.jar.bak` → `.jar` 복사 실패
- 그럼에도 백엔드 재시작 진행 → 실행할 파일이 없거나 잘못됨 → **서비스 중단 발생**

#### 원인 분석
- `mv` 명령 실패 여부를 확인하지 않음
- 모든 명령어가 직렬로 실행되어 중간 실패가 전체 중단을 유발

#### 개선 방향
- `mv` 복구 성공 여부를 조건문으로 감지
- 실패 시 즉시 `exit 1`로 중단하여 재시작 방지

#### 수정 예시

```bash
if mv "$JAR_DIR/$APP_NAME.jar.bak" "$JAR_DIR/$APP_NAME.jar"; then
  echo "[OK] 복구 완료"
else
  echo "[ERROR] 복구 실패! 백엔드 실행 중단됨."
  exit 1
fi
```

### 백엔드 관련 파일 권한 문제

#### 증상
- `.jar` 파일 덮어쓰기 중 `Permission denied`
- `/home/ubuntu/backend.log` 로그 파일 쓰기 실패

#### 원인
- 과거 `sudo`로 실행된 프로세스가 파일을 root 소유로 생성함

#### 해결 명령어

```bash
sudo chown ubuntu:ubuntu /home/ubuntu/mock_backend/build/libs/*.jar*
sudo chown ubuntu:ubuntu /home/ubuntu/backend.log
```

### 예방 수칙
- **항상** `ubuntu` 사용자로 배포 및 롤백 스크립트 실행
- `.jar`, `.log` 등 실행 파일 및 로그의 **소유자 권한을 유지**할 것
- Ansible이나 systemd 사용 시 `User=ubuntu` 설정으로 통일


## 프론트엔드 롤백 및 권한 관련 트러블슈팅

### 롤백 실패로 인한 서비스 중단 이슈

#### 문제 발생 상황
- `/var/www/react` 복사 중 오류 발생 혹은 누락된 `assets/` 디렉토리
- Nginx는 정상적으로 200 응답을 반환하나, 브라우저에서 화면이 비정상적임

#### 원인 분석
- 파일 복사 과정에서 일부 리소스 누락
- `nginx reload`가 누락되어 리소스 변경사항이 반영되지 않음

#### 개선 방향
- 백업 복원 후 Nginx를 **반드시 리로드**
- 리소스 파일(`/assets/index-*.js`)의 정상 반환 여부로 헬스체크 수행

#### 수정 예시 (rollback_frontend.sh)

```bash
if [ -d "$BACKUP_DIR" ]; then
  sudo cp -r "$BACKUP_DIR" "$TARGET_DIR" || {
    echo "[ERROR] 복사 실패"
    exit 1
  }
  sudo systemctl reload nginx
else
  echo "[ERROR] 백업 디렉토리가 존재하지 않음"
  exit 1
fi
```

### 프론트엔드 관련 파일 권한 문제

#### 증상
- `/var/www/react` 또는 `/var/www/react.bak` 디렉토리 권한 문제
- `sudo cp` 이후 `nginx`가 리소스를 제대로 서빙하지 못함

#### 원인
- `sudo`로 복사한 디렉토리의 소유자가 `root`가 됨
- `/var/www` 하위 정적 파일의 읽기 권한 누락

#### 해결 명령어

```bash
sudo chown -R www-data:www-data /var/www/react
sudo chmod -R 755 /var/www/react
```

> 또는, 배포 시 Ansible에서 `owner`, `group`, `mode` 명시

### 예방 수칙
- `nginx`가 읽을 수 있도록 `www-data` 소유권과 755 권한 유지
- 배포 후 `curl`, `grep`, `curl -I` 등으로 리소스 접근 여부 점검
- HTML만 200을 반환해도 JS/CSS가 깨졌을 수 있으므로 **브라우저 확인 병행**


## FastAPI 롤백 및 권한 관련 트러블슈팅

### 롤백 실패로 인한 서비스 중단 이슈

#### 문제 발생 상황
- `rollback_fastapi.sh` 수행 중 복원 실패
- FastAPI 서비스가 정상적으로 재시작되지 않음

#### 원인 분석
- FastAPI는 `nohup` 또는 `systemd` 방식으로 실행되기 때문에 포트 점유 가능성 존재
- 기존 프로세스 종료 없이 재시작 시 충돌 발생 가능

#### 개선 방향
- 롤백 시 실행 중인 포트를 명시적으로 종료
- `.bak` 파일 존재 여부 확인 후 재실행

#### 수정 예시

```bash
# 예: 8000 포트 사용 프로세스 종료
PID=$(lsof -ti tcp:8000)
if [ -n "$PID" ]; then
  kill -9 $PID
  echo "[OK] 기존 FastAPI 프로세스 종료 완료"
fi

if mv "$APP_DIR/$APP_NAME.bak" "$APP_DIR/$APP_NAME"; then
  echo "[OK] 복구 완료"
  nohup uvicorn main:app --host 0.0.0.0 --port 8000 &
else
  echo "[ERROR] 복구 실패! FastAPI 실행 중단됨."
  exit 1
fi
```

### FastAPI 관련 파일 권한 문제

#### 증상
- `.py` 또는 실행 스크립트 권한 문제로 서비스 실행 실패
- 로그 파일 쓰기 권한 부족

#### 원인
- 파일 소유자 및 권한 설정 미흡

#### 해결 명령어

```bash
sudo chown -R ubuntu:ubuntu /home/ubuntu/fastapi_app
sudo chmod -R 755 /home/ubuntu/fastapi_app
```

### 예방 수칙
- `ubuntu` 사용자로 배포 및 실행 권한 유지
- systemd 서비스 파일 내 `User=ubuntu` 설정
- 로그 및 실행 파일 권한 주기적 점검