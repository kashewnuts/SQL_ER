●ピザ売り上げテーブル
CREATE TABLE PizzaSales
(customer_id  INTEGER NOT NULL,
 sale_date    DATE NOT NULL,
 sales_amt    INTEGER NOT NULL,
   CONSTRAINT pk_PizzaSales PRIMARY KEY (customer_id, sale_date));

INSERT INTO PizzaSales VALUES (1, '2024-04-01', 500);
INSERT INTO PizzaSales VALUES (1, '2024-04-23', 1200);
INSERT INTO PizzaSales VALUES (1, '2024-05-29', 1700);
INSERT INTO PizzaSales VALUES (1, '2024-06-01', 400);
INSERT INTO PizzaSales VALUES (1, '2024-06-30', 8000);
INSERT INTO PizzaSales VALUES (2, '2023-12-30', 1000);
INSERT INTO PizzaSales VALUES (2, '2024-01-10', 800);
INSERT INTO PizzaSales VALUES (2, '2024-02-25', 500);
INSERT INTO PizzaSales VALUES (2, '2024-04-13', 1300);
INSERT INTO PizzaSales VALUES (2, '2024-05-08', 900);
INSERT INTO PizzaSales VALUES (3, '2023-10-08', 700);
INSERT INTO PizzaSales VALUES (3, '2023-11-22', 500);


●ワイリーの解：UNIONでクエリを繋げる
SELECT customer_id, '0-30日前は' AS term, SUM(sales_amt) AS term_amt
  FROM PizzaSales
 WHERE sale_date BETWEEN (DATE '2024-06-30' - INTERVAL '30' DAY) 
                     AND  DATE '2024-06-30'
 GROUP BY customer_id
UNION ALL
SELECT customer_id, '31日-60日前は' AS term, SUM(sales_amt) AS term_amt
  FROM PizzaSales
 WHERE sale_date BETWEEN (DATE '2024-06-30' - INTERVAL '60' DAY) 
                     AND (DATE '2024-06-30' - INTERVAL '31' DAY)
 GROUP BY customer_id
UNION
SELECT customer_id, '61日-90日前は' AS term, SUM(sales_amt) AS term_amt
  FROM PizzaSales
 WHERE sale_date BETWEEN (DATE '2024-06-30' - INTERVAL '90' DAY) 
                     AND (DATE '2024-06-30' - INTERVAL '61' DAY)
 GROUP BY customer_id
UNION
SELECT customer_id, '91日以上前は' AS term, SUM(sales_amt) AS term_amt
  FROM PizzaSales
 WHERE sale_date < (DATE '2024-06-30' - INTERVAL '91' DAY)
 GROUP BY customer_id
 ORDER BY customer_id, term;


●CASE式による解
SELECT customer_id,  
       SUM(CASE WHEN sale_date BETWEEN DATE '2024-06-30' - INTERVAL '30' DAY
                                   AND DATE '2024-06-30'
                THEN sales_amt ELSE 0 END) AS term_30,
       SUM(CASE WHEN sale_date BETWEEN DATE '2024-06-30' - INTERVAL '60' DAY 
                                   AND DATE '2024-06-30' - INTERVAL '31' DAY
                THEN sales_amt ELSE 0 END) AS term_31_60,
       SUM(CASE WHEN sale_date BETWEEN DATE '2024-06-30' - INTERVAL '90' DAY 
                                   AND DATE '2024-06-30' - INTERVAL '61' DAY
                THEN sales_amt ELSE 0 END) AS term_61_90,
       SUM(CASE WHEN sale_date < DATE '2024-06-30' - INTERVAL '91' DAY
                THEN sales_amt ELSE 0 END) AS term_91_
  FROM PizzaSales
 GROUP BY customer_id
 ORDER BY customer_id;


●SQL ServerとSnowflakeの解
SELECT customer_id,  
       SUM(CASE WHEN sale_date BETWEEN DATEADD(DAY, -30, CAST('2024-06-30' AS DATE))
                                  AND CAST('2024-06-30' AS DATE)
                THEN sales_amt ELSE 0 END) AS term_30,
       SUM(CASE WHEN sale_date BETWEEN DATEADD(DAY, -60, CAST('2024-06-30' AS DATE)) 
                                   AND DATEADD(DAY, -31, CAST('2024-06-30' AS DATE))
                THEN sales_amt ELSE 0 END) AS term_31_60,
       SUM(CASE WHEN sale_date BETWEEN DATEADD(DAY, -90, CAST('2024-06-30' AS DATE)) 
                                   AND DATEADD(DAY, -61, CAST('2024-06-30' AS DATE))
                THEN sales_amt ELSE 0 END) AS term_61_90,
       SUM(CASE WHEN sale_date < DATEADD(DAY, -91, CAST('2024-06-30' AS DATE))
                THEN sales_amt ELSE 0 END) AS term_91_
  FROM PizzaSales
 GROUP BY customer_id
 ORDER BY customer_id;


●人口テーブル
CREATE TABLE Population
(prefecture VARCHAR(32) NOT NULL,
 sex INTEGER NOT NULL,
 pop INTEGER NOT NULL,
   CONSTRAINT pk_Population PRIMARY KEY (prefecture, sex) );

INSERT INTO Population VALUES ('徳島', 1, 60);
INSERT INTO Population VALUES ('徳島', 2, 40);
INSERT INTO Population VALUES ('香川', 1, 90);
INSERT INTO Population VALUES ('香川', 2, 100);
INSERT INTO Population VALUES ('愛媛', 1, 100);
INSERT INTO Population VALUES ('愛媛', 2, 50);
INSERT INTO Population VALUES ('高知', 1, 100);
INSERT INTO Population VALUES ('高知', 2, 100);
INSERT INTO Population VALUES ('福岡', 1, 20);
INSERT INTO Population VALUES ('福岡', 2, 200);


●ワイリーの解：UNION
SELECT prefecture, SUM(pop_men) AS pop_men, SUM(pop_wom) AS pop_wom
  FROM ( SELECT prefecture, pop AS pop_men, null AS pop_wom
           FROM Population
          WHERE sex = '1'       -- 男性
          UNION
         SELECT prefecture, NULL AS pop_men, pop AS pop_wom
           FROM Population
          WHERE sex = '2') TMP  -- 女性
 GROUP BY prefecture;

●ヘレンの解：CASE式
SELECT prefecture, 
       SUM(CASE WHEN sex = '1' THEN pop ELSE 0 END) AS pop_men,
       SUM(CASE WHEN sex = '2' THEN pop ELSE 0 END) AS pop_wom
  FROM Population
 GROUP BY prefecture;


●役職テーブル
CREATE TABLE Roles
(person CHAR(16),
 role   CHAR(16),
   CONSTRAINT pk_Roles PRIMARY KEY (person, role));

INSERT INTO Roles VALUES('Smith', 'Officer');
INSERT INTO Roles VALUES('Smith', 'Director');
INSERT INTO Roles VALUES('Jones', 'Officer');
INSERT INTO Roles VALUES('White', 'Director');
INSERT INTO Roles VALUES('Brown', 'Worker');
INSERT INTO Roles VALUES('Kim', 'Officer');
INSERT INTO Roles VALUES('Kim', 'Worker');


●患者のクエリ：HAVING句で分岐
SELECT person, MAX(role) AS combined_role
  FROM Roles  
 GROUP BY person
HAVING COUNT(*) = 1  -- 役職が一つ
UNION
SELECT person, 'Both'  AS combined_role
  FROM Roles
 GROUP BY person
HAVING COUNT(*) = 2  -- 役職が二つ
;

●エラーになるクエリ
SELECT person, role AS combined_role
  FROM Roles  
 GROUP BY person
HAVING COUNT(*) = 1  -- 役職が一つなら
UNION
SELECT person, 'Both'  AS combined_role
  FROM Roles
 GROUP BY person
HAVING COUNT(*) = 2  -- 役職が二つなら
;

●ロバートの解：CASE式の引数にCOUNT関数を取る
SELECT person, 
       CASE WHEN COUNT(*) = 1  THEN MAX(role)
            WHEN COUNT(*) = 2  THEN 'Both'
            ELSE NULL
        END AS combined_role
  FROM Roles
 GROUP BY person;

●最大値と最小値が異なる場合って？
SELECT person,
       CASE WHEN MIN(role) <> MAX(role)
            THEN 'Both'
            ELSE MIN(role) END AS combined_role
  FROM Roles
 GROUP BY person;


●レース結果テーブル
CREATE TABLE RacingResults
(race_nbr INTEGER NOT NULL,
 first_prize CHAR(30) NOT NULL,
 second_prize CHAR(30) NOT NULL,
 third_prize CHAR(30) NOT NULL,
   CONSTRAINT pk_RacingResults PRIMARY KEY (race_nbr));

INSERT INTO RacingResults VALUES(1, 'サンオーシャン', 'ジョニーブレイク', 'ウーバーウィーク');
INSERT INTO RacingResults VALUES(2, 'オカメインコ', 'ガンバレフォックス', 'キングイエヤス');
INSERT INTO RacingResults VALUES(3, 'サンオーシャン', 'キングイエヤス', 'クイーンモナカ');
INSERT INTO RacingResults VALUES(4, 'ウーバーウィーク', 'ジョニーブレイク', 'コーラルフルーツ');
INSERT INTO RacingResults VALUES(5, 'コーラルフルーツ', 'ジョニーブレイク', 'ブラザーフッド');
INSERT INTO RacingResults VALUES(6, 'ジョニーブレイク', 'ソバヤノデマエ', 'ヒャクシキ');


●患者のクエリ：UNIONを使う
SELECT horse, SUM(tally) AS tally
  FROM (SELECT first_prize AS horse, 
               COUNT(*) AS tally, 'first_prize'
          FROM RacingResults
         GROUP BY first_prize
        UNION ALL
        SELECT second_prize AS horse, 
               COUNT(*) AS tally, 'second_prize'
          FROM RacingResults
         GROUP BY second_prize
        UNION ALL
        SELECT third_prize AS horse, 
               COUNT(*) AS tally, 'third_prize'
          FROM RacingResults
         GROUP BY third_prize) PRIZE
GROUP BY horse
ORDER BY tally DESC;


●馬名マスタテーブル
CREATE TABLE Horses
(horse_name CHAR(30) NOT NULL,
   CONSTRAINT pk_Horses PRIMARY KEY (horse_name) );

INSERT INTO Horses VALUES('ジョニーブレイク');
INSERT INTO Horses VALUES('ウーバーウィーク');
INSERT INTO Horses VALUES('サンオーシャン');
INSERT INTO Horses VALUES('コーラルフルーツ');
INSERT INTO Horses VALUES('キングイエヤス');
INSERT INTO Horses VALUES('ブラザーフッド');
INSERT INTO Horses VALUES('ソバヤノデマエ');
INSERT INTO Horses VALUES('ガンバレフォックス');
INSERT INTO Horses VALUES('オカメインコ');
INSERT INTO Horses VALUES('ヒャクシキ');
INSERT INTO Horses VALUES('クイーンモナカ');


●ロバートの解：馬名マスタと結合
SELECT HorseMaster.horse_name, COUNT(*) AS tally
  FROM Horses HorseMaster INNER JOIN RacingResults Results
    ON HorseMaster.horse_name IN (Results.first_prize, Results.second_prize, Results.third_prize)
 GROUP BY HorseMaster.horse_name
 ORDER BY tally DESC;

●入賞歴のない馬のデータ
INSERT INTO Horses VALUES('ロイヤルフラッシュ');

●外部結合による解：間違い
SELECT HorseMaster.horse_name, COUNT(*) AS tally
  FROM Horses HorseMaster LEFT OUTER JOIN RacingResults Results
    ON HorseMaster.horse_name IN (Results.first_prize, Results.second_prize, Results.third_prize)
 GROUP BY HorseMaster.horse_name
 ORDER BY tally DESC;
 
 ●ヘレンの解：OOUNT(列名)を使う
SELECT HorseMaster.horse_name, COUNT(Results.race_nbr) AS tally
  FROM Horses HorseMaster LEFT OUTER JOIN RacingResults Results
    ON HorseMaster.horse_name IN (Results.first_prize, Results.second_prize, Results.third_prize)
 GROUP BY HorseMaster.horse_name
 ORDER BY tally DESC;


●行持ちのテーブル定義
CREATE TABLE RacingResults2
(race_nbr INTEGER NOT NULL,
 prize    INTEGER NOT NULL 
   CHECK (prize IN (1,2,3)),
 horse_name CHAR(30) NOT NULL,
   CONSTRAINT pk_RacingResults2 PRIMARY KEY (race_nbr, prize));


INSERT INTO RacingResults2 VALUES(1, 1, 'サンオーシャン');
INSERT INTO RacingResults2 VALUES(1, 2, 'ジョニーブレイク');
INSERT INTO RacingResults2 VALUES(1, 3, 'ウーバーウィーク');
INSERT INTO RacingResults2 VALUES(2, 1, 'オカメインコ');
INSERT INTO RacingResults2 VALUES(2, 2, 'ガンバレフォックス');
INSERT INTO RacingResults2 VALUES(2, 3, 'キングイエヤス');
INSERT INTO RacingResults2 VALUES(3, 1, 'サンオーシャン');
INSERT INTO RacingResults2 VALUES(3, 2, 'キングイエヤス');
INSERT INTO RacingResults2 VALUES(3, 3, 'クイーンモナカ');
INSERT INTO RacingResults2 VALUES(4, 1, 'ウーバーウィーク');
INSERT INTO RacingResults2 VALUES(4, 2, 'ジョニーブレイク');
INSERT INTO RacingResults2 VALUES(4, 3, 'コーラルフルーツ');
INSERT INTO RacingResults2 VALUES(5, 1, 'コーラルフルーツ');
INSERT INTO RacingResults2 VALUES(5, 2, 'ジョニーブレイク');
INSERT INTO RacingResults2 VALUES(5, 3, 'ブラザーフッド');
INSERT INTO RacingResults2 VALUES(6, 1, 'ジョニーブレイク');
INSERT INTO RacingResults2 VALUES(6, 2, 'ソバヤノデマエ');
INSERT INTO RacingResults2 VALUES(6, 3, 'ヒャクシキ');

●入賞した馬名を選択する：行持ちバージョン
SELECT horse_name, COUNT(*) AS tally
  FROM RacingResults2
 GROUP BY horse_name
 ORDER BY tally DESC;


●講座マスタ
CREATE TABLE CourseMaster
(course_id   INTEGER PRIMARY KEY,
 course_name VARCHAR(32) NOT NULL);

INSERT INTO CourseMaster VALUES(1, '経理入門');
INSERT INTO CourseMaster VALUES(2, '財務知識');
INSERT INTO CourseMaster VALUES(3, '簿記検定');
INSERT INTO CourseMaster VALUES(4, '税理士');


●開催講座テーブル
CREATE TABLE OpenCourses
(month       CHAR(6) ,
 course_id   INTEGER ,
    CONSTRAINT pk_OpenCourses PRIMARY KEY(month, course_id));

INSERT INTO OpenCourses VALUES('201806', 1);
INSERT INTO OpenCourses VALUES('201806', 3);
INSERT INTO OpenCourses VALUES('201806', 4);
INSERT INTO OpenCourses VALUES('201807', 4);
INSERT INTO OpenCourses VALUES('201808', 2);
INSERT INTO OpenCourses VALUES('201808', 4);

