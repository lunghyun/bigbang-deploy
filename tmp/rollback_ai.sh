#!/bin/bash

APP_DIR="/home/ubuntu/mock_fastapi"
BAK_DIR="/home/ubuntu/mock_fastapi.bak"
LOG_PATH="/home/ubuntu/fastapi.log"
SERVICE="fastapi"

echo "[ROLLBACK] FastAPI 기존 프로세스 중지 중..."
sudo systemctl stop $SERVICE

if [ -d "$BAK_DIR" ]; then
  echo "[ROLLBACK] 백업된 디렉토리로 복구 중..."
  sudo rm -rf "$APP_DIR"
  sudo cp -r "$BAK_DIR" "$APP_DIR"
  sudo chown -R ubuntu:ubuntu "$APP_DIR"
else
  echo "[ERROR] 백업 디렉토리가 존재하지 않습니다."
  exit 1
fi

echo "[ROLLBACK] 포트 8000 점유 중인 프로세스 종료 중..."
sudo fuser -k 8000/tcp || true

echo "[ROLLBACK] FastAPI 서비스 재시작 중..."
sudo systemctl restart $SERVICE

echo "[ROLLBACK] 완료. 로그: $LOG_PATH"