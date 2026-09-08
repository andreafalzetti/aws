locals {
  froststead_state_key            = "froststead/hetzner/production.tfstate"
  froststead_cloudflare_state_key = "froststead/cloudflare/production.tfstate"
  froststead_github_oidc_subject  = "repo:andreafalzetti@2318450/froststead@1359391446:ref:refs/heads/main"
}

data "aws_iam_policy_document" "github_actions_froststead_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.froststead_github_oidc_subject]
    }
  }
}

resource "aws_iam_role" "github_actions_froststead" {
  name               = "github-actions-andreafalzetti-froststead-production"
  description        = "Least-privilege infrastructure and deploy role for FROSTSTEAD"
  assume_role_policy = data.aws_iam_policy_document.github_actions_froststead_trust.json

  max_session_duration = 3600
}

data "aws_iam_policy_document" "github_actions_froststead" {
  statement {
    sid       = "ListStateBucket"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:ListBucket"]
    resources = [aws_s3_bucket.terraform_state.arn]
  }

  statement {
    sid    = "ManageFroststeadState"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.terraform_state.arn}/${local.froststead_state_key}",
      "${aws_s3_bucket.terraform_state.arn}/${local.froststead_cloudflare_state_key}",
    ]
  }

  statement {
    sid    = "ManageFroststeadStateLock"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.terraform_state.arn}/${local.froststead_state_key}.tflock",
      "${aws_s3_bucket.terraform_state.arn}/${local.froststead_cloudflare_state_key}.tflock",
    ]
  }

  statement {
    sid    = "UseStateKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
    ]
    resources = [aws_kms_key.terraform_state.arn]
  }

  statement {
    sid    = "ReadDeploymentSecrets"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
    resources = [
      "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/froststead/production/*",
      "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/platform/production/hetzner/api-token",
    ]
  }

  statement {
    sid     = "DecryptDeploymentSecrets"
    effect  = "Allow"
    actions = ["kms:Decrypt", "kms:DescribeKey"]
    resources = [
      aws_kms_key.terraform_secrets.arn,
    ]
  }
}

resource "aws_iam_role_policy" "github_actions_froststead" {
  name   = "froststead-production"
  role   = aws_iam_role.github_actions_froststead.id
  policy = data.aws_iam_policy_document.github_actions_froststead.json
}
