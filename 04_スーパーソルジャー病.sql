●注文テーブル
CREATE TABLE Orders
( order_id   INTEGER     NOT NULL,
  order_shop VARCHAR(32) NOT NULL,
  order_name VARCHAR(32) NOT NULL,
  order_date DATE,
    CONSTRAINT pk_Orders PRIMARY KEY (order_id));

INSERT INTO Orders VALUES (10000,	'東京',	'後藤信二',		'2024-08-22');
INSERT INTO Orders VALUES (10001,	'埼玉',	'佐原商店',		'2024-09-01');
INSERT INTO Orders VALUES (10002,	'千葉',	'水原陽子',		'2024-09-20');
INSERT INTO Orders VALUES (10003,	'山形',	'加地健太郎',	'2024-08-05');
INSERT INTO Orders VALUES (10004,	'青森',	'相原酒店',		'2024-08-22');
INSERT INTO Orders VALUES (10005,	'長野',	'宮元雄介',		'2024-08-29');

●注文明細テーブル
CREATE TABLE OrderReceipts
( order_id          INTEGER     NOT NULL,
  order_receipt_id  INTEGER     NOT NULL,
  item_group        VARCHAR(32) NOT NULL,
  delivery_date     DATE        NOT NULL,
    CONSTRAINT pk_OrderReceipts PRIMARY KEY (order_id, order_receipt_id),
    CONSTRAINT fk_OrderReceipts FOREIGN KEY (order_id) REFERENCES Orders(order_id));

INSERT INTO OrderReceipts VALUES (10000,	1,	'食器',				    '2024-08-24');
INSERT INTO OrderReceipts VALUES (10000,	2,	'菓子詰め合わせ',	'2024-08-25');
INSERT INTO OrderReceipts VALUES (10000,	3,	'牛肉',				    '2024-08-26');
INSERT INTO OrderReceipts VALUES (10001,	1,	'魚介類',			    '2024-09-04');
INSERT INTO OrderReceipts VALUES (10002,	1,	'菓子詰め合わせ',	'2024-09-22');
INSERT INTO OrderReceipts VALUES (10002,	2,	'調味料セット',		'2024-09-22');
INSERT INTO OrderReceipts VALUES (10003,	1,	'米',				  '2024-08-06');
INSERT INTO OrderReceipts VALUES (10003,	2,	'牛肉',				'2024-08-10');
INSERT INTO OrderReceipts VALUES (10003,	3,	'食器',				'2024-08-10');
INSERT INTO OrderReceipts VALUES (10004,	1,	'野菜',				'2024-08-23');
INSERT INTO OrderReceipts VALUES (10005,	1,	'飲料水',			'2024-08-30');
INSERT INTO OrderReceipts VALUES (10005,	2,	'菓子詰め合わせ',	'2024-08-30');

●ワイリーの解：WHERE句に間違いあり
SELECT O.order_id,
       O.order_name,
       ORC.delivery_date - O.order_date AS diff_days
  FROM Orders O 
       INNER JOIN OrderReceipts ORC
          ON O.order_id = ORC.order_id
 WHERE diff_days >= 3;


●ワイリーの解：修正版
SELECT O.order_id,
       O.order_name,
       ORC.delivery_date - O.order_date AS diff_days
  FROM Orders O 
       INNER JOIN OrderReceipts ORC
          ON O.order_id = ORC.order_id
 WHERE ORC.delivery_date - O.order_date >= 3;


●SQL Serverでの日付の減算
SELECT O.order_id,
       O.order_name,
       DATEDIFF(DAY, O.order_date, ORC.delivery_date) AS diff_days
  FROM Orders O 
       INNER JOIN OrderReceipts ORC
          ON O.order_id = ORC.order_id
 WHERE CAST(DATEDIFF(DAY, O.order_date, ORC.delivery_date) AS INTEGER) >=  3;


●ヘレンの解：MAX関数を使う
SELECT O.order_id,
       MAX(O.order_name),
       MAX(ORC.delivery_date - O.order_date) AS max_diff_days
  FROM Orders O 
       INNER JOIN OrderReceipts ORC
          ON O.order_id = ORC.order_id
 WHERE ORC.delivery_date - O.order_date >= 3
 GROUP BY O.order_id;


●ワイリーの解：MAX関数を使う
SELECT O.order_id,
       MAX(O.order_name) AS order_name,
       MAX(O.order_date) AS order_date,
       COUNT(*) AS item_count
  FROM Orders O
       INNER JOIN OrderReceipts ORC
       ON O.order_id = ORC.order_id
GROUP BY O.order_id;


●ヘレンの解：ウィンドウ関数を使う
SELECT DISTINCT O.order_id, O.order_name, O.order_date,
       COUNT(*) OVER (PARTITION BY O.order_id) AS item_count
  FROM Orders O
       INNER JOIN OrderReceipts ORC
       ON O.order_id = ORC.order_id;

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
    