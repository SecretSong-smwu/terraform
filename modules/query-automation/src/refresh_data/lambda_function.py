import json, boto3

lambda_client = boto3.client('lambda', region_name='ap-northeast-2')
PRODUCER_FUNCTION = 'A1Producer-secret'

def lambda_handler(event, context):
    """
    사용자가 '데이터 갱신해줘' 요청 시 Producer 수동 트리거
    """
    try:
        response = lambda_client.invoke(
            FunctionName=PRODUCER_FUNCTION,
            InvocationType='Event'
        )

        return {
            "status": "triggered",
            "message": "데이터 수집을 시작했습니다. 약 10초 후 새 로그가 쌓입니다.",
            "producer": PRODUCER_FUNCTION
        }

    except Exception as e:
        return {"error": str(e)}
