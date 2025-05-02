#!/bin/bash

TARGET_DIR="/var/www/react"
BACKUP_DIR="/var/www/react.bak"
NGINX_LOG="/var/log/nginx/error.log"
HEALTH_CHECK_URL="https://test.moongsan.com"

echo "[FRONTEND ROLLBACK] 기존 정적 파일 제거 중..."
sudo rm -rf "$TARGET_DIR" || {
  echo "[ERROR] 기존 정적 파일 제거 실패"
  exit 1
}

echo "[FRONTEND ROLLBACK] 백업에서 복구 중..."
if [ -d "$BACKUP_DIR" ]; then
  sudo cp -r "$BACKUP_DIR" "$TARGET_DIR" || {
    echo "[ERROR] 복사 실패"
    exit 1
  }
else
  echo "[ERROR] 백업 디렉토리가 존재하지 않음"
  exit 1
fi

echo "[FRONTEND ROLLBACK] nginx 리로드 중..."
sudo systemctl reload nginx || {
  echo "[ERROR] nginx 리로드 실패. 로그 확인 필요: $NGINX_LOG"
  exit 1
}

echo "[FRONTEND ROLLBACK] 헬스 체크 수행 중..."
if curl -sSf "$HEALTH_CHECK_URL" | grep -q '<div id="root">'; then
  echo "[OK] 헬스 체크 통과: 프론트엔드 정상 복구됨"
else
  echo "[WARN] 헬스 체크 실패. 브라우저에서 수동 확인 요망"
  exit 1
fi

echo "[FRONTEND ROLLBACK] 완료"