# Dynamodbテーブル
resource "aws_dynamodb_table" "main" {
  name           = "yoyo_pokemon_test"
  hash_key       = "PokemonName"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  attribute {
    name = "PokemonName"
    type = "S"
  }
  tags = {
    "Name" = "yoyo_pokemon_test"
  }
}