from janome.tokenizer import Tokenizer
from janome.analyzer import Analyzer
from janome.charfilter import *
from janome.tokenfilter import *
from datetime import datetime as dt
import sqlite3 as db
import os.path
import json

from ibm_watson import NaturalLanguageUnderstandingV1
from ibm_cloud_sdk_core.authenticators import IAMAuthenticator
from ibm_watson.natural_language_understanding_v1 \
    import Features, EntitiesOptions, KeywordsOptions,CategoriesOptions

# import pip3 install ibm_watson

ifpath = "./Results.db"
tdatetime = dt.now()
tstr = tdatetime.strftime('%Y%m%d_%H%M%S')

try:
    con = db.connect('Results.db', isolation_level=None)
    # 初回のみテーブル作成
    con.execute("DROP TABLE IF EXISTS Results")
    con.execute("CREATE TABLE IF NOT EXISTS Results (create_date text,sequence_no integer,text_string text)")
    con.execute("INSERT INTO Results VALUES ('201912252200',1,'TEXTSTRING')")
except sqlite3.Error as e:
    print('sqlite3.Error occurred:', e.args[0])

print("typeall")
con.execute("SELECT * FROM Results")


# t = Tokenizer()
t = Tokenizer("userdic.csv", udic_enc="utf8")

# dic format
# 表層形,左文脈ID,右文脈ID,コスト,品詞,品詞細分類1,品詞細分類2,品詞細分類3,活用型,活用形,原形,読み,発音

# just install pip3 install janome

# 以下はJanomeのフィルタ機能のサンプル
# char_filters = [UnicodeNormalizeCharFilter(), RegexReplaceCharFilter(u'蛇の目', u'janome')]
# tokenizer = Tokenizer()
# token_filters = [CompoundNounFilter(), POSStopFilter(['記号','助詞']), LowerCaseFilter()]
# a = Analyzer(char_filters, tokenizer, token_filters)

analyze_text = "OS作業依頼書が欲しいのですが"

malist = t.tokenize(analyze_text)
seqno = 0
save_tstr = tstr
for n in malist:
#    print(n)
    seqno = seqno + 1
    # print(n.surface)
    # print(n.part_of_speech.split(',')[0])
    # print(n.part_of_speech.split(',')[1])

    # SQL実行
    con.execute("insert into Results VALUES (?,?,?)", (save_tstr, seqno, n.surface+","+n.part_of_speech.split(',')[0]+","+n.part_of_speech.split(',')[1]))
con.commit()

print ("select")

# SQL実行
cur = con.cursor()
cur.execute("select * from Results")
results = cur.fetchall()

print(results)

con.close()

# ---------- IBM WATSON CALLING
# WATSON NLUの自然言語抽出機能
#   エンティティ：人々、企業、場所、ランドマーク、組織などを抽出します
#   カテゴリ:テキストの自動分類。https://cloud.ibm.com/docs/services/natural-language-understanding/categories.html#categories-hierarchy
#   感情sentiment：ポジティブかnegativeか
#   構文/セマンティック・ロール。テキストを部分に分割し、名詞、動詞、主題、アクション、オブジェクトなどを識別することによるテキストの言語分析。
#   キーワードkeyword、感情emotion、概念：感情は喜び、怒り、悲しみなどの感情。キーワードは、テキストで重要な単語です。概念は、テキストに表示される場合と表示されない場合がありますが、概念を反映する単語です。
print("[HTTP] begin...\n")

watson_url = "{url}"

api_key = "{apikey}"
watson_version = "2019-07-12"

authenticator = IAMAuthenticator(api_key)
natural_language_understanding = NaturalLanguageUnderstandingV1(
    version='2019-07-12',
    authenticator=authenticator)

natural_language_understanding.set_service_url(watson_url)

response = natural_language_understanding.analyze(
    text=analyze_text,
    languages='ja',
    features=Features(
        categories=CategoriesOptions(limit=5),
        entities=EntitiesOptions(emotion=True, sentiment=True, limit=5),
        keywords=KeywordsOptions(emotion=True, sentiment=True,
                                 limit=2))).get_result()

print(json.dumps(response, indent=2))

