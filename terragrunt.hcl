locals {
  # 環境変数
  SystemName = get_env("SYSTEM_NAME", "yoyo-pk")
  region     = get_env("REGION", "ap-northeast-1")
  env        = get_env("TF_ENV", "prd")

  module-name = "${trimprefix(path_relative_to_include(), "exec.d/")}"

  # 環境依存の情報を読込
  common-vars = read_terragrunt_config(find_in_parent_folders("conf.d/common.hcl"))
  env-vars    = read_terragrunt_config(find_in_parent_folders("conf.d/${local.env}.hcl"))
}

## terraformの基本的な設定
generate "base" {
  path      = "base.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.11.0"
    }
  }
}

provider "aws" {
  region  = "${local.region}"
  # assume_role {
  #   role_arn = "arn:aws:iam::${get_aws_account_id()}:role/administrator-access"
  # }
  default_tags {
    tags = {
      "SystemName" = "${local.SystemName}"
      "Env" = "${local.env}"
    }
  }
}
EOF
}

# 状態ファイルの出力先
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket         = "${local.SystemName}-${local.env}-terragruntbackend-${get_aws_account_id()}"
    region         = "${local.region}"
    key            = "${local.module-name}.tfstate"
    encrypt        = true
    dynamodb_table = "${local.SystemName}-${local.env}-terragrunt-backendTable"
  }
}

# 削除しやすいようにキャッシュは一箇所にまとめておく
download_dir = "${get_terragrunt_dir()}/../.terragrunt-cache/${local.module-name}"

## terraformのファイル読み込み
terraform {
  source = "${path_relative_from_include()}/modules//${local.module-name}"
}

## 変数をterraformへ渡す。conf.d内のファイルが増えたら適宜追加する
inputs = merge(
  {
    env        = local.env,
    SystemName = local.SystemName,
    region     = local.region,
  },
  local.common-vars.inputs,
  local.env-vars.inputs,
)