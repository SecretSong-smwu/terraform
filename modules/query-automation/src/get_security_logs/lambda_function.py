"""
GetSecurityLogs-secretsong (v2 - A1Producer 데이터 계약 반영)

변경점:
1. S3 raw/auth.log 직접 파싱 방식 폐기
2. A1Producer가 저장하는 DynamoDB LOG_TABLE을 조회하는 방식으로 전환
3. 최신순 정렬 후 limit 개수만큼 반환 (기본 20건)

주의: priority는 문자열(HIGH/MEDIUM/LOW), action은 ALLOW/DENY로 저장됨
      (구버전 숫자 priority, alert action 계약과 다름)
"""

import json
import os
import boto3
from boto3.dynamodb.conditions import Attr

REGION = os.environ.get("AWS_REGION", "ap-northeast-2")
LOG_TABLE = os.environ["LOG_TABLE"]  # A1Producer와 동일한 환경변수명으로 맞출 것

dynamodb = boto3.resource("dynamodb", region_name=REGION)
log_table = dynamodb.Table(LOG_TABLE)


def lambda_handler(event, context):
    params = event.get("queryStringParameters") or event.get("params") or {}
    limit = int(params.get("limit", 20))
    src_ip_filter = params.get("src_ip")
    priority_filter = params.get("priority")

    try:
        scan_kwargs = {}

        filters = []
        if src_ip_filter:
            filters.append(Attr("src_ip").eq(src_ip_filter))
        if priority_filter:
            filters.append(Attr("priority").eq(priority_filter))

        if filters:
            combined = filters[0]
            for f in filters[1:]:
                combined = combined & f
            scan_kwargs["FilterExpression"] = combined

        resp = log_table.scan(**scan_kwargs)
        items = resp.get("Items", [])

        while "LastEvaluatedKey" in resp and len(items) < 1000:
            scan_kwargs["ExclusiveStartKey"] = resp["LastEvaluatedKey"]
            resp = log_table.scan(**scan_kwargs)
            items.extend(resp.get("Items", []))

        items.sort(key=lambda x: x.get("timestamp", ""), reverse=True)
        items = items[:limit]

        return {
            "statusCode": 200,
            "count": len(items),
            "logs": items,
        }

    except Exception as e:
        return {"statusCode": 500, "error": str(e)}
