resource "aws_cloudwatch_event_rule" "codecommit_rule" {
  name = "codecommit-change"

  event_pattern = jsonencode({
    source = [
      "aws.codecommit"
    ]

    detail-type = [
      "CodeCommit Repository State Change"
    ]

    resources = [
        aws_codecommit_repository.myrepo.arn
    ]

    detail = {
        referenceType = ["branch"],
        referenceName = ["master"]

    }
  })
  role_arn      = aws_iam_role.eventbridge_role.arn
}

resource "aws_cloudwatch_event_target" "codepipeline_target" {
  rule      = aws_cloudwatch_event_rule.codecommit_rule.name
  target_id = "CodePipeline"
  arn       = aws_codepipeline.codepipeline.arn
  role_arn = aws_iam_role.eventbridge_role.arn
}

data "aws_iam_policy_document" "event_policy" {
  statement {
    effect    = "Allow"
    actions   = ["codepipeline:StartPipelineExecution"]
    resources = [aws_codepipeline.codepipeline.arn]
  }
}

data "aws_iam_policy_document" "events_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eventbridge_role" {
  name               = "eventbridge-role"
  assume_role_policy = data.aws_iam_policy_document.events_assume_role.json
}

resource "aws_iam_role_policy" "eb_policy" {
  name = "eb_policy"
  role = aws_iam_role.eventbridge_role.id
  policy = data.aws_iam_policy_document.event_policy.json
}