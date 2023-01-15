import json
import os
import urllib.request
import boto3
import logging
import random

logger = logging.getLogger()
logger.setLevel(logging.INFO)

LINE_CHANNEL_ACCESS_TOKEN   = os.environ['LINE_CHANNEL_ACCESS_TOKEN']
CLOUDFRONT_DISTRIBUTION_URL = os.environ['CLOUDFRONT_DISTRIBUTION_URL']
REPLY_URL = os.environ['REPLY_URL']
KIMYAS_PROFILE_URL= os.environ['KIMYAS_PROFILE_URL']

def lambda_handler(event, context):
    for message_event in json.loads(event['body'])['events']:
        #イベントからユーザーの入力文字列を取得
        input_word = message_event['message']['text'] # ここでのエラーはAPIGatewayで弾く
        logger.info([input_word,message_event['source']['userId']])

        # dynamoDBからデータ取得し、タプルで変数に格納
        data_tuple = get_data_from_dynamoDB(input_word)
        
        # headerとbodyの必要事項はLINEの公式ドキュメントで定義されている
        headers = {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + LINE_CHANNEL_ACCESS_TOKEN # Bearerの直後には空白が必要（仕様）
        }
        body = {
            'replyToken': message_event['replyToken'],
            'messages': [
                {
                    "type": "template",
                    "altText": data_tuple[4],
                    "template": {
                      "type": "buttons",
                      "thumbnailImageUrl": data_tuple[0],
                      "imageAspectRatio": "square",
                      "imageSize": "contain",
                      "imageBackgroundColor": "#FFFFFF",
                      "title": data_tuple[3] + "-" + data_tuple[4],
                      "text": data_tuple[1],
                      "defaultAction": {
                          "type": "uri",
                          "label": "詳細ページ",
                          "uri": data_tuple[2]
                      },
                      "actions": [
                          {
                            "type": "uri",
                            "label": "もっと詳しく！",
                            "uri": data_tuple[2]
                          },
                          {
                            "type": "message",
                            "label": data_tuple[5] + "を調べてみる",
                            "text": data_tuple[5]
                          },
                          {
                            "type": "uri",
                            "label": "このBotの開発者について",
                            "uri": KIMYAS_PROFILE_URL
                          }
                      ]
                    }
                }
            ]
        }
        
        req = urllib.request.Request(REPLY_URL, data=json.dumps(body).encode('utf-8'), method='POST', headers=headers) # HTTPリクエストを作成
        with urllib.request.urlopen(req) as res: # 引数のreq(URL)をオープン(=HTTPリクエストを実行)。返り値resには、HTTPResponseクラスのオブジェクトが返送される。
            logger.info(res.read().decode("utf-8")) # 成功ならステータスコード200と空のJSONオブジェクト{}が返ってくる(LINEドキュメントより)

    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }
    
def get_data_from_dynamoDB(input_word):
    dynamoDB = boto3.resource('dynamodb')
    table = dynamoDB.Table('yoyo_pokemon_test')
    # targetが見つからなかった時のエラーハンドリング
    try:
        target_item = table.get_item(Key={'PokemonName': input_word})['Item']
    except Exception as e:
        random_num = random.randrange(1,9,1)# 1-9のランダムな整数を生成
        target_item = table.get_item(Key={'PokemonName': "けつばん"+str(random_num)})['Item'] #けつばん1~9（クラウン）が検索されたことにする
    # 通常処理
    s3_url = CLOUDFRONT_DISTRIBUTION_URL + target_item['S3ObjectName']
    yoyo_maker = target_item['YoyoMaker']
    yoyo_item = target_item['YoyoItem']
    comment = target_item['Comment']
    rewind_url = target_item['RewindURL']
    next_pokemon = target_item['NextPokemon']
    
    return(s3_url, comment, rewind_url, yoyo_maker, yoyo_item, next_pokemon)# 要素の順番を替える場合は、メイン処理のタプル順も編集すること

    