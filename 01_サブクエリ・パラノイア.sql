

●購入明細テーブル
CREATE TABLE Receipts
(customer_id   CHAR(4) NOT NULL, 
 seq           INTEGER NOT NULL, 
 price         INTEGER NOT NULL, 
   PRIMARY KEY (customer_id, seq));

INSERT INTO Receipts VALUES ('A',   1   ,500    );
INSERT INTO Receipts VALUES ('A',   2   ,1000   );
INSERT INTO Receipts VALUES ('A',   3   ,700    );
INSERT INTO Receipts VALUES ('B',   5   ,100    );
INSERT INTO Receipts VALUES ('B',   6   ,5000   );
INSERT INTO Receipts VALUES ('B',   7   ,300    );
INSERT INTO Receipts VALUES ('B',   9   ,200    );
INSERT INTO Receipts VALUES ('B',   12  ,1000   );
INSERT INTO Receipts VALUES ('C',   10  ,600    );
INSERT INTO Receipts VALUES ('C',   20  ,100    );
INSERT INTO Receipts VALUES ('C',   45  ,200    );
INSERT INTO Receipts VALUES ('C',   70  ,50     );
INSERT INTO Receipts VALUES ('D',   3   ,2000   );


●患者1の解 サブクエリを用いて最小の枝番を取得する
SELECT R1.customer_id, R1.seq, R1.price
  FROM Receipts R1
         INNER JOIN
           (SELECT customer_id, MIN(seq) AS min_seq
              FROM Receipts
             GROUP BY customer_id) R2
    ON R1.customer_id = R2.customer_id
   AND R1.seq = R2.min_seq;


●サブクエリ内部のSELECT文の結果：最小の枝番を取得する
SELECT customer_id, MIN(seq) AS min_seq
  FROM Receipts
 GROUP BY customer_id;

●ロバートの解：FIRST_VALUE関数
SELECT *
  FROM (SELECT customer_id, seq, price,
               FIRST_VALUE(seq) OVER (PARTITION BY customer_id 
                                            ORDER BY seq) AS min_seq
          FROM Receipts) TMP
 WHERE seq = min_seq;

●ウィンドウ関数単独で実行してみる
SELECT customer_id, seq, price,
       FIRST_VALUE(seq) OVER (PARTITION BY customer_id ORDER BY seq) AS min_seq
  FROM Receipts;

●顧客別に最も大きな枝番の購入額を調べる
SELECT *
  FROM (SELECT customer_id, seq, price,
               FIRST_VALUE(seq) OVER (PARTITION BY customer_id 
                                            ORDER BY seq DESC) AS max_seq
          FROM Receipts) TMP
 WHERE seq = max_seq;

●n番目の一般化：ROW_NUMBER関数
SELECT *
  FROM (SELECT customer_id, seq, price,
               ROW_NUMBER() OVER (PARTITION BY customer_id 
                                      ORDER BY seq) AS price_num
          FROM Receipts) TMP
 WHERE price_num = 3;


●株価履歴テーブル
-- SnowflakeではCHECK制約を除去してください
CREATE TABLE StockHistory
(ticker_symbol CHAR(8) NOT NULL,
 sale_date DATE NOT NULL,
 closing_price INTEGER NOT NULL,
 trend INTEGER
    CHECK(trend IN(-1, 0, 1)),
    CONSTRAINT pk_StockHistory PRIMARY KEY (ticker_symbol, sale_date));
    

INSERT INTO StockHistory VALUES('A社',   '2024-04-01', 100, NULL);
INSERT INTO StockHistory VALUES('A社',   '2024-04-02', 200, NULL);
INSERT INTO StockHistory VALUES('A社',   '2024-04-03', 199, NULL);
INSERT INTO StockHistory VALUES('A社',   '2024-04-04', 199, NULL);
INSERT INTO StockHistory VALUES('B商事', '2024-10-10',  10, NULL);
INSERT INTO StockHistory VALUES('B商事', '2024-04-14',  20, NULL);
INSERT INTO StockHistory VALUES('B商事', '2024-04-20',   5, NULL);
INSERT INTO StockHistory VALUES('C鉄鋼', '2024-05-01', 156, NULL);
INSERT INTO StockHistory VALUES('C鉄鋼', '2024-05-03', 182, NULL);
INSERT INTO StockHistory VALUES('C鉄鋼', '2024-05-05', 182, NULL);
INSERT INTO StockHistory VALUES('C鉄鋼', '2024-05-05', 182, NULL);

●患者2の解：相関サブクエリのネストが深い(MySQLでは動作しない)
UPDATE StockHistory
   SET trend
       = COALESCE(SIGN(closing_price
         - (SELECT H1.closing_price
              FROM StockHistory H1
             WHERE H1.ticker_symbol = StockHistory.ticker_symbol
               AND H1.sale_date =
                   (SELECT MAX(sale_date)
                      FROM StockHistory H2
                     WHERE H2.ticker_symbol
                           = StockHistory.ticker_symbol
                       AND H2.sale_date
                           < StockHistory.sale_date))),0);

●患者2の解：相関サブクエリのネストが深い(MySQLでも動作する)
UPDATE StockHistory
   SET trend
       = COALESCE(SIGN(closing_price
         - (SELECT TMP2.closing_price
              FROM (
                SELECT H1.closing_price
                  FROM StockHistory H1
                 WHERE H1.ticker_symbol = StockHistory.ticker_symbol
                   AND H1.sale_date =
                       (
                         SELECT tmp1.sale_date
                         FROM (
                           SELECT MAX(sale_date) AS sale_date
                             FROM StockHistory H2
                           WHERE H2.ticker_symbol
                                 = StockHistory.ticker_symbol
                             AND H2.sale_date
                                 < StockHistory.sale_date
                          ) TMP1
                       ) 
                 ) TMP2 )),0);




●ワイリーの解：エラーになる
UPDATE StockHistory
   SET trend = COALESCE(SIGN(closing_price
                  - (SELECT LAG(closing_price, 1) 
                                OVER (PARTITION BY ticker_symbol 
                                          ORDER BY sale_date) 
                       FROM StockHistory)) ,0);



●ワイリーの解２：やっぱりエラーになる
UPDATE StockHistory
   SET trend = COALESCE(SIGN(closing_price
                  - (SELECT LAG(closing_price, 1) 
                                OVER (PARTITION BY ticker_symbol 
                                          ORDER BY sale_date)
                       FROM StockHistory SH1)) ,0)
WHERE StockHistory.ticker_symbol = SH1.ticker_symbol
  AND StockHistory.sale_date = SH1.sale_date;


●ウィンドウ関数による解。共通表式を使う
WITH PRE_SH (ticker_symbol, sale_date, trend) AS 
(SELECT ticker_symbol, sale_date, 
        COALESCE(SIGN(closing_price - 
                  MAX(closing_price) 
                      OVER (PARTITION BY ticker_symbol 
                                ORDER BY sale_date
                            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)) ,0)  
  FROM StockHistory)
UPDATE StockHistory
   SET trend = (SELECT PRE_SH.trend
                  FROM PRE_SH
                 WHERE StockHistory.ticker_symbol = PRE_SH.ticker_symbol
                   AND StockHistory.sale_date = PRE_SH.sale_date);


●ヘレンの解：LAG関数を使う
WITH PRE_SH (ticker_symbol, sale_date, trend) AS 
(SELECT ticker_symbol, sale_date, 
        COALESCE(SIGN(closing_price - 
                  LAG(closing_price, 1) 
                      OVER (PARTITION BY ticker_symbol 
                                ORDER BY sale_date)) ,0)  
  FROM StockHistory)
UPDATE StockHistory
   SET trend = (SELECT PRE_SH.trend
                  FROM PRE_SH
                 WHERE StockHistory.ticker_symbol = PRE_SH.ticker_symbol
                   AND StockHistory.sale_date = PRE_SH.sale_date);


●Oracle向けの解：ウィンドウ関数でビューを定義する
CREATE VIEW PRE_SH (ticker_symbol, sale_date, closing_price, trend) 
AS (SELECT ticker_symbol, sale_date, closing_price,
           COALESCE(SIGN(closing_price - 
                          LAG(closing_price, 1) 
                             OVER (PARTITION BY ticker_symbol 
                                       ORDER BY sale_date)) ,0)
      FROM StockHistory);


●Oracleでも動作する解：ビューを使う（※Snowflakeではこの解もエラーになる）
UPDATE StockHistory
   SET trend = (SELECT PRE_SH.trend
                  FROM PRE_SH
                 WHERE StockHistory.ticker_symbol = PRE_SH.ticker_symbol
                   AND StockHistory.sale_date = PRE_SH.sale_date);


●UPDATE対象のテーブルに相関名を付けたSQL（SQL Serverでのみエラーになる）
WITH PRE_SH (ticker_symbol, sale_date, trend) AS 
(SELECT ticker_symbol, sale_date, 
        COALESCE(SIGN(closing_price - 
                  LAG(closing_price, 1) 
                      OVER (PARTITION BY ticker_symbol 
                                ORDER BY sale_date)) ,0)  
  FROM StockHistory)
UPDATE StockHistory SH
   SET trend = (SELECT PRE_SH.trend
                  FROM PRE_SH
                 WHERE SH.ticker_symbol = PRE_SH.ticker_symbol
                   AND SH.sale_date = PRE_SH.sale_date);


●要素テーブル
CREATE TABLE Elements
(lvl INTEGER NOT NULL,
 color VARCHAR(10),
 length INTEGER,
 width INTEGER,
 hgt INTEGER,
   CONSTRAINT pk_Elements PRIMARY KEY(lvl) );

INSERT INTO Elements VALUES (1, 'RED', 8, 10, 12);
INSERT INTO Elements VALUES (2, NULL, NULL, NULL, 20);
INSERT INTO Elements VALUES (3, NULL, 9, 82, 25);
INSERT INTO Elements VALUES (4, 'BLUE', NULL, 67, NULL);
INSERT INTO Elements VALUES (5, 'GRAY', NULL, NULL, NULL);

●患者のクエリ
SELECT (SELECT color  FROM Elements WHERE lvl = M.lc) AS color,
       (SELECT length FROM Elements WHERE lvl = M.ll) AS length,
       (SELECT width  FROM Elements WHERE lvl = M.lw) AS width,
       (SELECT hgt    FROM Elements WHERE lvl = M.lh) AS hgt
  FROM (SELECT MAX(CASE WHEN color IS NOT NULL
                        THEN lvl END) AS lc,
               MAX(CASE WHEN length IS NOT NULL
                        THEN lvl END) AS ll,
               MAX(CASE WHEN width IS NOT NULL
                        THEN lvl END) AS lw,
               MAX(CASE WHEN hgt IS NOT NULL
                        THEN lvl END) AS lh
          FROM Elements)  M;

●IGNORE NULLSオプション付きウィンドウ関数
SELECT MAX(color_max),
       MAX(length_max),
       MAX(width_max),
       MAX(hgt_max)
  FROM (SELECT FIRST_VALUE(color)  IGNORE NULLS OVER(ORDER BY lvl DESC) color_max,
               FIRST_VALUE(length) IGNORE NULLS OVER(ORDER BY lvl DESC) length_max,
               FIRST_VALUE(width)  IGNORE NULLS OVER(ORDER BY lvl DESC) width_max,
               FIRST_VALUE(hgt)    IGNORE NULLS OVER(ORDER BY lvl DESC) hgt_max
          FROM Elements) TMP;

●LAST_VALUEを使う（間違い）
SELECT *  FROM (SELECT customer_id, seq, price, 
                       LAST_VALUE(seq) OVER (PARTITION BY customer_id
                                                   ORDER BY seq) AS max_seq
                 FROM Receipts) 
 WHERE seq = max_seq;
