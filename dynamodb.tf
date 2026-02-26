module "authors_table_label" {
  source    = "cloudposse/label/null"
  version   = "0.25.0"
  namespace = "lab"
  stage     = "dev"
  name      = "authors"
}

resource "aws_dynamodb_table" "authors" {
  name         = module.authors_table_label.id
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

module "courses_table_label" {
  source    = "cloudposse/label/null"
  version   = "0.25.0"
  namespace = "lab"
  stage     = "dev"
  name      = "courses"
}

resource "aws_dynamodb_table" "courses" {
  name         = module.courses_table_label.id
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}