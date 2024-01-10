import boto3
import subprocess

def handler(event, context):
    # Get the S3 bucket and key (object key) from the event
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']

    # Create an S3 client
    s3 = boto3.client('s3')

    # Download the file from S3
    local_file_path = '/tmp/' + key
    s3.download_file(bucket, key, local_file_path)

    # Change permissions and execute the file
    subprocess.run(['chmod', '+x', local_file_path])  # Make the file executable
    result = subprocess.run([local_file_path], capture_output=True, text=True, shell=True)

    # Print the result
    print(result.stdout)

    return {
        'statusCode': 200,
        'body': 'Processing complete'
    }
