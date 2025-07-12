●サーバ負荷テーブル
CREATE TABLE ServerLoad
( server_id CHAR(1) NOT NULL, 
  time TIMESTAMP NOT NULL,
  server_load INTEGER NOT NULL,
    PRIMARY KEY(server_id, time));

INSERT INTO ServerLoad VALUES ('A', '2024-06-01 00:00:00', 50);
INSERT INTO ServerLoad VALUES ('A', '2024-06-01 00:00:15', 45);
INSERT INTO ServerLoad VALUES ('A', '2024-06-01 00:00:30', 38);
INSERT INTO ServerLoad VALUES ('A', '2024-06-01 00:00:45', 70);
INSERT INTO ServerLoad VALUES ('B', '2024-06-01 00:00:00', 80);
INSERT INTO ServerLoad VALUES ('B', '2024-06-01 00:00:15',100);
INSERT INTO ServerLoad VALUES ('B', '2024-06-01 00:00:30', 90);
INSERT INTO ServerLoad VALUES ('B', '2024-06-01 00:00:45', 60);


●サブクエリによる前の行の取得
SELECT server_id, time, server_load,
       server_load - (SELECT server_load
                        FROM ServerLoad SL2
                       WHERE SL1.server_id = SL2.server_id
                         AND time = (SELECT MAX(time)
                                       FROM ServerLoad SL3
                                      WHERE SL3.server_id = SL2.server_id 
                                        AND SL1.time > SL3.time)) diff
  FROM ServerLoad SL1;


●ワイリーの解(ウィンドウ関数)
SELECT server_id, time, server_load,
       MAX(server_load) OVER (PARTITION BY server_id ORDER BY time
                              ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING) old_load,
       server_load - MAX(server_load) OVER (PARTITION BY server_id ORDER BY time
                                            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING) diff
  FROM ServerLoad;


●ヘレンの解：LAG関数を使う
SELECT server_id, time, server_load,
       LAG(server_load, 1) OVER(PARTITION BY server_id ORDER BY time) old_load,
       server_load - LAG(server_load,1) OVER(PARTITION BY server_id ORDER BY time) diff_load
  FROM ServerLoad;

●ロバートの解：ウィンドウ定義をまとめる
SELECT server_id, time, server_load,
       LAG(server_load,1) OVER WINDOW_LAG old_load,
       server_load - LAG(server_load,1) OVER WINDOW_LAG diff_load
  FROM ServerLoad
  WINDOW WINDOW_LAG AS (PARTITION BY server_id ORDER BY time);


●株価テーブル
CREATE TABLE StockPrice 
(company CHAR(8) NOT NULL,
 time TIMESTAMP NOT NULL,
 price INTEGER NOT NULL,
   CONSTRAINT pk_StockPrice PRIMARY KEY (company,time));

INSERT INTO StockPrice  VALUES('A社', '2024-06-01 00:00:00', 273);
INSERT INTO StockPrice  VALUES('A社', '2024-06-01 00:10:00', 560);
INSERT INTO StockPrice  VALUES('A社', '2024-06-01 00:55:00', 145);
INSERT INTO StockPrice  VALUES('A社', '2024-06-01 01:22:00', 800);
INSERT INTO StockPrice  VALUES('B社', '2024-07-01 00:00:00', 156);
INSERT INTO StockPrice  VALUES('B社', '2024-07-02 17:00:20',  40);
INSERT INTO StockPrice  VALUES('B社', '2024-07-02 18:32:11', 123);
INSERT INTO StockPrice  VALUES('B社', '2024-07-02 23:45:21', 907);


●患者のコード
SELECT company, time, 
       price - (SELECT price
                  FROM StockPrice SP1
                 WHERE SP1.company = SP3.company
                   AND time = (SELECT MIN(time)
                                 FROM StockPrice SP2
                                WHERE SP1.company = SP2.company)) AS diff
  FROM StockPrice SP3;

●ワイリーの解：FIRST_VALUE関数
SELECT company, time, price,
       FIRST_VALUE(price) OVER WINDOW_FIRST start_value,
       price - FIRST_VALUE(price) OVER WINDOW_FIRST diff
  FROM StockPrice 
  WINDOW WINDOW_FIRST AS (PARTITION BY company ORDER BY time);


●省略テーブル
CREATE TABLE OmitTbl
(keycol CHAR(8) NOT NULL,
 seq    INTEGER NOT NULL,
 val    INTEGER ,
  CONSTRAINT pk_OmitTbl PRIMARY KEY (keycol, seq));

INSERT INTO OmitTbl VALUES ('A', 1, 50);
INSERT INTO OmitTbl VALUES ('A', 2, NULL);
INSERT INTO OmitTbl VALUES ('A', 3, NULL);
INSERT INTO OmitTbl VALUES ('A', 4, 70);
INSERT INTO OmitTbl VALUES ('A', 5, NULL);
INSERT INTO OmitTbl VALUES ('A', 6, 900);
INSERT INTO OmitTbl VALUES ('B', 1, 10);
INSERT INTO OmitTbl VALUES ('B', 2, 20);
INSERT INTO OmitTbl VALUES ('B', 3, NULL);
INSERT INTO OmitTbl VALUES ('B', 4, 3);
INSERT INTO OmitTbl VALUES ('B', 5, NULL);
INSERT INTO OmitTbl VALUES ('B', 6, NULL);


●患者3のコード：UPDATE文で相関サブクエリを用いている
UPDATE OmitTbl
   SET val = (SELECT val
                FROM OmitTbl O1
               WHERE O1.keycol = OmitTbl.keycol				
                 AND O1.seq = (SELECT MAX(seq)
                                FROM OmitTbl O2
                               WHERE O2.keycol = OmitTbl.keycol
                                 AND O2.seq < OmitTbl.seq    
                                 AND O2.val IS NOT NULL))   
 WHERE val IS NULL;


●NULLを埋め立てるSELECT文：IGNORE NULLSオプション
SELECT keycol, seq,
       LAST_VALUE(val) IGNORE NULLS 
               OVER(PARTITION BY keycol 
                        ORDER BY seq)
  FROM OmitTbl;


●NULLを埋め立てるUPDATE文：ウィンドウ関数を使う
CREATE VIEW NoNULL (keycol, seq, val) AS
(SELECT keycol, seq,
        LAST_VALUE(val) IGNORE NULLS 
                OVER(PARTITION BY keycol 
                        ORDER BY seq)
  FROM OmitTbl);

UPDATE OmitTbl
   SET val = (SELECT val
                FROM NoNULL NN
               WHERE OmitTbl.keycol = NN.keycol
                 AND OmitTbl.seq = NN.seq)
 WHERE val IS NULL;

●座席テーブル
CREATE TABLE Seats
(seat   INTEGER NOT NULL,
 status CHAR(1) NOT NULL
   CHECK (status IN ('E', 'O')),
   CONSTRAINT pk_Sales PRIMARY KEY(seat));  -- Empty or Occupied

INSERT INTO Seats VALUES (1,  'O');
INSERT INTO Seats VALUES (2,  'O');
INSERT INTO Seats VALUES (3,  'E');
INSERT INTO Seats VALUES (4,  'E');
INSERT INTO Seats VALUES (5,  'E');
INSERT INTO Seats VALUES (6,  'O');
INSERT INTO Seats VALUES (7,  'E');
INSERT INTO Seats VALUES (8,  'E');
INSERT INTO Seats VALUES (9,  'E');
INSERT INTO Seats VALUES (10, 'E');
INSERT INTO Seats VALUES (11, 'E');
INSERT INTO Seats VALUES (12, 'O');
INSERT INTO Seats VALUES (13, 'O');
INSERT INTO Seats VALUES (14, 'E');
INSERT INTO Seats VALUES (15, 'E');


●座席テーブル2
CREATE TABLE Seats2
 ( seat   INTEGER NOT NULL,
   line_id CHAR(1) NOT NULL,
   status CHAR(1) NOT NULL
     CHECK (status IN ('E', 'O')),
     CONSTRAINT pk_Seats2 PRIMARY KEY(seat)); 

INSERT INTO Seats2 VALUES (1, 'A', 'O');
INSERT INTO Seats2 VALUES (2, 'A', 'O');
INSERT INTO Seats2 VALUES (3, 'A', 'E');
INSERT INTO Seats2 VALUES (4, 'A', 'E');
INSERT INTO Seats2 VALUES (5, 'A', 'E');
INSERT INTO Seats2 VALUES (6, 'B', 'O');
INSERT INTO Seats2 VALUES (7, 'B', 'O');
INSERT INTO Seats2 VALUES (8, 'B', 'E');
INSERT INTO Seats2 VALUES (9, 'B', 'E');
INSERT INTO Seats2 VALUES (10,'B', 'E');
INSERT INTO Seats2 VALUES (11,'C', 'E');
INSERT INTO Seats2 VALUES (12,'C', 'E');
INSERT INTO Seats2 VALUES (13,'C', 'E');
INSERT INTO Seats2 VALUES (14,'C', 'O');
INSERT INTO Seats2 VALUES (15,'C', 'E');

