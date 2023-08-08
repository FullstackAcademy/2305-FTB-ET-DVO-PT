provider "aws" {
  region = "us-east-1"
}

resource "aws_codecommit_repository" "myrepo" {
  repository_name = "MyDemoRepo"
  description     = "This is the Demo App Repository"
}

resource "aws_security_group" "permit_webr" {
  name        = "Web Security Group"
  description = "Enable HTTP access"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Permit Web Requests"
  }
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "single-instance"

  ami                         = var.ec2_ami
  instance_type               = "t2.micro"
  monitoring                  = false
  vpc_security_group_ids      = [aws_security_group.permit_webr.id]
  subnet_id                   = var.subnet_id
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  tags = {
    Name      = "MyCodePipelineDemo"
    Terraform = "true"
  }
}

resource "aws_codedeploy_app" "mycodedeploy" {
  compute_platform = "Server"
  name             = "MyDemoApplication"
}

resource "aws_codedeploy_deployment_group" "mydeploymentgroup" {
  app_name              = aws_codedeploy_app.mycodedeploy.name
  deployment_group_name = "MyDemoDeploymentGroup"
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  deployment_style {
    deployment_type = "IN_PLACE"
  }

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "MyCodePipelineDemo"
    }
  }
}

resource "aws_codepipeline" "codepipeline" {
  name     = "MyFirstPipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName       = "MyDemoRepo"
        BranchName           = "master"
        PollForSourceChanges = false
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ApplicationName     = "MyDemoApplication"
        DeploymentGroupName = "MyDemoDeploymentGroup"
      }
    }
  }
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "my-cicd-demo-bucket-aws-fsa"
  force_destroy = true
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline_policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = file("policy_doc.json")
}