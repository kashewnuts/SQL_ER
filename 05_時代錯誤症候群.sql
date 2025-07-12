
●供給業者テーブル
CREATE TABLE Suppliers
( sup      CHAR(1)     NOT NULL,
  city     VARCHAR(16) NOT NULL,
  area     VARCHAR(16) NOT NULL,
  ship_flg VARCHAR(16) NOT NULL,
  item_cnt INTEGER    NOT NULL,
    CONSTRAINT pk_Suppliers PRIMARY KEY (sup));


INSERT INTO Suppliers VALUES ('A',	'東京',	'北区',   '可',	20);
INSERT INTO Suppliers VALUES ('B',	'東京',	'大田区', '不可',	30);
INSERT INTO Suppliers VALUES ('C',	'東京',	'荒川区', '可',	40);
INSERT INTO Suppliers VALUES ('D',	'東京',	'三鷹市', '可',	10);
INSERT INTO Suppliers VALUES ('E',	'大阪',	'淀川区', '不可',	40);
INSERT INTO Suppliers VALUES ('F',	'大阪',	'堺区',   '不可',	20);
INSERT INTO Suppliers VALUES ('G',	'大阪',	'北区',   '可',	10);
INSERT INTO Suppliers VALUES ('H',	'大阪',	'福島区', '不可',	20);
INSERT INTO Suppliers VALUES ('I',	'大阪',	'東淀川区','可',	30);

●ワイリーの解
SELECT SP.sup, SP.city, SP.ship_flg, SP.item_cnt -- 出荷可能業者のパート
  FROM Suppliers SP
       INNER JOIN
          (SELECT city,
                  SUM(item_cnt) AS able_cnt
             FROM Suppliers
            WHERE ship_flg = '可'
            GROUP BY city) SUM_ITEM
         ON SP.city = SUM_ITEM.city
        AND SP.item_cnt >= (SUM_ITEM.able_cnt * 0.5)
 WHERE SP.ship_flg = '可'
UNION ALL
SELECT SP.sup, SP.city, SP.ship_flg, SP.item_cnt -- 出荷不可能業者のパート
  FROM Suppliers SP
       INNER JOIN
          (SELECT city,
                  SUM(item_cnt) AS disable_cnt
             FROM Suppliers
            WHERE ship_flg = '不可'
            GROUP BY city) SUM_ITEM
         ON SP.city = SUM_ITEM.city
        AND SP.item_cnt >= (SUM_ITEM.disable_cnt * 0.5)
 WHERE SP.ship_flg = '不可';


●ヘレンの解：共通表式を利用
WITH SUM_ITEM AS (
         SELECT city,
                SUM(CASE WHEN ship_flg = '可'   
                         THEN item_cnt 
                         ELSE NULL END) AS able_cnt,
                SUM(CASE WHEN ship_flg = '不可' 
                         THEN item_cnt
                         ELSE NULL END) AS disable_cnt
           FROM Suppliers
          GROUP BY city)
SELECT SP.sup, SP.city, SP.ship_flg, SP.item_cnt
  FROM Suppliers SP
       INNER JOIN SUM_ITEM
          ON SP.city = SUM_ITEM.city
         AND SP.item_cnt >= (SUM_ITEM.able_cnt * 0.5)
 WHERE SP.ship_flg = '可'
UNION ALL
SELECT SP.sup, SP.city, SP.ship_flg, SP.item_cnt
  FROM Suppliers SP
         INNER JOIN SUM_ITEM
            ON SP.city = SUM_ITEM.city
           AND SP.item_cnt >= (SUM_ITEM.disable_cnt * 0.5)
 WHERE SP.ship_flg = '不可';


●ロバートの解：分岐をCASE式で表現
WITH SUM_ITEM AS (
         SELECT city,
                SUM(CASE WHEN ship_flg = '可'   
                         THEN item_cnt 
                         ELSE NULL END) AS able_cnt,
                SUM(CASE WHEN ship_flg = '不可' 
                         THEN item_cnt
                         ELSE NULL END) AS disable_cnt
           FROM Suppliers
          GROUP BY city)
SELECT SP.sup, SP.city, SP.ship_flg, SP.item_cnt
  FROM Suppliers SP
       INNER JOIN SUM_ITEM
          ON SP.city = SUM_ITEM.city
         AND SP.item_cnt >= CASE WHEN SP.ship_flg = '可'   THEN SUM_ITEM.able_cnt
                                 WHEN SP.ship_flg = '不可' THEN SUM_ITEM.disable_cnt
                                 ELSE NULL END * 0.5;

●製造業者テーブル
CREATE TABLE Manufacturers
( mfs      CHAR(1)     NOT NULL,
  city     VARCHAR(16) NOT NULL,
  area     VARCHAR(16) NOT NULL,
  req_flg  VARCHAR(16) NOT NULL,
    CONSTRAINT pk_Manufacturers PRIMARY KEY (mfs));

INSERT INTO Manufacturers VALUES ('a',	'東京',	'北区',  '要');
INSERT INTO Manufacturers VALUES ('b',	'東京',	'荒川区','要');
INSERT INTO Manufacturers VALUES ('c',	'東京',	'江戸川区'  ,'要');
INSERT INTO Manufacturers VALUES ('d',	'大阪',	'淀川区','不要');
INSERT INTO Manufacturers VALUES ('e',	'大阪',	'北区'  ,'不要');
INSERT INTO Manufacturers VALUES ('f',	'大阪',	'福島区','要');


●ワイリーの回答：結果が間違い
SELECT sup, city, area
  FROM Suppliers
 WHERE ship_flg = '可'
   AND city IN (SELECT city
                  FROM Manufacturers
                 WHERE req_flg = '要')
   AND area IN (SELECT area
                  FROM Manufacturers
                  WHERE req_flg = '要');


●ヘレンの解：複数の列を連結して一つのキーとして扱う
SELECT sup, city, area
  FROM Suppliers
 WHERE ship_flg = '可'
   AND city || area IN (SELECT city || area
                          FROM Manufacturers
                         WHERE req_flg = '要');


●ロバートの解：行式を利用
SELECT sup, city, area
  FROM Suppliers
 WHERE ship_flg = '可'
   AND (city, area) IN (SELECT city, area
                          FROM Manufacturers
                         WHERE req_flg = '要');

●(city, area)に対するインデックス作成
CREATE INDEX idx_cityarea ON Suppliers(city, area);
