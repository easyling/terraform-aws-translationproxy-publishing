resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.project}_executor_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "edgelambda.amazonaws.com"
          ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "domain_classifier" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "${path.module}/domain_classifier_lambda.zip"
  function_name = "${var.project}_classifier"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"
  description   = "Add domain classifier for multi-domain publishing via Cloud CDN"

  tags = {
    product = "translationproxy",
    project = var.project,
  }


  publish = true

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("${path.module}/domain_classifier_lambda.zip")

  runtime = "nodejs14.x"
}

output "classifier_arn" {
  value = aws_lambda_function.domain_classifier.qualified_arn
}
