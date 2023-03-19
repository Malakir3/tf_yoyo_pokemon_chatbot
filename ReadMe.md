# 概要
好きなポケモンの名前を入力すると、おすすめのヨーヨーを紹介してくれるLINE ChatBotです。
<br>

# Stateファイルの管理
TerraformのStateファイルを格納するS3と、排他制御用のDynamoDBテーブルは、CloudForamationで作成する。  
<br>

# AWS Vault経由での実行方法  
ex) terraform plan
<br>
`$ aws-vault exec YOUR_PROFILE_NAME -- TERRAGRUNT_EXE_PATH plan`  
***
<br>

# 各種フォルダ情報
|フォルダ名|詳細
| ------------------ | ------------------ |
|conf.d|環境ごとの変数情報を格納する。環境差分はこの階層のファイルで吸収する。|
|exec.d|terragruntの実行ファイル群。このフォルダを起点にterragruntが各種モジュールを実行する。|
|module|terraformの各種モジュール群。主コードを記載する。|
***
<br>

# リファレンス
https://zoo200.net/terraform-terragrunt-my-best-practice/
