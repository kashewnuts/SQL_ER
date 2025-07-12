# ●患者3のコード（Python + PostgreSQL）

# PostgreSQLへ接続するドライバとしてpsycopg2を使用しています
# 下記サイトよりドライバの最新版をダウンロードしてインストールしてください
# https://pypi.org/project/psycopg2/

from os import getenv
import psycopg2
from psycopg2.extensions import connection

# 1) データベースへの接続情報 */
strCon = "host=localhost dbname=shop user=postgres password=test"

# 2) 変数の初期化
strResult = ""
strUpdate = ""

strOldTicker = ""
strCurTicker = ""
intOldPrice = 0
intCurPrice = 0
intTrend = 0

# 3) PostgreSQLへの接続 */
connection = psycopg2.connect(strCon)
cursor = connection.cursor()

# 4) SELECT文の実行 */
cursor.execute("SELECT * FROM StockHistory ORDER BY ticker_symbol, sale_date")
result=cursor.fetchall()

# 5) 結果セットを一行づつループ */
for row in result:

    # 6) 現在の企業を取得 */
    strCurTicker = row[0]
    intCurPrice = row[2]

    # 7) 企業が同じ場合は株価を比較してtrendを計算 */
    if strOldTicker == strCurTicker:
        if intCurPrice > intOldPrice:
                intTrend = 1
        elif intOldPrice == intCurPrice:
                intTrend = 0
        else:
                intTrend = -1 
    else:
        intTrend = 0

    # 8) UPDATE文を実行 
    strUpdate = "UPDATE StockHistory " +  "SET trend = " + str(intTrend) + " " + "WHERE ticker_symbol = '" + row[0] + "' " + "AND sale_date = '" + str(row[1]) + "'"

    cursor.execute(strUpdate)

    # 9) コミット
    connection.commit()

    intOldPrice = intCurPrice;
    strOldTicker = strCurTicker;

# 10) データベースとの接続を切断
cursor.close()
connection.close()
