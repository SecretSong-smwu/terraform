import json
import base64
import boto3

sfn = boto3.client('stepfunctions', region_name='ap-northeast-2')

def lambda_handler(event, context):
    params = event.get("queryStringParameters", {}) or {}
    token_raw = params.get("token")
    path = event.get("path", "") or event.get("resource", "")

    if not token_raw:
        return {"statusCode": 400, "body": "토큰이 없습니다."}

    token = base64.b64decode(token_raw).decode("utf-8")

    try:
        if "reject" in path:
            sfn.send_task_failure(
                taskToken=token,
                error="ApprovalRejected",
                cause="담당자가 차단을 거부했습니다."
            )
            return {"statusCode": 200, "body": "거부 처리되었습니다."}
        else:
            sfn.send_task_success(taskToken=token, output=json.dumps({"approved": True}))
            return {"statusCode": 200, "body": "승인되었습니다. IP 차단이 진행됩니다."}
    except Exception as e:
        return {"statusCode": 500, "body": f"오류: {str(e)}"}
