# SageMaker Canvas Auto Shutdown Terraform

This repository contains Terraform templates, which can be deployed to an AWS account to enable automatic shutdown on idle for SageMaker Canvas applications.

The functionality for Canvas Auto Shutdown in this repository is for all SageMaker Canvas apps, on all user profiles, on all SageMaker domains.

## Architecture description
![architecture diagram](/canvas_auto_shutdown.png "canvas auto shutdown").

To enable auto-shutdown, Terraform will deploy resources consisting of an AWS Lambda function triggered by a CloudWatch alarm on the TimeSinceLastActive metric. The Lambda function will stop the SageMaker Canvas app when invoked by the Amazon CloudWatch alarm after a configurable idle timeout threshold is exceeded. This will allow us to automatically shut down idle Canvas apps to avoid incurring unnecessary charges.

## Deployment

### Prerequisites
- An AWS account.
- An IAM user with administrative access.
- AWS CLI. Check [this guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) for up to date instructions to install AWS CLI.
- Terraform CLI. Check [this guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) for up to date instructions to install Terafrom for Amazon Linux.
- You must establish how the AWS CLI authenticates with AWS when you deploy this solution. To configure credentials for programmatic access for the AWS CLI, choose one of the options from [this guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-authentication.html)

### Deployment Steps
Clone this repository and navigate to the terraform-sagemaker-canvas-auto-shutdown folder.

In terminal, run the following terraform commands:

```
terraform init
```
You should see a success message like:
```
Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```
Now you can run:
```
terraform plan
```
After you are satisfied with the resources the plan outlines to be created, you can run:
```
terraform apply
```
Enter “yes“ when prompted to confirm the deployment. 

If successfully deployed, you should see an output that looks like:
```
Apply complete! Resources: X added, 0 changed, 0 destroyed.
```

## Cleaning up
Run the following command to clean up your resources
```
terraform destroy
```


