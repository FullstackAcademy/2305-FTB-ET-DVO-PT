# Enterprise Module 6 CI/CD Terraform Lab Solution

#### This is one possible working solution for the Enterprise Module 6 CI/CD
#### https://docs.aws.amazon.com/codepipeline/latest/userguide/tutorials-simple-codecommit.html

The Terraform files involved are:
- main.tf - outlines and builds the main resources (e.g. CodeCommit repo, CodePipeline pipeline, S3 Bucket, EC2 instance)
- ec2_role.tf - outlines and builds the policies and roles required for the EC2 instance
- codedeploy_role.tf - outlines and builds policies and role required for CodeDeploy service
- eventbridge.tf - outlines and builds the CloudWatch EventBridge rule and associated resources required for monitoring the CodeCommit repository for changes
- policy_doc.json - json document defining the IAM policy for CodePipeline
- variables.tf - defines a couple key variables used in main.tf

### High-level Diagram of Solution
![Untitled Diagram drawio (1)](https://github.com/FullstackAcademy/2305-FTB-ET-DVO-PT/assets/87505099/78880f65-9a9a-44f6-9fd2-9f2acf830f81)
