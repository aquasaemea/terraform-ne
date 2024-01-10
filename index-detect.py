import boto3

def handler(event, context):
    # Get the S3 bucket and key (object key) from the event
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']

    # Create an S3 client
    s3 = boto3.client('s3')

    # Download the file from S3
    local_file_path = '/tmp/' + key
    s3.download_file(bucket, key, local_file_path)

    # Read and print the content of the file
    with open(local_file_path, 'r') as file:
        file_content = file.read()
        print("Content of testscript.sh:")
        print(file_content)

    return {
        'statusCode': 200,
        'body': 'Processing complete'
    }

