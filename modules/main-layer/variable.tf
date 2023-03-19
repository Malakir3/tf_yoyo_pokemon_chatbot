##########################
# 環境変数
##########################
variable "SystemName" {
  type = string
}

variable "env" {
  type = string
}

variable "region" {
  type = string
}

##########################
# env変数
##########################
variable "retention_in_days" {
  type = number
}

variable "api_id" {
  type = string
}

variable "role_id" {
  type = string
}

variable "parent_api_resource_id" {
  type = string
}

##########################
# common変数
##########################
variable "lambda_envs" {
  type = map(string)
}
