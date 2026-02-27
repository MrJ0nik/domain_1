locals {
  lambdas = {
    get-all-authors = {
      action     = "dynamodb:Scan"
      table      = aws_dynamodb_table.authors.arn
      table_name = aws_dynamodb_table.authors.name
    }
    get-all-courses = {
      action     = "dynamodb:Scan"
      table      = aws_dynamodb_table.courses.arn
      table_name = aws_dynamodb_table.courses.name
    }
    get-course = {
      action     = "dynamodb:GetItem"
      table      = aws_dynamodb_table.courses.arn
      table_name = aws_dynamodb_table.courses.name
    }
    save-course = {
      action     = "dynamodb:PutItem"
      table      = aws_dynamodb_table.courses.arn
      table_name = aws_dynamodb_table.courses.name
    }
    update-course = {
      action     = "dynamodb:PutItem"
      table      = aws_dynamodb_table.courses.arn
      table_name = aws_dynamodb_table.courses.name
    }
    delete-course = {
      action     = "dynamodb:DeleteItem"
      table      = aws_dynamodb_table.courses.arn
      table_name = aws_dynamodb_table.courses.name
    }
  }
}

module "lambda_labels" {
  for_each  = local.lambdas
  source    = "cloudposse/label/null"
  version   = "0.25.0"
  namespace = "lab"
  stage     = "dev"
  name      = each.key
}

resource "aws_iam_role" "lambda_roles" {
  for_each = local.lambdas
  name     = "${module.lambda_labels[each.key].id}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policies" {
  for_each = local.lambdas
  name     = "${module.lambda_labels[each.key].id}-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = each.value.action
        Resource = each.value.table
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attachments" {
  for_each   = local.lambdas
  role       = aws_iam_role.lambda_roles[each.key].name
  policy_arn = aws_iam_policy.lambda_policies[each.key].arn
}
data "archive_file" "lambda_zips" {
  for_each    = local.lambdas
  type        = "zip"
  source_file = "${path.module}/src/${each.key}/index.mjs"
  output_path = "${path.module}/${each.key}.zip"
}

resource "aws_lambda_function" "lambdas" {
  for_each         = local.lambdas
  filename         = data.archive_file.lambda_zips[each.key].output_path
  function_name    = module.lambda_labels[each.key].id
  role             = aws_iam_role.lambda_roles[each.key].arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  source_code_hash = data.archive_file.lambda_zips[each.key].output_base64sha256

  environment {
    variables = {
      TABLE_NAME = each.value.table_name
    }
  }
}