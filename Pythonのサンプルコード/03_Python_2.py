# ●患者2のコード（Python + PostgreSQL）

# PostgreSQLへ接続するドライバとしてpsycopg2を使用しています
# 下記サイトよりドライバの最新版をダウンロードしてインストールしてください
# https://pypi.org/project/psycopg2/

from os import getenv
import psycopg2
from psycopg2.extensions import connection

# 1) データベースへの接続情報 */
strCon = "host=localhost dbname=shop user=postgres password=test"

# 2) 変数の初期化
strOldCustomer = ""
strCurCustomer = ""
intPrice = 0

intCurSeq = 0  
intOldSeq = 0  


# 3) PostgreSQLへの接続 */
connection = psycopg2.connect(strCon)
cursor = connection.cursor()

# 4) SELECT文の実行 */
cursor.execute('SELECT * FROM Receipts ORDER BY customer_id, seq, price')
result=cursor.fetchall()

# 5) ヘッダの表示 */
strHeader = "customer_id| seq | price   "
print(strHeader);
print("-----------+-----+---------");

# 6) 結果セットを一行づつループ */
for row in result:

    strCurCustomer = row[0]

    # 7) 顧客IDが変わったら、最小の連番を出力
    if strOldCustomer != strCurCustomer:

        # 8) 各列の更新 */
        intCurSeq =  row[1]
        intPrice = row[2]

        # 9) 結果の画面表示 */
        strResult =  strCurCustomer + "       |" + format(intCurSeq, "3") + "  |   " + format(intPrice, "6")
        print(strResult);

    strOldCustomer = strCurCustomer;


# 10) データベースとの接続を切断
cursor.close()
connection.close()
