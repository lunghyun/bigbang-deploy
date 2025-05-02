#!/bin/bash

JAR_DIR="/home/ubuntu/mock_backend/build/libs"
APP_NAME="mock_backend-0.0.1-SNAPSHOT"
LOG_PATH="/home/ubuntu/backend.log"

echo "[ROLLBACK] 기존 프로세스 종료 중..."
sudo pkill -f $APP_NAME || echo "[INFO] 실행 중인 프로세스 없음"

echo "[ROLLBACK] 백업된 jar로 복구 중..."
if sudo mv "$JAR_DIR/$APP_NAME.jar.bak" "$JAR_DIR/$APP_NAME.jar"; then
  echo "[OK] 복구 완료"
else
  echo "[ERROR] 복구 실패! 백엔드 실행 중단됨."
  exit 1
fi

echo "[ROLLBACK] 애플리케이션 재시작 중..."
nohup java -jar "$JAR_DIR/$APP_NAME.jar" > "$LOG_PATH" 2>&1 &

echo "[ROLLBACK] 완료. 로그: $LOG_PATH"