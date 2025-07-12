00_序章

●倉庫テーブル
CREATE TABLE Warehouse 
(warehouse_id  INTEGER NOT NULL PRIMARY KEY,
 region        CHAR(32) NOT NULL);

INSERT INTO Warehouse VALUES (1, 'East Coast'); 
INSERT INTO Warehouse VALUES (2, 'East Coast');
INSERT INTO Warehouse VALUES (3, 'West Coast');
INSERT INTO Warehouse VALUES (4, 'West Coast');
INSERT INTO Warehouse VALUES (5, 'West Coast');


●倉庫IDから拠点の都市を割り出すクエリ
SELECT DECODE(warehouse_id, 1, 'New York', 
                            2, 'New Jersey', 
                            3, 'Los Angels', 
                            4, 'Seattle',
                            5, 'San Francisco',
                               'Non domestic') AS city,
       region
  FROM  Warehouse;


●CASE式による汎用的なクエリ
SELECT CASE WHEN warehouse_id = 1 THEN 'New York'
            WHEN warehouse_id = 2 THEN 'New Jersey'
            WHEN warehouse_id = 3 THEN 'Los Angels'
            WHEN warehouse_id = 4 THEN 'Seattle'
            WHEN warehouse_id = 5 THEN 'San Francisco'
            ELSE NULL END AS city,
       region
  FROM Warehouse;


●単純CASE式の書き方
SELECT CASE warehouse_id 
               WHEN 1 THEN 'New York'
               WHEN 2 THEN 'New Jersey'
               WHEN 3 THEN 'Los Angels'
               WHEN 4 THEN 'Seattle'
               WHEN 5 THEN 'San Francisco'
        ELSE NULL END AS city,
       region
  FROM Warehouse;


●CASE式は短絡評価
SELECT CASE WHEN warehouse_id IN (1, 2) THEN 'New York'
            WHEN warehouse_id = 2 THEN 'New Jersey'
            WHEN warehouse_id = 3 THEN 'Los Angels'
            WHEN warehouse_id = 4 THEN 'Seattle'
            WHEN warehouse_id = 5 THEN 'San Francisco'
            ELSE NULL END AS city,
       region
  FROM Warehouse;


●戻り値は同じデータ型でなければエラーになる
SELECT CASE WHEN warehouse_id = 1 THEN 'New York'
            WHEN warehouse_id = 2 THEN 100
            WHEN warehouse_id = 3 THEN 'Los Angels'
            WHEN warehouse_id = 4 THEN 500
            WHEN warehouse_id = 5 THEN 'San Francisco'
            ELSE NULL END AS city,
       region
  FROM Warehouse;


●都市テーブル
CREATE TABLE City
(city   CHAR(32) NOT NULL ,
 population INTEGER NOT NULL,
   CONSTRAINT pk_City PRIMARY KEY (city));


INSERT INTO City VALUES('New York', 8460000);
INSERT INTO City VALUES('Los Angels',  3840000);
INSERT INTO City VALUES('San Francisco',  815000);
INSERT INTO City VALUES('New Orleans',  377000);


●患者2のコード（SQL Server）
SELECT [New York], [Los Angels], [San Francisco], [New Orleans]
FROM  
(
  SELECT city, population   
  FROM City
) AS SourceTable  
PIVOT
(  
  SUM(population)
  FOR city IN ([New York], [Los Angels], [San Francisco], [New Orleans])  
) AS PivotTable;


●ロバートの解：CASE式を使うピボット
SELECT SUM(CASE WHEN city = 'New York'      THEN population ELSE 0 END)  AS "New York", 
       SUM(CASE WHEN city = 'Los Angels'    THEN population ELSE 0 END)  AS "Los Angels",
       SUM(CASE WHEN city = 'San Francisco' THEN population ELSE 0 END)  AS "San Francisco",
       SUM(CASE WHEN city = 'New Orleans'   THEN population ELSE 0 END)  AS "New Orleans" 
  FROM City; 


●SUM関数なしでCASE式を使うと
SELECT CASE WHEN city = 'New York'      THEN population ELSE 0 END  AS "New York", 
       CASE WHEN city = 'Los Angels'    THEN population ELSE 0 END  AS "Los Angels",
       CASE WHEN city = 'San Francisco' THEN population ELSE 0 END  AS "San Francisco",
       CASE WHEN city = 'New Orleans'   THEN population ELSE 0 END  AS "New Orleans" 
  FROM City; 

●商品価格テーブル
CREATE TABLE ItemPrice
(item_id   CHAR(3) NOT NULL,
 year      INTEGER NOT NULL,
 item_name VARCHAR(32) NOT NULL,
 price_tax_ex INTEGER NOT NULL,
 price_tax_in INTEGER NOT NULL,
   CONSTRAINT pk_ItemPrice PRIMARY KEY (item_id, year));

INSERT INTO ItemPrice VALUES('100',	2002,	'カップ',	500,	525);
INSERT INTO ItemPrice VALUES('100',	2003,	'カップ',	520,	546);
INSERT INTO ItemPrice VALUES('100',	2004,	'カップ',	600,	630);
INSERT INTO ItemPrice VALUES('100',	2005,	'カップ',	600,	630);
INSERT INTO ItemPrice VALUES('101',	2002,	'スプーン',	500,	525);
INSERT INTO ItemPrice VALUES('101',	2003,	'スプーン',	500,	525);
INSERT INTO ItemPrice VALUES('101',	2004,	'スプーン',	500,	525);
INSERT INTO ItemPrice VALUES('101',	2005,	'スプーン',	500,	525);
INSERT INTO ItemPrice VALUES('102',	2002,	'ナイフ',	600,	630);
INSERT INTO ItemPrice VALUES('102',	2003,	'ナイフ',	550,	577);
INSERT INTO ItemPrice VALUES('102',	2004,	'ナイフ',	550,	577);
INSERT INTO ItemPrice VALUES('102',	2005,	'ナイフ',	400,	420);


●ワイリーの解答（UNIONを使う）
SELECT item_name, year, price_tax_ex AS price
  FROM ItemPrice
 WHERE year <= 2003
UNION ALL
SELECT item_name, year, price_tax_in AS price
  FROM ItemPrice
 WHERE year >= 2004;


●：ヘレンの解答（CASE式を使う）
SELECT item_name, year,
       CASE WHEN year <= 2003 THEN price_tax_ex
            WHEN year >= 2004 THEN price_tax_in
            ELSE NULL END AS price 
  FROM ItemPrice;


●ワイリーの解（WHERE句でCASE式）
SELECT item_name, year
  FROM ItemPrice
 WHERE 600 <= CASE WHEN year <= 2003 THEN price_tax_ex
                   WHEN year >= 2004 THEN price_tax_in
                   ELSE NULL END;


●集計単位を変換して人口の合計を求める
SELECT CASE WHEN city IN ('New York', 'New Orleans')     THEN 'East Coast'
            WHEN city IN ('San Francisco', 'Los Angels') THEN 'West Coast'
            ELSE NULL END AS region,
       SUM(population) AS sum_pop                
  FROM City                                       
 GROUP BY region; 


●OracleとPostgreSQLとMySQL以外での書き方
SELECT CASE WHEN city IN ('New York', 'New Orleans')     THEN 'East Coast'
            WHEN city IN ('San Francisco', 'Los Angels') THEN 'West Coast'
            ELSE NULL END AS region,
       SUM(population) AS sum_pop
  FROM City
 GROUP BY CASE WHEN city IN ('New York', 'New Orleans')     THEN 'East Coast'
               WHEN city IN ('San Francisco', 'Los Angels') THEN 'West Coast'
               ELSE NULL END;


●値の入れ替え：患者のUPDATE文
UPDATE City
   SET population = 3840000
 WHERE city = 'New York';

UPDATE City
   SET population = 8460000
 WHERE city = 'Los Angels';


●ヘレンの解：UPDATE文でCASE式を使う
UPDATE City 
   SET population = CASE WHEN city = 'New York'   THEN 3840000
                         WHEN city = 'Los Angels' THEN 8460000
                         ELSE population END
 WHERE city IN ('New York', 'Los Angels');

●スカラサブクエリで一般化したUPDATE文(MySQLではエラーになる)
UPDATE City 
   SET population = CASE WHEN city = 'New York'   THEN
                             (SELECT population FROM City WHERE city = 'Los Angels')
                         WHEN city = 'Los Angels' THEN 
                             (SELECT population FROM City WHERE city = 'New York')
                         ELSE population END
 WHERE city IN ('New York', 'Los Angels');


●アイスクリーム売り上げテーブル
CREATE TABLE SalesIcecream
(shop_id   CHAR(4) NOT NULL,
 sale_date DATE NOT NULL,
 sales_amt INTEGER NOT NULL,
   CONSTRAINT pk_SalesIcecream PRIMARY KEY(shop_id, sale_date) );

INSERT INTO SalesIcecream VALUES('A', '2024-06-01', 67800);
INSERT INTO SalesIcecream VALUES('A', '2024-06-02', 87000);
INSERT INTO SalesIcecream VALUES('A', '2024-06-05', 11300);
INSERT INTO SalesIcecream VALUES('A', '2024-06-10', 9800);
INSERT INTO SalesIcecream VALUES('A', '2024-06-15', 9800);
INSERT INTO SalesIcecream VALUES('B', '2024-06-02', 178000);
INSERT INTO SalesIcecream VALUES('B', '2024-06-15', 18800);
INSERT INTO SalesIcecream VALUES('B', '2024-06-17', 19850);
INSERT INTO SalesIcecream VALUES('B', '2024-06-20', 23800);
INSERT INTO SalesIcecream VALUES('B', '2024-06-21', 18800);
INSERT INTO SalesIcecream VALUES('C', '2024-06-01', 12500);

●患者のクエリ：相関サブクエリで累計を求める
SELECT shop_id,
       sale_date,
       sales_amt,
       (SELECT SUM(sales_amt)
          FROM SalesIcecream SI1
         WHERE SI1.shop_id = SI2.shop_id
           AND SI1.sale_date <= SI2.sale_date) AS cumlative_amt
  FROM SalesIcecream SI2;


●ロバートの解：ウィンドウ関数
SELECT shop_id,
       sale_date,
       sales_amt,
       SUM(sales_amt) OVER (PARTITION BY shop_id 
                                ORDER BY sale_date) AS cumlative_amt
  FROM SalesIcecream;

●ウィンドウ関数で移動平均を求める
SELECT shop_id,
       sale_date,
       sales_amt,
       ROUND(AVG(sales_amt) OVER (PARTITION BY shop_id 
                                ORDER BY sale_date
                            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 0) AS moving_avg
  FROM SalesIcecream;


●体重テーブル
CREATE TABLE Weights
(student_id CHAR(4) NOT NULL PRIMARY KEY,
 weight INTEGER NOT NULL);

INSERT INTO Weights VALUES('A',  55);
INSERT INTO Weights VALUES('B',  70);
INSERT INTO Weights VALUES('C',  65);
INSERT INTO Weights VALUES('D',  120);
INSERT INTO Weights VALUES('E',  83);
INSERT INTO Weights VALUES('F',  63);

●平均を求めるクエリ
SELECT ROUND(AVG(weight), 0) AS avg_weight
  FROM Weights;


●クラスの平均と学生の体重を比較する
SELECT *
  FROM Weights
 WHERE weight > (SELECT ROUND(AVG(weight), 0) AS avg_weight
                   FROM Weights);


●正しい解：ウィンドウ関数を使う
SELECT student_id, weight, avg_weight
  FROM (SELECT student_id, weight,
               ROUND(AVG(weight) OVER(), 0) AS avg_weight
          FROM Weights) TMP
  WHERE weight > avg_weight;
