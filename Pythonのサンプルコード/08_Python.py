# ●集合指向アレルギーとループ依存症の併発（Python + PostgreSQL）
# PostgreSQLへ接続するドライバとしてpsycopg2を使用しています
# 下記サイトよりドライバの最新版をダウンロードしてインストールしてください
# https://pypi.org/project/psycopg2/

from os import getenv
import psycopg2
from psycopg2.extensions import connection

# 1) データベースへの接続情報 
strCon = "host=localhost dbname=shop user=postgres password=test"

          
# 2) 変数の初期化 
strCurDepartment = ""
strOldDepartment = ""

strCheckflg = ""       # 完了または未完 
blCompleted = True     # 完了フラグ 

# 3) PostgreSQLへの接続 */
connection = psycopg2.connect(strCon)
cursor = connection.cursor()


# 4) SELECT文の実行 */
cursor.execute("SELECT * FROM Departments ORDER BY department, division")
result=cursor.fetchall()

# 5) ヘッダの表示 */
strHeader = " department" + "\n" + "-----------" 
print(strHeader)

# 最初の行かどうかを判断するカウンター
rowCnt = 0;

# 6) 結果セットを一行づつループ */
for row in result:

    rowCnt = rowCnt + 1  # 最初の行で1になる

    strCurDepartment = row[0].strip()
    strCheckflg = row[2].strip()


    # 7) 部署が異なる場合（かつ最初の行でない場合）はブレイクしてチェックフラグを確認
    if (strOldDepartment != strCurDepartment) and rowCnt > 1:

        # チェックフラグがtrueなら出力 */
        if blCompleted == True:
            print(strOldDepartment)      # 一行前の部署を出力
        
        # ブレイクしたら完了フラグもtrueで初期化
        blCompleted = True


    # 8) 一つでも未完の課があれば完了フラグをfalseにする */
    if strCheckflg == "未完":
        blCompleted = False

    strOldDepartment = strCurDepartment

# 9) チェックフラグがtrueなら最後の部署を出力 */
if blCompleted == True:
    print(strCurDepartment)    # 現在行の部署を出力
    
# 10) データベースとの接続を切断
cursor.close()
connection.close()
