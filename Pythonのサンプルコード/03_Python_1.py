# ●患者1のコード（Python + PostgreSQL）

# PostgreSQLへ接続するドライバとしてpsycopg2を使用しています
# 下記サイトよりドライバの最新版をダウンロードしてインストールしてください
# https://pypi.org/project/psycopg2/

from os import getenv
import psycopg2
from psycopg2.extensions import connection

# 1) データベースへの接続情報 */
strCon = "host=localhost dbname=shop user=postgres password=test"

# 2) 変数の初期化
strOldShop = "";
strCurShop = "";
intCumlative = 0;   # 累計

# 3) PostgreSQLへの接続 */
connection = psycopg2.connect(strCon)
cursor = connection.cursor()

# 4) SELECT文の実行 */
cursor.execute('SELECT * FROM SalesIcecream')
result=cursor.fetchall()

# 5) ヘッダの表示 */
strHeader = " shop_id | sale_date  | sales_amt | cumlative    "
print(strHeader);

# 6) 結果セットを一行づつループ */
for row in result:

    # 7) 累計を加算 */
    intCumlative = intCumlative + row[2]
    strCurShop = row[0]

    # 8) 店舗が異なる場合は累計をリセット */
    if strOldShop != strCurShop:
        intCumlative = row[2];
        print("---------+------------+-----------+----------")

    # 9) 結果の画面表示 */
    strResult =  row[0] + "     |" + str(row[1]) + "  |     " + format(row[2], '06') + "|" + format(intCumlative, '10')
    print(strResult)

    strOldShop = strCurShop

# 10) データベースとの接続を切断
cursor.close()
connection.close()

