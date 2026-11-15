#!/bin/bash

# --- Configuration ---
SERVER_DIR="/home/ubuntu/minecraft-server"
BACKUP_DIR="/home/ubuntu/minecraft-backups"
S3_BUCKET="s3://mc-server-backups-aey-2026"
SCREEN_NAME="mc"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="mc-backup-${TIMESTAMP}.tar.gz"

echo "[$(date)] Starting Minecraft server backup..."

# 1. แจ้งเตือนในเกมและปิดการเขียนดิสก์ชั่วคราว (ป้องกันไฟล์ World พัง)
screen -S "$SCREEN_NAME" -p 0 -X stuff "say [Backup] Starting world backup...^M"
screen -S "$SCREEN_NAME" -p 0 -X stuff "save-off^M"
screen -S "$SCREEN_NAME" -p 0 -X stuff "save-all^M"

# รอ 5 วินาทีให้ตัวเกมเขียนข้อมูลทั้งหมดลงดิสก์จนเสร็จ
sleep 5

# 2. บีบอัดโฟลเดอร์ World ทั้งหมดและไฟล์ตั้งค่าสำคัญ
tar -czf "${BACKUP_DIR}/${BACKUP_FILE}" -C "$SERVER_DIR" world world_nether world_the_end server.properties

# 3. เปิดระบบ Auto-Save ของเกมกลับมาทำงานตามปกติ
screen -S "$SCREEN_NAME" -p 0 -X stuff "save-on^M"
screen -S "$SCREEN_NAME" -p 0 -X stuff "say [Backup] Backup completed!^M"

# 4. อัปโหลดไฟล์ขึ้น AWS S3
echo "[$(date)] Uploading ${BACKUP_FILE} to ${S3_BUCKET}..."
aws s3 cp "${BACKUP_DIR}/${BACKUP_FILE}" "${S3_BUCKET}/${BACKUP_FILE}"

# 5. ตรวจสอบผลการอัปโหลดและลบไฟล์ชั่วคราวบน EC2 เพื่อประหยัดพื้นที่ดิสก์
if [ $? -eq 0 ]; then
    echo "[$(date)] Upload successful! Cleaning up local backup file..."
    rm -f "${BACKUP_DIR}/${BACKUP_FILE}"
else
    echo "[$(date)] ERROR: Upload to S3 failed! Keeping local file."
    exit 1
fi

echo "[$(date)] Backup process finished successfully."
