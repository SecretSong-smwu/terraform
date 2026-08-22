import json, boto3

s3_client = boto3.client('s3', region_name='ap-northeast-2')
BUCKET_NAME = 'auth-log-secret-namyoonah'

def lambda_handler(event, context):
    try:
        prefix = 'analyzed/'

        listed = s3_client.list_objects_v2(Bucket=BUCKET_NAME, Prefix=prefix)

        if 'Contents' not in listed or not listed['Contents']:
            return {"message": "아직 분석 결과가 없습니다"}

        latest_file = sorted(listed['Contents'], key=lambda x: x['LastModified'])[-1]

        obj = s3_client.get_object(Bucket=BUCKET_NAME, Key=latest_file['Key'])
        analysis = json.loads(obj['Body'].read().decode('utf-8'))

        return {
            "file": latest_file['Key'],
            "last_modified": latest_file['LastModified'].isoformat(),
            "analysis": analysis,
            "summary": f"최근 분석 결과: 위험도 {analysis.get('risk_level', 'UNKNOWN')}"
        }

    except Exception as e:
        return {"error": str(e)}
