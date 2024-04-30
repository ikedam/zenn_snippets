# DockerイメージでLambaを作成するTerraformテンプレート
# IAMロールなど、直接骨子に関係ないものはmain_extra.tfにおいています。
terraform {
  required_version = "~> 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.41.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.4.2"
    }
    # https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "aws" {
}

data "aws_ecr_authorization_token" "token" {
}

# https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs#registry-credentials
provider "docker" {
  registry_auth {
    address  = data.aws_ecr_authorization_token.token.proxy_endpoint
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
  }
}

resource "aws_ecr_repository" "image_repository" {
  name                 = replace(var.basename, "-", "_")
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "remove_untagged" {
  repository = aws_ecr_repository.image_repository.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged in 1 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# イメージのリビルド判定用
data "archive_file" "lambda" {
  type        = "zip"
  output_path = "${path.module}/lambda.zip"
  source_dir  = "${path.module}/lambda"
  # .dockerignore 相当の指定を行う。
  excludes = setunion(
    fileset("${path.module}/lambda", ".devcontainer/**/*"),
    fileset("${path.module}/lambda", ".github/**/*"),
    fileset("${path.module}/lambda", ".gitignore"),
  )
}

resource "docker_image" "lambda" {
  name         = "${aws_ecr_repository.image_repository.repository_url}:latest"
  platform     = "linix/amd64"
  keep_locally = true
  build {
    context = "${path.module}/lambda"
  }
  triggers = {
    sha256 = data.archive_file.lambda.output_sha256
  }
}

resource "docker_registry_image" "lambda" {
  name          = docker_image.lambda.name
  keep_remotely = true

  triggers = {
    sha256 = data.archive_file.lambda.output_sha256
  }
}

locals {
  repo_image_url = "${aws_ecr_repository.image_repository.repository_url}@${docker_registry_image.lambda.sha256_digest}"
  # Lambda、IAMロール、CloudWatchロググループで循環参照しないように
  # 一旦ローカル変数で定義
  function_name = "${var.basename}-function"
}

resource "aws_lambda_function" "lambda" {
  function_name = local.function_name
  role          = aws_iam_role.lambda.arn

  package_type = "Image"
  image_uri    = local.repo_image_url
  publish      = true
}

resource "aws_api_gateway_rest_api" "api" {
  name = "${var.basename}-api"

  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = var.basename
      version = "1.0"
    }
    paths = {
      "/" = {
        get = {
          x-amazon-apigateway-integration = {
            type                 = "AWS_PROXY"
            uri                  = aws_lambda_function.lambda.invoke_arn
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
          }
        }
      }
    }
  })
}

resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "prod"
}
