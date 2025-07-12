
●OTLTテーブル定義
CREATE TABLE OTLT 
(code_type          VARCHAR(32),
 code               VARCHAR(32),
 code_description   VARCHAR(32),
   CONSTRAINT pk_OTLT PRIMARY KEY (code_type, code));

INSERT INTO OTLT VALUES('pref_cd', '01', '北海道');
INSERT INTO OTLT VALUES('pref_cd', '02', '青森県');
INSERT INTO OTLT VALUES('pref_cd', '03', '岩手県');
INSERT INTO OTLT VALUES('pref_cd', '04', '宮城県');
INSERT INTO OTLT VALUES('pref_cd', '05', '秋田県');
INSERT INTO OTLT VALUES('pref_cd', '06', '山形県');
INSERT INTO OTLT VALUES('pref_cd', '07', '福島県');
INSERT INTO OTLT VALUES('pref_cd', '08', '茨城県');
INSERT INTO OTLT VALUES('pref_cd', '09', '栃木県');
INSERT INTO OTLT VALUES('pref_cd', '10', '群馬県');
INSERT INTO OTLT VALUES('pref_cd', '11', '埼玉県');
INSERT INTO OTLT VALUES('pref_cd', '12', '千葉県');
INSERT INTO OTLT VALUES('pref_cd', '13', '東京都');
INSERT INTO OTLT VALUES('pref_cd', '14', '神奈川県');
INSERT INTO OTLT VALUES('pref_cd', '15', '新潟県');
INSERT INTO OTLT VALUES('pref_cd', '16', '富山県');
INSERT INTO OTLT VALUES('pref_cd', '17', '石川県');
INSERT INTO OTLT VALUES('pref_cd', '18', '福井県');
INSERT INTO OTLT VALUES('pref_cd', '19', '山梨県');
INSERT INTO OTLT VALUES('pref_cd', '20', '長野県');
INSERT INTO OTLT VALUES('pref_cd', '21', '岐阜県');
INSERT INTO OTLT VALUES('pref_cd', '22', '静岡県');
INSERT INTO OTLT VALUES('pref_cd', '23', '愛知県');
INSERT INTO OTLT VALUES('pref_cd', '24', '三重県');
INSERT INTO OTLT VALUES('pref_cd', '25', '滋賀県');
INSERT INTO OTLT VALUES('pref_cd', '26', '京都府');
INSERT INTO OTLT VALUES('pref_cd', '27', '大阪府');
INSERT INTO OTLT VALUES('pref_cd', '28', '兵庫県');
INSERT INTO OTLT VALUES('pref_cd', '29', '奈良県');
INSERT INTO OTLT VALUES('pref_cd', '30', '和歌山県');
INSERT INTO OTLT VALUES('pref_cd', '31', '鳥取県');
INSERT INTO OTLT VALUES('pref_cd', '32', '島根県');
INSERT INTO OTLT VALUES('pref_cd', '33', '岡山県');
INSERT INTO OTLT VALUES('pref_cd', '34', '広島県');
INSERT INTO OTLT VALUES('pref_cd', '35', '山口県');
INSERT INTO OTLT VALUES('pref_cd', '36', '徳島県');
INSERT INTO OTLT VALUES('pref_cd', '37', '香川県');
INSERT INTO OTLT VALUES('pref_cd', '38', '愛媛県');
INSERT INTO OTLT VALUES('pref_cd', '39', '高知県');
INSERT INTO OTLT VALUES('pref_cd', '40', '福岡県');
INSERT INTO OTLT VALUES('pref_cd', '41', '佐賀県');
INSERT INTO OTLT VALUES('pref_cd', '42', '長崎県');
INSERT INTO OTLT VALUES('pref_cd', '43', '熊本県');
INSERT INTO OTLT VALUES('pref_cd', '44', '大分県');
INSERT INTO OTLT VALUES('pref_cd', '45', '宮崎県');
INSERT INTO OTLT VALUES('pref_cd', '46', '鹿児島県');
INSERT INTO OTLT VALUES('pref_cd', '47', '沖縄県');
INSERT INTO OTLT VALUES('company_cd', 'A001', 'A商社');
INSERT INTO OTLT VALUES('company_cd', 'B002', 'B建設');
INSERT INTO OTLT VALUES('company_cd', 'Z027', 'Z化学');
INSERT INTO OTLT VALUES('sex_cd', '0', '不明');
INSERT INTO OTLT VALUES('sex_cd', '1', '男');
INSERT INTO OTLT VALUES('sex_cd', '2', '女');
INSERT INTO OTLT VALUES('sex_cd', '9', '適用不能');

CREATE TABLE DataPop
(pref_cd   VARCHAR(32) NOT NULL,
 pref_name VARCHAR(32) NOT NULL,
 population INTEGER NOT NULL,
   CONSTRAINT pk_DataPop PRIMARY KEY (pref_cd));

INSERT INTO DataPop VALUES('01', '北海道', 1000);
INSERT INTO DataPop VALUES('03', '秋田県', 2000);
INSERT INTO DataPop VALUES('04', '岩手県', 1200);
INSERT INTO DataPop VALUES('05', '宮城県', 5000);
INSERT INTO DataPop VALUES('07', '福島県', 8000);


●患者1のクエリ：OTLTテーブルとの外部結合
SELECT MASTER.code AS pref_cd,
         MASTER.code_description AS pref_name,
       DATA.population AS pop
  FROM OTLT MASTER LEFT OUTER JOIN DataPop DATA
    ON MASTER.code = DATA.pref_cd
 WHERE MASTER.code_type = 'pref_cd';


CREATE TABLE OTLT_INTERVAL
(code_type  VARCHAR(128) NOT NULL,
 code_value VARCHAR(128) NOT NULL,
 start_year INTEGER      NOT NULL,
 end_year   INTEGER      ,
 code_description VARCHAR(128) NOT NULL,
   CONSTRAINT pk_OTLT_INTERVAL PRIMARY KEY (code_type, code_value, start_year) );

INSERT INTO OTLT_INTERVAL VALUES('age_class', '01', 1998, 2000, '0歳以上15歳未満');
INSERT INTO OTLT_INTERVAL VALUES('age_class', '02', 1998, 2000, '15歳以上20歳未満');
INSERT INTO OTLT_INTERVAL VALUES('age_class', '03', 1998, 2000, '20歳以上30歳未満');
INSERT INTO OTLT_INTERVAL VALUES('age_class', '04', 1998, 2000, '30歳以上40歳未満');
INSERT INTO OTLT_INTERVAL VALUES('age_class', '05', 1998, 2000, '40歳以上50歳未満');
INSERT INTO OTLT_INTERVAL VALUES('age_class', '06', 1998, 2000, '50歳以上');
INSERT INTO OTLT_INTERVAL VALUES('age_class', '01', 2001, 2003, '0歳以上20歳未満');
INSERT INTO OTLT_INTERVAL VALUES('age_class', '02', 2001, 2003, '20歳以上40歳未満');
INSERT INTO OTLT_INTERVAL VALUES('age_class', '03', 2001, 2003, '40歳以上60歳未満');
INSERT INTO OTLT_INTERVAL VALUES('age_class', '04', 2001, 2003, '60歳以上80歳未満');
INSERT INTO OTLT_INTERVAL VALUES('age_class', '05', 2001, 2003, '80歳以上');
INSERT INTO OTLT_INTERVAL VALUES('age_class', '01', 2004, 9999, '0歳以上15歳未満');
INSERT INTO OTLT_INTERVAL VALUES('age_class', '02', 2004, 9999, '15歳以上30歳未満');
INSERT INTO OTLT_INTERVAL VALUES('age_class', '03', 2004, 9999, '30歳以上45歳未満');
INSERT INTO OTLT_INTERVAL VALUES('age_class', '04', 2004, 9999, '45歳以上60歳未満');
INSERT INTO OTLT_INTERVAL VALUES('age_class', '05', 2004, 9999, '60歳以上75歳未満');
INSERT INTO OTLT_INTERVAL VALUES('age_class', '06', 2004, 9999, '75歳以上');


-- end_yearがNULLのデータ
INSERT INTO OTLT_INTERVAL VALUES('age_class', '01', 2004, NULL, '0歳以上15歳未満');
INSERT INTO OTLT_INTERVAL VALUES('age_class', '02', 2004, NULL, '15歳以上30歳未満');
INSERT INTO OTLT_INTERVAL VALUES('age_class', '03', 2004, NULL, '30歳以上45歳未満');
INSERT INTO OTLT_INTERVAL VALUES('age_class', '04', 2004, NULL, '45歳以上60歳未満');
INSERT INTO OTLT_INTERVAL VALUES('age_class', '05', 2004, NULL, '60歳以上75歳未満');
INSERT INTO OTLT_INTERVAL VALUES('age_class', '06', 2004, NULL, '75歳以上');


●end_yearがNULLだと、比較結果がunknownとなり1行も選択されない
SELECT code_value, code_description
  FROM OTLT_INTERVAL
 WHERE 2005 BETWEEN start_year AND end_year;


●口座列持ちテーブル
CREATE TABLE AccountsCols
(act_nbr  CHAR(6) NOT NULL,
 amt_2024 INTEGER,
 amt_2025 INTEGER,
 amt_2026 INTEGER,
   CONSTRAINT pk_AccountsCols PRIMARY KEY(act_nbr) );

INSERT INTO AccountsCols VALUES ('007634',	320000,	490000,	120000);
INSERT INTO AccountsCols VALUES ('135981',	88000,	90000,	100000);
INSERT INTO AccountsCols VALUES ('447900',	2348900, NULL,		9000);
INSERT INTO AccountsCols VALUES ('238901',	2348900, NULL,		9000);


●すべての年度について、残高が100,000円以上の口座を選択する（列持ちの場合）
SELECT act_nbr
  FROM AccountsCols
 WHERE amt_2024 >= 100000
   AND amt_2025 >= 100000
   AND amt_2026 >= 100000;


●テーブル定義（行持ち）
CREATE TABLE AccountsRows
(act_nbr  CHAR(6) NOT NULL,
 year     INTEGER NOT NULL,
 amt      INTEGER NOT NULL,
   CONSTRAINT pk_AccountsRows PRIMARY KEY(act_nbr, year) );

INSERT INTO AccountsRows VALUES ('007634',	2006,	320000);
INSERT INTO AccountsRows VALUES ('007634',	2007,	490000);
INSERT INTO AccountsRows VALUES ('007634',	2008,	120000);
INSERT INTO AccountsRows VALUES ('135981',	2006,	88000);
INSERT INTO AccountsRows VALUES ('135981',	2007,	90000);
INSERT INTO AccountsRows VALUES ('135981',	2008,	100000);
INSERT INTO AccountsRows VALUES ('447900',	2006,	2348900);
INSERT INTO AccountsRows VALUES ('447900',	2008,	9000);
INSERT INTO AccountsRows VALUES ('238901',	2007,	5000);

●行持ちテーブルなら簡単なクエリでOK
SELECT act_nbr
  FROM AccountsRows
 GROUP BY act_nbr
HAVING COUNT(*) = SUM(CASE WHEN amt >= 100000
                           THEN 1
                           ELSE 0 END);


●全残高を0クリア（列持ちバージョン）
UPDATE AccountsCols
   SET amt_2024 = 0,
       amt_2025 = 0,
       amt_2026 = 0;

●全残高を0クリア（行持ちバージョン）
UPDATE AccountsRows
   SET amt = 0;

CREATE TABLE Items
(item_no   CHAR(3)  NOT NULL,
 item_name CHAR(16) NOT NULL,
 price     INTEGER  NOT NULL,
   CONSTRAINT pk_Items PRIMARY KEY(item_no) );

INSERT INTO Items VALUES('001',	'洗剤',	400);
INSERT INTO Items VALUES('002',	'パン',	200);
INSERT INTO Items VALUES('003',	'ボールペン',	100);
INSERT INTO Items VALUES('004',	'しゃもじ',	300);
INSERT INTO Items VALUES('005',	'クッキー',	550);
INSERT INTO Items VALUES('006',	'ビール',	280);
INSERT INTO Items VALUES('007',	'はさみ',	350);
INSERT INTO Items VALUES('008',	'コップ',	600);
INSERT INTO Items VALUES('009',	'箸',	320);


●集計キーを追加するクエリ（Oracle／SQL Server）
ALTER TABLE Items ADD item_grp CHAR(3);

●集計キーを追加するクエリ（PostgreSQL／MySQL／Db2）
ALTER TABLE Items ADD COLUMN item_grp CHAR(3);

UPDATE Items
   SET item_grp = CASE WHEN item_no IN ('001', '004', '008', '009') THEN 'A'
                       WHEN item_no IN ('002', '005', '006') THEN 'B'
                       WHEN item_no IN ('003', '007') THEN 'C'
                       ELSE NULL END;

●集計キーを利用してSELECT
SELECT item_grp,
       ROUND(AVG(price), 0) AS avg_price
  FROM Items
 GROUP BY item_grp;


●使い捨て集約キーのクエリ
SELECT CASE WHEN item_no IN ('001', '004', '008', '009') THEN 'A'
            WHEN item_no IN ('002', '005', '006') THEN 'B'
            WHEN item_no IN ('003', '007') THEN 'C'
            ELSE NULL END AS item_group,
       AVG(price) AS avg_price
  FROM Items
 GROUP BY item_group;

●会員テーブル
CREATE TABLE Customers
(customer_id   CHAR(4) NOT NULL,
 age           INTEGER NOT NULL,
 sex           CHAR(1) NOT NULL,
 status        CHAR(16) NOT NULL CHECK(status IN ('一般', 'プレミア')),
   CONSTRAINT pk_Customers PRIMARY KEY(customer_id) );

INSERT INTO Customers VALUES ('0001', 42, 'm', '一般');
INSERT INTO Customers VALUES ('0002', 27, 'f', '一般');
INSERT INTO Customers VALUES ('0003', 30, 'm', 'プレミア');
INSERT INTO Customers VALUES ('0004', 62, 'f', 'プレミア');

●会員テーブル（一般）
CREATE TABLE Customers_General
(customer_id   CHAR(4) NOT NULL,
 age           INTEGER NOT NULL,
 sex           CHAR(1) NOT NULL,
   CONSTRAINT pk_Customers_General PRIMARY KEY(customer_id) );

INSERT INTO Customers_General VALUES ('0001', 42, 'm');
INSERT INTO Customers_General VALUES ('0002', 27, 'f');

●会員テーブル（プレミア）
CREATE TABLE Customers_Premier
(customer_id   CHAR(4) NOT NULL,
 age           INTEGER NOT NULL,
 sex           CHAR(1) NOT NULL,
   CONSTRAINT pk_Customers_Premier_Female PRIMARY KEY(customer_id) );

INSERT INTO Customers_Premier VALUES ('0003', 30, 'm');
INSERT INTO Customers_Premier VALUES ('0004', 62, 'f');

/* パーティション化テーブル（Oracle／MySQL） */
CREATE TABLE SalesPartition (
    sales_id   INTEGER NOT NULL,
    sales_date DATE NOT NULL,
    sales_year INTEGER,
      CONSTRAINT pk_SalesPartition PRIMARY KEY (sales_id, sales_year))
         PARTITION BY RANGE (sales_year) (
         PARTITION p0 VALUES LESS THAN (2020),
         PARTITION p1 VALUES LESS THAN (2021),
         PARTITION p2 VALUES LESS THAN (2022),
         PARTITION p3 VALUES LESS THAN (2023),
         PARTITION p4 VALUES LESS THAN (2024));

/* パーティション化テーブル（PostgreSQL） */

CREATE TABLE SalesPartition (
    sales_id   INTEGER NOT NULL,
    sales_date DATE NOT NULL,
    sales_year INTEGER,
      CONSTRAINT pk_SalesPartition PRIMARY KEY (sales_id, sales_year)) 
PARTITION BY RANGE (sales_year);

CREATE TABLE p0 PARTITION OF SalesPartition FOR VALUES FROM (2020) to (2021);
CREATE TABLE p1 PARTITION OF SalesPartition FOR VALUES FROM (2021) to (2022);
CREATE TABLE p2 PARTITION OF SalesPartition FOR VALUES FROM (2022) to (2023);
CREATE TABLE p3 PARTITION OF SalesPartition FOR VALUES FROM (2023) to (2024);
CREATE TABLE p4 PARTITION OF SalesPartition FOR VALUES FROM (2024) to (2025);



●隣接リストモデル
CREATE TABLE OrgChart
 (emp  VARCHAR(32),
  boss VARCHAR(32),
  role VARCHAR(32) NOT NULL,
    CONSTRAINT pk_OrgChart PRIMARY KEY (emp), 
    CONSTRAINT fk_OrgChart FOREIGN KEY (boss) REFERENCES OrgChart (emp)); 

INSERT INTO OrgChart VALUES ('足立', NULL,   '社長');
INSERT INTO OrgChart VALUES ('猪狩', '足立', '部長');
INSERT INTO OrgChart VALUES ('上田', '足立', '部長');
INSERT INTO OrgChart VALUES ('江崎', '上田', '課長');
INSERT INTO OrgChart VALUES ('大神', '上田', '課長');
INSERT INTO OrgChart VALUES ('加藤', '上田', '課長');
INSERT INTO OrgChart VALUES ('木島', '江崎', 'ヒラ');


●すべてのノードのパスを列挙するクエリ（4階層限定）
SELECT O1.emp, O2.emp, O3.emp, O4.emp
  FROM OrgChart O1
    LEFT OUTER JOIN OrgChart O2
      ON O1.emp = O2.boss
         LEFT OUTER JOIN OrgChart O3
           ON O2.emp = O3.boss
              LEFT OUTER JOIN OrgChart O4
                ON O3.emp = O4.boss;



●再帰共通表式による木の深さの探索(OracleとSQL ServerではRECURSIVEを削除すること)
WITH RECURSIVE Traversal (emp, boss, depth) AS
(SELECT O1.emp, O1.boss, 1 AS depth /* 開始点となるクエリ */
   FROM OrgChart O1
  WHERE boss IS NULL
 UNION ALL
 SELECT O2.emp, O2.boss, (T.depth + 1) AS depth /* 再帰的に繰り返されるクエリ */
   FROM OrgChart O2, Traversal T
  WHERE T.emp = O2.boss)
SELECT emp, boss, depth
  FROM Traversal;

●江崎氏の上司を全員求める(OracleとSQL ServerではRECURSIVEを削除すること)
WITH RECURSIVE Traversal (emp, boss, depth) AS
(SELECT O1.emp, O1.boss, 1 AS depth /* 開始点となるクエリ */
   FROM OrgChart O1
  WHERE emp = '江崎'
 UNION ALL
 SELECT O2.emp, O2.boss, (T.depth + 1) AS depth  /* 再帰的に繰り返されるクエリ */
   FROM OrgChart O2, Traversal T
  WHERE T.boss = O2.emp)
SELECT emp, boss, depth
  FROM Traversal;

●部分木の取得（再帰共通表式）(OracleとSQL ServerではRECURSIVEを削除すること)
WITH RECURSIVE Traversal (emp, boss, depth) AS
(SELECT O1.emp, O1.boss, 1 AS depth /* 開始点となるクエリ */
   FROM OrgChart O1
  WHERE emp = '上田'
 UNION ALL
 SELECT O2.emp, O2.boss, (T.depth + 1) AS depth /* 再帰的に繰り返されるクエリ */
   FROM OrgChart O2, Traversal T
  WHERE T.emp = O2.boss)
SELECT emp, boss, depth
  FROM Traversal;

●隣接リストモデル：ブランチノードの追加
INSERT INTO OrgChart VALUES('栗栖', '足立', '専務');

UPDATE OrgChart 
   SET boss = '栗栖'
 WHERE emp = '猪狩';  

●上田氏を削除する場合は部下のboss列を付け替える
UPDATE OrgChart
   SET boss = '足立'
 WHERE emp IN ('江崎', '大神', '加藤');

DELETE FROM OrgChart
 WHERE emp = '上田';


●循環グラフを作る
UPDATE OrgChart
   SET boss = '江崎'
 WHERE emp = '足立';

  
●無限再帰クエリ(OracleとSQL ServerではRECURSIVEを削除すること)
（※読者の環境での実行は推奨しませんが、もし実行する時にはリソース消費をモニタリングしながら慎重に実行してください）
WITH RECURSIVE Traversal (emp, boss, depth) AS
(SELECT O1.emp, O1.boss, 1 AS depth /* 開始点となるクエリ */
   FROM OrgChart O1
  WHERE emp = '足立'
 UNION ALL
 SELECT O2.emp, O2.boss, (T.depth + 1) AS depth /* 再帰的に繰り返されるクエリ */
   FROM OrgChart O2, Traversal T
  WHERE T.emp = O2.boss)
SELECT emp, boss, depth
  FROM Traversal;


●Oracleでのみ使用可能な階層問い合わせ ※テーブルデータを初期化してから実行してください
SELECT emp, boss, LEVEL
  FROM OrgChart
 START WITH boss IS NULL
CONNECT BY PRIOR emp = boss;


●閉包テーブル
CREATE TABLE OrgChart2
 (emp  VARCHAR(32) PRIMARY KEY,
  role VARCHAR(32) NOT NULL,
  tree_id INTEGER  UNIQUE NOT NULL); 

INSERT INTO OrgChart2 VALUES ('足立',  '社長', 1);
INSERT INTO OrgChart2 VALUES ('猪狩',  '部長', 2);
INSERT INTO OrgChart2 VALUES ('上田',  '部長', 3);
INSERT INTO OrgChart2 VALUES ('江崎',  '課長', 4);
INSERT INTO OrgChart2 VALUES ('大神',  '課長', 5);
INSERT INTO OrgChart2 VALUES ('加藤',  '課長', 6);
INSERT INTO OrgChart2 VALUES ('木島',  'ヒラ', 7);

CREATE TABLE Closure
(parent INTEGER NOT NULL,
 child  INTEGER NOT NULL,
   CONSTRAINT pk_Closure PRIMARY KEY (parent, child),
   CONSTRAINT fk_parent FOREIGN KEY  (parent) REFERENCES  OrgChart2 (tree_id),
   CONSTRAINT fk_child  FOREIGN KEY  (child)  REFERENCES  OrgChart2 (tree_id));

INSERT INTO Closure VALUES (1, 1);
INSERT INTO Closure VALUES (1, 2);
INSERT INTO Closure VALUES (1, 3);
INSERT INTO Closure VALUES (1, 4);
INSERT INTO Closure VALUES (1, 5);
INSERT INTO Closure VALUES (1, 6);
INSERT INTO Closure VALUES (1, 7);
INSERT INTO Closure VALUES (2, 2);
INSERT INTO Closure VALUES (3, 3);
INSERT INTO Closure VALUES (3, 4);
INSERT INTO Closure VALUES (3, 5);
INSERT INTO Closure VALUES (3, 6);
INSERT INTO Closure VALUES (3, 7);
INSERT INTO Closure VALUES (4, 4);
INSERT INTO Closure VALUES (4, 7);
INSERT INTO Closure VALUES (5, 5);
INSERT INTO Closure VALUES (6, 6);
INSERT INTO Closure VALUES (7, 7);

●階層の深さを求めるクエリ（閉包テーブル）
SELECT O.emp, COUNT(*) AS depth
  FROM OrgChart2 O INNER JOIN Closure C
    ON O.tree_id = C.child
 GROUP BY O.emp 
 ORDER BY depth;


●上田氏の部下を全員求める（部分木の取得）
SELECT O2.emp
  FROM (SELECT O.emp, C.child, O.tree_id
          FROM OrgChart2 O INNER JOIN Closure C
            ON O.tree_id = C.parent
         WHERE O.emp = '上田') TMP
      INNER JOIN OrgChart2 O2
         ON O2.tree_id = TMP.child;


●リーフノードを求める
SELECT O.emp
  FROM (SELECT parent,
               COUNT(*) OVER (PARTITION BY parent) AS cnt
          FROM Closure) TMP 
            INNER JOIN OrgChart2 O
    ON O.tree_id = TMP.parent
 WHERE cnt = 1;

