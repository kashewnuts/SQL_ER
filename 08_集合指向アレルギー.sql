
●テーブル定義：アドレス帳
CREATE TABLE Addresses
(name VARCHAR(32) NOT NULL,
 family_id INTEGER NOT NULL,
 address VARCHAR(64) NOT NULL,
   CONSTRAINT pk_Addresses PRIMARY KEY(name));


INSERT INTO Addresses VALUES('前田 義明', '100', '東京都港区虎ノ門3-2-29');
INSERT INTO Addresses VALUES('前田 由美', '100', '東京都港区虎ノ門3-2-92');
INSERT INTO Addresses VALUES('加藤 裕也', '200', '東京都新宿区西新宿2-8-1');
INSERT INTO Addresses VALUES('加藤 勝',   '200', '東京都新宿区西新宿2-8-1');
INSERT INTO Addresses VALUES('ホームズ',  '300', 'ベーカー街221B');
INSERT INTO Addresses VALUES('ワトソン',  '400', 'ベーカー街221B');
INSERT INTO Addresses VALUES('新藤 一郎', '500', '新潟県南魚沼郡湯沢町湯沢2494');
INSERT INTO Addresses VALUES('新藤 次郎', '500', '新潟県南魚沼郡湯沢町湯沢2494');
INSERT INTO Addresses VALUES('新藤 三郎', '500', '新潟県南魚沼郡湯沢町湯沢3494');

●患者のコード：自己結合を使う
SELECT DISTINCT A1.name, A1.address
  FROM Addresses A1 INNER JOIN Addresses A2
    ON A1.family_id = A2.family_id
   AND A1.address <> A2.address ;

●ヘレンの解答：HAVING句を使う
SELECT family_id
  FROM Addresses
 GROUP BY family_id
HAVING MIN(address) <> MAX(address);

●ウィンドウ関数による解
SELECT name, address
  FROM (SELECT name, address,
               MAX(address) OVER(PARTITION BY family_id) max_address,
               MIN(address) OVER(PARTITION BY family_id) min_address
          FROM Addresses) MAX_MIN
 WHERE max_address <> min_address;


●テーブル定義：部署テーブル
CREATE TABLE Departments
(department  CHAR(16) NOT NULL,
 division    CHAR(16) NOT NULL,
 check_flag       CHAR(8)  NOT NULL,
   CONSTRAINT pk_Departments PRIMARY KEY (department, division));

INSERT INTO Departments VALUES ('営業部', '一課', '完了');
INSERT INTO Departments VALUES ('営業部', '二課', '完了');
INSERT INTO Departments VALUES ('営業部', '三課', '未完');
INSERT INTO Departments VALUES ('研究開発部', '基礎理論課', '完了');
INSERT INTO Departments VALUES ('研究開発部', '応用技術課', '完了');
INSERT INTO Departments VALUES ('総務部', '一課', '完了');
INSERT INTO Departments VALUES ('人事部', '採用課', '未完');

⚫ワイリーの答え：その1（間違い）
SELECT DISTINCT department
  FROM Departments
 WHERE check_flag = '完了';


●ワイリーの答え：その2
SELECT department
  FROM Departments D1
 GROUP BY department
HAVING COUNT(*) =  (SELECT COUNT(*)
                      FROM Departments D2
                     WHERE check_flag = '完了'
                       AND D1.department = D2.department
                     GROUP BY department);


●ヘレンの解：CASE式を使う
SELECT department
  FROM Departments
 GROUP BY department
HAVING COUNT(*) = SUM(CASE WHEN check_flag = '完了' 
                           THEN 1 ELSE 0 END);


●ウィンドウ関数による解
SELECT  department, division, check_flag
  FROM (SELECT department, division, check_flag,
	           SUM(CASE WHEN check_flag = '完了' 
	                    THEN 1 ELSE 0 END) OVER DPT completed_cnt,
	           COUNT(*) OVER DPT all_cnt
	      FROM Departments
	      WINDOW DPT AS (PARTITION BY department)) TMP
 WHERE completed_cnt = all_cnt;


●サブクエリの中のウィンドウ関数の値を見てみる
SELECT department,
	   SUM(CASE WHEN check_flag = '完了' 
	            THEN 1 ELSE 0 END) OVER DPT completed_cnt,
	   COUNT(*) OVER DPT all_cnt
  FROM Departments
  WINDOW DPT AS (PARTITION BY department);


●テーブル定義：部署テーブル2
CREATE TABLE Departments2
(department  CHAR(16) NOT NULL,
 division    CHAR(16) NOT NULL,
 check_date  DATE,
   CONSTRAINT pk_Departments2 PRIMARY KEY (department, division));

INSERT INTO Departments2 VALUES ('営業部', '一課', '2024-10-11');
INSERT INTO Departments2 VALUES ('営業部', '二課', '2024-10-12');
INSERT INTO Departments2 VALUES ('営業部', '三課', NULL);
INSERT INTO Departments2 VALUES ('研究開発部', '基礎理論課', '2024-09-15');
INSERT INTO Departments2 VALUES ('研究開発部', '応用技術課', '2024-08-20');
INSERT INTO Departments2 VALUES ('総務部', '一課', '2024-09-11');
INSERT INTO Departments2 VALUES ('人事部', '採用課', NULL);

●ワイリーの答え：HAVING句を使う

SELECT department
  FROM Departments2
 GROUP BY department
HAVING COUNT(*) = SUM(CASE WHEN check_date IS NOT NULL 
                           THEN 1 ELSE 0 END);


●ヘレンの答え：COUNT(列名)を使う
SELECT department
  FROM Departments2
 GROUP BY department
HAVING COUNT(*) = COUNT(check_date);


●ヘレンの答えの中を見てみる
SELECT department, COUNT(*) AS all_cnt, COUNT(check_date) as col_cnt
  FROM Departments2
 GROUP BY department;


●集合指向アレルギーとループ依存症の併発（Java + PostgreSQL）
import java.sql.*;

public class SecurityCheck {
     public static void main(String[] args) throws Exception {

          /* 1) データベースへの接続情報 */
          Connection con = null; 
          Statement st = null;
          ResultSet rs = null;

          String url = "jdbc:postgresql://localhost:5432/shop";
          String user = "postgres";
          String password = "test"; 

          String strResult = null;
          
          /* 2) 変数の初期化 */
          String   strCurDepartment = "";
          String   strOldDepartment = "";

          String   strCheckflg = "";       /* 完了または未完 */
          boolean  blCompleted = true;     /* 完了フラグ */

          /* 3) JDBCドライバの定義 */
          Class.forName("org.postgresql.Driver");

          /* 4) PostgreSQLへの接続 */
          con = DriverManager.getConnection(url, user, password);
          st = con.createStatement();

          /* 5) SELECT文の実行 */
          rs = st.executeQuery("SELECT * FROM Departments " + 
                                       "ORDER BY department, division");


          /* 6) ヘッダの表示 */
          String strHeader = " department" + "\n" + "-----------" + "\n" ;
          System.out.print(strHeader);

          //最初の行かどうかを判断するカウンター
          int rowCnt = 0;

          /* 7) 結果セットを一行づつループ */
          while (rs.next()){

               rowCnt ++;  //最初の行で1になる

               strCurDepartment = rs.getString("department").trim();
               strCheckflg = rs.getString("check_flag").trim(); 

               /* 9) 部署が異なる場合（かつ最初の行でない場合）はブレイクしてチェックフラグを確認 */
               if (strOldDepartment.equals(strCurDepartment) == false && rowCnt > 1){

                    /* チェックフラグがtrueなら出力 */
                    if (blCompleted == true){
                       System.out.print(strOldDepartment + "\n");      //一行前の部署を出力
                    }

                    //ブレイクしたら完了フラグもtrueで初期化
                    blCompleted = true;
               }


               /* 8) 一つでも未完の課があれば完了フラグをfalseにする */
               if (strCheckflg.equals("未完")) {
                    blCompleted = false;
               }

               strOldDepartment = strCurDepartment;
          }


          /* チェックフラグがtrueなら最後の部署を出力 */
          if (blCompleted == true){
               System.out.print(strCurDepartment + "\n");    //現在行の部署を出力
          }
    
          /* 10) データベースとの接続を切断 */
          rs.close(); 
          st.close();
          con.close();
     }
}  


