# 롤백 및 권한 관련 트러블슈팅

---

## 1. 백엔드

### 1.1 롤백 실패로 인한 서비스 중단

#### ❍ 문제 상황
- `rollback.sh` 실행 중 `.jar.bak` → `.jar` 복사 실패
- 그럼에도 백엔드 재시작이 진행되어 실행 파일 누락 → 서비스 중단

#### ❍ 원인
- `mv` 명령 실패 여부 미확인
- 중간 실패에도 다음 단계가 직렬로 실행됨

#### ❍ 개선 방법
```bash
if mv "$JAR_DIR/$APP_NAME.jar.bak" "$JAR_DIR/$APP_NAME.jar"; then
  echo "[OK] 복구 완료"
else
  echo "[ERROR] 복구 실패! 백엔드 실행 중단됨."
  exit 1
fi
```

---

### 1.2 권한 문제

#### ❍ 증상
- `.jar` 덮어쓰기 중 `Permission denied`
- 로그 파일 쓰기 실패

#### ❍ 원인
- 과거 `sudo` 실행으로 `root` 소유 파일 생성

#### ❍ 해결
```bash
sudo chown ubuntu:ubuntu /home/ubuntu/mock_backend/build/libs/*.jar*
sudo chown ubuntu:ubuntu /home/ubuntu/backend.log
```

#### ❍ 예방 수칙
- 항상 `ubuntu` 사용자로 배포 및 롤백 실행
- `.jar`, `.log` 등 실행 파일과 로그는 `ubuntu` 소유 유지
- systemd/Ansible 모두 `User=ubuntu` 설정

---

## 2. 프론트엔드

### 2.1 롤백 실패 및 화면 비정상

#### ❍ 문제 상황
- `/var/www/react` 복사 중 일부 리소스 누락
- Nginx는 200 응답이나 화면이 비정상 표시

#### ❍ 원인
- `assets/` 디렉토리 누락
- `nginx reload` 누락으로 캐시 미반영

#### ❍ 개선 방법
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

---

### 2.2 권한 문제

#### ❍ 증상
- `nginx`가 리소스를 서빙하지 못함

#### ❍ 원인
- `sudo cp`로 복사된 디렉토리가 `root` 소유
- `/var/www` 하위 파일 권한 누락

#### ❍ 해결
```bash
sudo chown -R www-data:www-data /var/www/react
sudo chmod -R 755 /var/www/react
```

#### ❍ 예방 수칙
- `/var/www/react`는 `www-data: 755`로 설정
- curl/grep/브라우저 병행 점검

---

## 3. FastAPI

### 3.1 롤백 실패 및 프로세스 충돌

#### ❍ 문제 상황
- FastAPI 서비스가 포트를 점유한 상태로 재시작 → 충돌

#### ❍ 개선 방법
```bash
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

---

### 3.2 권한 문제

#### ❍ 증상
- `.py` 또는 로그 파일 권한 문제로 실행 실패

#### ❍ 해결
```bash
sudo chown -R ubuntu:ubuntu /home/ubuntu/fastapi_app
sudo chmod -R 755 /home/ubuntu/fastapi_app
```

#### ❍ 예방 수칙
- `ubuntu` 사용자로 실행
- systemd에 `User=ubuntu`
- 권한 주기적 점검