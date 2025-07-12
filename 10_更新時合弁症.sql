●受注明細テーブル
CREATE TABLE EntryDetails
( entry_id   CHAR(3) NOT NULL,
  entry_seq  INTEGER NOT NULL,
  item       CHAR(3) ,
  quantity   INTEGER ,
    CONSTRAINT pk_EntryDetails PRIMARY KEY (entry_id, entry_seq));

INSERT INTO EntryDetails VALUES ('001', 1, 'DK0', 1);
INSERT INTO EntryDetails VALUES ('001', 2, 'CF2', 3);
INSERT INTO EntryDetails VALUES ('001', 3, 'AA9', 2);
INSERT INTO EntryDetails VALUES ('002', 1, 'BF8', 10);
INSERT INTO EntryDetails VALUES ('002', 2, 'CF2', 1);
INSERT INTO EntryDetails VALUES ('003', 1, 'DK0', 5);

●発注明細テーブル
CREATE TABLE OrderDetails
( order_id   CHAR(3) NOT NULL,
  order_seq  INTEGER NOT NULL,
  entry_id   CHAR(3) NOT NULL,
  entry_seq  INTEGER NOT NULL,
  item       CHAR(3) ,
  quantity   INTEGER ,
    CONSTRAINT pk_OrderDetails PRIMARY KEY (order_id, order_seq));

INSERT INTO OrderDetails VALUES ('OD1', 1, '001', 1, NULL, NULL);
INSERT INTO OrderDetails VALUES ('OD1', 2, '001', 2, NULL, NULL);
INSERT INTO OrderDetails VALUES ('OD1', 3, '001', 3, NULL, NULL);
INSERT INTO OrderDetails VALUES ('OD2', 1, '002', 1, NULL, NULL);
INSERT INTO OrderDetails VALUES ('OD2', 2, '002', 2, NULL, NULL);
INSERT INTO OrderDetails VALUES ('OD3', 1, '003', 1, NULL, NULL);


●患者のコード：冗長なUPDATE
UPDATE OrderDetails
   SET item     = (SELECT item 
                     FROM EntryDetails ED1
                    WHERE OrderDetails.entry_id  = ED1.entry_id
                      AND OrderDetails.entry_seq = ED1.entry_seq),
       quantity = (SELECT quantity
                     FROM EntryDetails ED2
                    WHERE OrderDetails.entry_id  = ED2.entry_id
                      AND OrderDetails.entry_seq = ED2.entry_seq);


●ヘレンの解：SET句で行式を使う
UPDATE OrderDetails
   SET (item, quantity)
           = (SELECT item, quantity
                     FROM EntryDetails ED
                    WHERE OrderDetails.entry_id  = ED.entry_id
                      AND OrderDetails.entry_seq = ED.entry_seq);


●ロバートの解：WHERE句で対象レコードを制限
/* インデックス作成 */
CREATE INDEX idx_entry ON OrderDetails (entry_id, entry_seq);

UPDATE OrderDetails
   SET (item, quantity)
           = (SELECT item, quantity
                     FROM EntryDetails ED
                    WHERE OrderDetails.entry_id  = ED.entry_id
                      AND OrderDetails.entry_seq = ED.entry_seq)
WHERE EXISTS (SELECT *
                 FROM EntryDetails ED
                WHERE OrderDetails.entry_id  = ED.entry_id
                  AND OrderDetails.entry_seq = ED.entry_seq);


●「ホテル」テーブル
CREATE TABLE Hotel
( floor_nbr INTEGER NOT NULL,
  room_nbr  INTEGER);

INSERT INTO Hotel VALUES (1, NULL);
INSERT INTO Hotel VALUES (1, NULL);
INSERT INTO Hotel VALUES (1, NULL);
INSERT INTO Hotel VALUES (2, NULL);
INSERT INTO Hotel VALUES (2, NULL);
INSERT INTO Hotel VALUES (3, NULL);
INSERT INTO Hotel VALUES (3, NULL);

●ワイリーの解：SET句でウィンドウ関数を使う（Db2でのみ動作）
UPDATE Hotel
   SET room_nbr = (floor_nbr * 100)
                    + ROW_NUMBER() OVER (PARTITION BY floor_nbr);


●ワイリーの解：ビュー版（どのDBMSでも動く）
CREATE VIEW Hotel_Room_Num (floor_nbr, room_nbr) AS 
(SELECT floor_nbr,
       (floor_nbr * 100) 
         + ROW_NUMBER() OVER (PARTITION BY floor_nbr)
  FROM Hotel);



●客室番号に連番が付いたHotel2テーブルを作成
CREATE TABLE Hotel2
( floor_nbr INTEGER NOT NULL,
  room_nbr  INTEGER NOT NULL,
    CONSTRAINT pk_Hotel2 PRIMARY KEY (floor_nbr, room_nbr));

●Oracle、PostgreSQL、SQL Server、Db2
INSERT INTO Hotel2 VALUES(1, (SELECT COALESCE(MAX(room_nbr), 0) +1 FROM Hotel2));
INSERT INTO Hotel2 VALUES(1, (SELECT COALESCE(MAX(room_nbr), 0) +1 FROM Hotel2));
INSERT INTO Hotel2 VALUES(1, (SELECT COALESCE(MAX(room_nbr), 0) +1 FROM Hotel2));
INSERT INTO Hotel2 VALUES(2, (SELECT COALESCE(MAX(room_nbr), 0) +1 FROM Hotel2));
INSERT INTO Hotel2 VALUES(2, (SELECT COALESCE(MAX(room_nbr), 0) +1 FROM Hotel2));
INSERT INTO Hotel2 VALUES(3, (SELECT COALESCE(MAX(room_nbr), 0) +1 FROM Hotel2));
INSERT INTO Hotel2 VALUES(3, (SELECT COALESCE(MAX(room_nbr), 0) +1 FROM Hotel2));

●MySQL
BEGIN;
  CREATE TABLE Sequence (id INTEGER NOT NULL);
  INSERT INTO Sequence VALUES (0);
  UPDATE Sequence SET id = LAST_INSERT_ID(id + 1);
  INSERT INTO Hotel2 VALUES(1, (SELECT LAST_INSERT_ID()));
  UPDATE Sequence SET id = LAST_INSERT_ID(id + 1);
  INSERT INTO Hotel2 VALUES(1, (SELECT LAST_INSERT_ID()));
  UPDATE Sequence SET id = LAST_INSERT_ID(id + 1);
  INSERT INTO Hotel2 VALUES(1, (SELECT LAST_INSERT_ID()));
  UPDATE Sequence SET id = LAST_INSERT_ID(id + 1);
  INSERT INTO Hotel2 VALUES(2, (SELECT LAST_INSERT_ID()));
  UPDATE Sequence SET id = LAST_INSERT_ID(id + 1);
  INSERT INTO Hotel2 VALUES(2, (SELECT LAST_INSERT_ID()));
  UPDATE Sequence SET id = LAST_INSERT_ID(id + 1);
  INSERT INTO Hotel2 VALUES(3, (SELECT LAST_INSERT_ID()));
  UPDATE Sequence SET id = LAST_INSERT_ID(id + 1);
  INSERT INTO Hotel2 VALUES(3, (SELECT LAST_INSERT_ID()));
  DROP TABLE Sequence;
COMMIT;


●Snowflake
INSERT INTO hotel2 (floor_nbr, room_nbr) 
SELECT  1,  MAX(room_nbr) + 1 FROM hotel2;
INSERT INTO hotel2 (floor_nbr, room_nbr) 
SELECT  1,  MAX(room_nbr) + 1 FROM hotel2;
INSERT INTO hotel2 (floor_nbr, room_nbr) 
SELECT  1,  MAX(room_nbr) + 1 FROM hotel2;
INSERT INTO hotel2 (floor_nbr, room_nbr) 
SELECT  2,  MAX(room_nbr) + 1 FROM hotel2;
INSERT INTO hotel2 (floor_nbr, room_nbr) 
SELECT  2,  MAX(room_nbr) + 1 FROM hotel2;
INSERT INTO hotel2 (floor_nbr, room_nbr) 
SELECT  3,  MAX(room_nbr) + 1 FROM hotel2;
INSERT INTO hotel2 (floor_nbr, room_nbr) 
SELECT  3,  MAX(room_nbr) + 1 FROM hotel2;
INSERT INTO hotel2 (floor_nbr, room_nbr) 
SELECT  3,  MAX(room_nbr) + 1 FROM hotel2;


●ワイリーの解：UPDATE文でウィンドウ関数（Snowflakeでは動かない）
UPDATE Hotel2
   SET room_nbr
         =  (SELECT nbr
               FROM (SELECT room_nbr, 
                           (floor_nbr * 100) +
                              ROW_NUMBER() OVER(PARTITION BY floor_nbr
                                           ORDER BY room_nbr) AS nbr
                       FROM Hotel2) TMP
              WHERE Hotel2.room_nbr = TMP.room_nbr);


●フルーツテーブル
CREATE TABLE Fruits
(name  VARCHAR(32) NOT NULL,
 price INTEGER NOT NULL);


 INSERT INTO Fruits VALUES('バナナ', 100);
 INSERT INTO Fruits VALUES('バナナ', 100);
 INSERT INTO Fruits VALUES('バナナ', 100);
 INSERT INTO Fruits VALUES('ぶどう', 500);
 INSERT INTO Fruits VALUES('みかん', 200);
 INSERT INTO Fruits VALUES('みかん', 200);
 INSERT INTO Fruits VALUES('すいか', 300);


●患者のコード（Oracleでのみ動作）
DELETE FROM Fruits F1
 WHERE rowid < (SELECT MAX(F2.rowid)
                  FROM Fruits F2
                 WHERE F1.name = F2.name
                   AND F1.price = F2.price);


●ワイリーの解
CREATE TABLE Fruits_Unique (row_num, name, price) AS
SELECT ROW_NUMBER() OVER(PARTITION BY name, price ORDER BY name) AS row_num,
       name, price
   FROM Fruits;
 
DELETE FROM Fruits_Unique
WHERE row_num > 1;


●SQL ServerのCTAS
SELECT ROW_NUMBER() OVER(PARTITION BY name, price ORDER BY name) AS row_num,
       name, price
INTO Fruits_Unique
   FROM Fruits;

●MySQLのCTAS
CREATE TABLE Fruits_Unique AS
SELECT ROW_NUMBER() OVER(PARTITION BY name, price ORDER BY name) AS row_num,
       name, price
   FROM Fruits;

●給料テーブル
CREATE TABLE Salary
(emp_name  VARCHAR(32) NOT NULL PRIMARY KEY,
 salary    INTEGER NOT NULL);

 INSERT INTO Salary VALUES('トム',     200000);
 INSERT INTO Salary VALUES('ジョード', 150000);
 INSERT INTO Salary VALUES('ウルフ',   450000);
 INSERT INTO Salary VALUES('クロウ',   250000);


●間違った更新
UPDATE Salary
   SET salary = salary * 1.5
 WHERE salary <= 200000;

UPDATE Salary
   SET salary = salary * 0.8
 WHERE salary <= 300000;


●欠勤テーブル
CREATE TABLE Absenteeism 
(emp_id INTEGER NOT NULL, 
 absent_date DATE NOT NULL, 
 reason CHAR (40) NOT NULL , 
 severity_points INTEGER NOT NULL CHECK (severity_points BETWEEN 0 AND 4),
   CONSTRAINT pk_Absenteeism PRIMARY KEY (emp_id, absent_date)); 

INSERT INTO Absenteeism VALUES(1, '2024-05-01', 'ずる', 4);

-- 長期病欠なので0になる
INSERT INTO Absenteeism VALUES(1, '2024-05-02', '病気', 2);

-- 長期病欠なので0になる
INSERT INTO Absenteeism VALUES(1, '2024-05-03', 'ずる', 2);   

INSERT INTO Absenteeism VALUES(1, '2024-05-05', 'ケガ', 1);

-- 長期病欠なので0になる
INSERT INTO Absenteeism VALUES(1, '2024-05-06', '病気', 3);   

INSERT INTO Absenteeism VALUES(2, '2024-05-01', 'ずる', 4);
INSERT INTO Absenteeism VALUES(2, '2024-05-03', '病気', 2);
INSERT INTO Absenteeism VALUES(2, '2024-05-05', 'サボリ', 2);

-- 長期病欠なので0になる
INSERT INTO Absenteeism VALUES(2, '2024-05-06', 'サボリ', 2); 


