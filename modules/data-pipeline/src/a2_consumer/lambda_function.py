"""
A2Consumer-secret
"""

import base64
import json
import os
import time
from datetime import datetime, timezone
import boto3
from botocore.exceptions import ClientError

COUNTER_TABLE = os.environ["COUNTER_TABLE"]
ANALYZED_BUCKET = os.environ["ANALYZED_BUCKET"]
ANALYZED_PREFIX = os.environ.get("ANALYZED_PREFIX", "analyzed")
WINDOW_SECONDS = int(os.environ.get("WINDOW_SECONDS", "300"))
REGION = os.environ.get("AWS_REGION", "ap-northeast-2")
USE_COMPREHEND = os.environ.get("USE_COMPREHEND", "true").lower() == "true"

dynamodb = boto3.resource("dynamodb", region_name=REGION)
counter_table = dynamodb.Table(COUNTER_TABLE)
s3 = boto3.client("s3", region_name=REGION)
comprehend = boto3.client("comprehend", region_name=REGION)


def update_counter(src_ip: str) -> int:
    now = int(time.time())
    try:
        resp = counter_table.get_item(Key={"src_ip": src_ip})
        item = resp.get("Item")
    except ClientError as e:
        print(f"카운터 조회 실패: {e}")
        item = None

    if item and (now - int(item.get("last_seen", 0))) <= WINDOW_SECONDS:
        new_count = int(item.get("fail_count", 0)) + 1
    else:
        new_count = 1

    counter_table.put_item(Item={
        "src_ip": src_ip,
        "fail_count": new_count,
        "last_seen": now,
    })
    return new_count


def score_risk(count: int) -> str:
    if count >= 5:
        return "HIGH"
    if count >= 2:
        return "MEDIUM"
    return "LOW"


def extract_keywords(description: str):
    if not USE_COMPREHEND or not description:
        return []
    try:
        resp = comprehend.detect_key_phrases(Text=description, LanguageCode="ko")
        return [kp["Text"] for kp in resp.get("KeyPhrases", [])][:5]
    except ClientError as e:
        print(f"Comprehend 호출 실패(무시하고 계속): {e}")
        return []


def build_recommendation(risk_level: str) -> str:
    return {
        "HIGH": "즉시 IP 차단 검토 필요",
        "MEDIUM": "모니터링 강화, 반복 시 차단 검토",
        "LOW": "특이사항 없음, 로그만 기록",
    }.get(risk_level, "특이사항 없음")


def lambda_handler(event, context):
    processed = 0

    for record in event.get("Records", []):
        try:
            payload = base64.b64decode(record["kinesis"]["data"])
            item = json.loads(payload)
        except (KeyError, json.JSONDecodeError) as e:
            print(f"레코드 파싱 실패, 건너뜀: {e}")
            continue

        src_ip = item.get("src_ip")
        signature = item.get("signature", "")
        description = item.get("description", "")
        if not src_ip:
            continue

        count = update_counter(src_ip)
        risk_level = score_risk(count)
        keywords = extract_keywords(description)

        now_iso = datetime.now(timezone.utc).isoformat()
        analyzed = {
            "src_ip": src_ip,
            "risk_level": risk_level,
            "reason": f"최근 {WINDOW_SECONDS}초 내 {count}회 반복 탐지 ({signature})",
            "recommended_action": build_recommendation(risk_level),
            "warning_text": description,
            "keywords": keywords,
            "occurrence_count": count,
            "timestamp": now_iso,
        }

        key = f"{ANALYZED_PREFIX}/{src_ip}/{now_iso.replace(':', '-')}.json"
        s3.put_object(
            Bucket=ANALYZED_BUCKET,
            Key=key,
            Body=json.dumps(analyzed, ensure_ascii=False).encode("utf-8"),
            ContentType="application/json",
        )
        processed += 1
        print(f"{src_ip} -> {risk_level} (count={count}) 저장 완료: {key}")

    return {"statusCode": 200, "processed": processed}
