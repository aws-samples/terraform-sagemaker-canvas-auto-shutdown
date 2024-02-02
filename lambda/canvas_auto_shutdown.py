import boto3
from botocore.config import Config
import os
import datetime

def lambda_handler(event, context):
    region = event['region']

    try:
        config = Config(region_name=region)
        cloudwatch = boto3.client('cloudwatch', config=config)
        sagemaker = boto3.client('sagemaker', config=config)
        # Check which user is in timeout
        metric_data_results = cloudwatch.get_metric_data(
          MetricDataQueries=[
              {
                  "Id": "q1",
                  "Expression": 'SELECT AVG(TimeSinceLastActive) FROM "/aws/sagemaker/Canvas/AppActivity" GROUP BY DomainId, UserProfileName',
                  "Period": int(os.environ['ALARM_PERIOD'])
              }
          ],
          StartTime=datetime.datetime(2023, 10, 20),
          EndTime=datetime.datetime.now(),
          ScanBy='TimestampAscending'
        )
        for metric in metric_data_results['MetricDataResults']:
            domain_id, user_profile_name = metric['Label'].split(' ')
            latest_value = metric['Values'][-1]
            if latest_value >= int(os.environ['TIMEOUT_THRESHOLD']):
                print(f"Canvas App for {user_profile_name} in domain {domain_id} will be deleted.")
                response = sagemaker.delete_app(
                    DomainId=domain_id,
                    UserProfileName=user_profile_name,
                    AppType='Canvas',
                    AppName='default'
                    )
    except Exception as e:
        print(str(e))
        raise e