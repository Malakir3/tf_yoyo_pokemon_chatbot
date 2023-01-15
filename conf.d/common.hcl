inputs = {
  lambda_envs = {
    "line_channel_access_token"   = get_env("TF_ENV_LINE_CHANNEL_ACCESS_TOKEN"),
    "cloudfront_distribution_url" = get_env("TF_ENV_CLOUDFRONT_DISTRIBUTION_URL"),
    "kimyas_profile_url"          = get_env("TF_ENV_KIMYAS_PROFILE_URL"),
    "reply_url"                   = get_env("TF_ENV_REPLY_URL"),
  },
  api_id                 = get_env("TF_ENV_API_ID"),
  role_id                = get_env("TF_ENV_ROLE_ID"),
  parent_api_resource_id = get_env("TF_ENV_PARENT_API_RESOURCE_ID"),
}