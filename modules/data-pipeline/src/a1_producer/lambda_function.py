"""
A1Producer-secret (v2 - 팀 데이터 계약 반영)
"""

import json
import os
import re
import time
import uuid
from datetime import datetime, timezone
import boto3
from botocore.exceptions import ClientError

STREAM_NAME = os.environ["STREAM_NAME"]
OFFSET_TABLE = os.environ["OFFSET_TABLE"]
LOG_TABLE = os.environ["LOG_TABLE"]
LOG_BUCKET = os.environ["LOG_BUCKET"]
LOG_KEY = os.environ["LOG_KEY"]
BATCH_SIZE = int(os.environ.get("BATCH_SIZE", "10"))
REGION = os.environ.get("AWS_REGION", "ap-northeast-2")

s3 = boto3.client("s3", region_name=REGION)
kinesis = boto3.client("kinesis", region_name=REGION)
dynamodb = boto3.resource("dynamodb", region_name=REGION)
offset_table = dynamodb.Table(OFFSET_TABLE)
log_table = dynamodb.Table(LOG_TABLE)

OFFSET_KEY = {"pk": "auth_log_offset"}

LOG_PATTERN = re.compile(
    r"Invalid user\s+(?P<username>\S+)\s+from\s+(?P<src_ip>[\d.]+)"
)


def get_offset() -> int:
    try:
        resp = offset_table.get_item(Key=OFFSET_KEY)
        return int(resp.get("Item", {}).get("line_offset", 0))
    except ClientError as e:
        print(f"offset 조회 실패, 0부터 시작: {e}")
        return 0


def save_offset(new_offset: int):
    offset_table.put_item(Item={**OFFSET_KEY, "line_offset": new_offset, "updated_at": int(time.time())})


def normalize(line: str):
    m = LOG_PATTERN.search(line)
    if not m:
        return None

    src_ip = m.group("src_ip")
    username = m.group("username")
    now_iso = datetime.now(timezone.utc).isoformat()

    signature = "SSH Invalid User Scan"
    action = "DENY"
    priority = "MEDIUM"
    description = f"존재하지 않는 계정 '{username}'으로 {src_ip}에서 SSH 로그인 시도"

    return {
        "log_id": f"{now_iso}_{uuid.uuid4().hex[:6]}",
        "src_ip": src_ip,
        "signature": signature,
        "priority": priority,
        "action": action,
        "timestamp": now_iso,
        "description": description,
    }


def lambda_handler(event, context):
    offset = get_offset()

    obj = s3.get_object(Bucket=LOG_BUCKET, Key=LOG_KEY)
    lines = obj["Body"].read().decode("utf-8").splitlines()
    total_lines = len(lines)

    if offset >= total_lines:
        print("전체 로그를 다 읽었습니다. offset을 0으로 되돌려 반복 재생합니다.")
        offset = 0

    batch = lines[offset: offset + BATCH_SIZE]

    records = []
    for line in batch:
        item = normalize(line)
        if item is None:
            continue
        records.append(item)

    sent = 0
    for item in records:
        log_table.put_item(Item=item)
        kinesis.put_record(
            StreamName=STREAM_NAME,
            Data=json.dumps(item, ensure_ascii=False).encode("utf-8"),
            PartitionKey=item["src_ip"],
        )
        sent += 1

    new_offset = offset + len(batch)
    save_offset(new_offset)

    print(f"{sent}건 전송 (offset {offset} -> {new_offset} / 전체 {total_lines}줄)")

    return {"statusCode": 200, "sent": sent, "offset": new_offset, "total_lines": total_lines}
