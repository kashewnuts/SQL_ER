●テーブル定義（PostgreSQL）

CREATE TABLE EmpChildArray
(emp_id     CHAR(4)  PRIMARY KEY,
 emp_name   VARCHAR(16) NOT NULL,
 children   VARCHAR(16) ARRAY);

INSERT INTO EmpChildArray VALUES('0001', '熊田虎吉',	'{"熊田雄介", "熊田心美"}');
INSERT INTO EmpChildArray VALUES('0002', '青井慎吾',	'{"青井大地"}');
INSERT INTO EmpChildArray VALUES('0003', '新城菜々美','{"新城康介", "新城徹", "新城大海"}');
INSERT INTO EmpChildArray VALUES('0004', '武田春樹',	'{}');

●配列型の結果を求めるSELECT文
SELECT * FROM EmpChildArray;

●Oracleにおける配列型の定義

/* 要素数10の文字列型の配列タイプを定義 */
CREATE OR REPLACE TYPE children_typ IS VARRAY(10) of VARCHAR2(16);
/

CREATE TABLE EmpChildArrayOracle
(emp_id     CHAR(4)  PRIMARY KEY,
 emp_name   VARCHAR2(16) NOT NULL,
 children	children_typ);

INSERT INTO EmpChildArrayOracle VALUES('0001', '熊田虎吉',  children_typ('熊田雄介', '熊田心美'));
INSERT INTO EmpChildArrayOracle VALUES('0002', '青井慎吾',  children_typ('青井大地'));
INSERT INTO EmpChildArrayOracle VALUES('0003', '新城菜々美',children_typ('新城康介', '新城徹', '新城大海'));
INSERT INTO EmpChildArrayOracle VALUES('0004', '武田春樹',  NULL);

●Oracleでの配列型の列に対する索引作成
CREATE INDEX idx_children ON EmpChildArrayOracle(children);


●PostgreSQLで子どもの数を数える
SELECT emp_name, COALESCE(ARRAY_LENGTH(children, 1), 0)
  FROM EmpChildArray;

●Oracleで子どもの数を数える

set serveroutput on

CREATE OR REPLACE FUNCTION ChildCount(children children_typ)
RETURN NUMBER
IS
BEGIN
  IF children.exists(1) THEN
      RETURN children.COUNT;
  ELSE
      RETURN 0;
  END IF;
END;
/

SELECT emp_name, ChildCount(children)
  FROM EmpChildArrayOracle;


●配列の格納（ダメなやり方）
CREATE TABLE EmpChild
(emp_id   	CHAR(4)  PRIMARY KEY,
 emp_name 	VARCHAR(16) NOT NULL,
 child_1	VARCHAR(16),
 child_2    VARCHAR(16),
 child_3    VARCHAR(16));


●テーブル定義：テーブルを分割
CREATE TABLE Employee
(emp_id     CHAR(4)  PRIMARY KEY,
 emp_name   VARCHAR(16) NOT NULL);

INSERT INTO Employee VALUES('0001', '熊田虎吉');
INSERT INTO Employee VALUES('0002', '青井慎吾');
INSERT INTO Employee VALUES('0003', '新城菜々美');
INSERT INTO Employee VALUES('0004', '武田春樹');

CREATE TABLE EmployeeChildren
(emp_id   	CHAR(4) NOT NULL,
 child_seq 	INTEGER NOT NULL,
 child_name VARCHAR(16) NOT NULL,
   CONSTRAINT pk_EmployeeChildren PRIMARY KEY(emp_id, child_seq) );

INSERT INTO EmployeeChildren VALUES('0001', 1, '熊田雄介');
INSERT INTO EmployeeChildren VALUES('0001', 2, '熊田心美');
INSERT INTO EmployeeChildren VALUES('0002', 1, '青井大地');
INSERT INTO EmployeeChildren VALUES('0003', 1, '新城康介');
INSERT INTO EmployeeChildren VALUES('0003', 2, '新城徹');
INSERT INTO EmployeeChildren VALUES('0003', 3, '新城大海');

●外部結合で親と子どもを紐づける
SELECT Emp.emp_name, Child.child_name
  FROM Employee Emp LEFT OUTER JOIN EmployeeChildren Child
    ON Emp.emp_id = Child.emp_id;


●継承 親テーブルのDDL（PostgreSQL）

CREATE TABLE measurement (
    city_id         int not null,
    logdate         date not null,
    peaktemp        int,
    unitsales       int
);

●継承 子テーブルのDDL（PostgreSQL）

CREATE TABLE measurement_yy04mm02 ( ) INHERITS (measurement);
CREATE TABLE measurement_yy04mm03 ( ) INHERITS (measurement);
CREATE TABLE measurement_yy05mm11 ( ) INHERITS (measurement);
CREATE TABLE measurement_yy05mm12 ( ) INHERITS (measurement);
CREATE TABLE measurement_yy06mm01 ( ) INHERITS (measurement);


●テーブル定義：疑似配列
CREATE TABLE ArrayTbl
(id   INTEGER  PRIMARY KEY,
 c1   INTEGER,
 c2   INTEGER,
 c3   INTEGER,
 c4   INTEGER,
 c5   INTEGER,
 c6   INTEGER,
 c7   INTEGER,
 c8   INTEGER,
 c9   INTEGER,
 c10  INTEGER);

INSERT INTO ArrayTbl VALUES(1,	1,		4,		6,		NULL,	8,		5,		7,		33,		NULL,	NULL);
INSERT INTO ArrayTbl VALUES(2,	NULL,	4,		6,		2,		6,		7,		12,		NULL,	9,		NULL);
INSERT INTO ArrayTbl VALUES(3,	9,		3,		5,		7,		8,		4,		9,		NULL,	5,		1);
INSERT INTO ArrayTbl VALUES(4,	8,		11,		2,		5,		7,		9,		10,		NULL,	5,		3);
INSERT INTO ArrayTbl VALUES(5,	NULL,	6,		7,		9,		9,		9,		NULL,	NULL,	NULL,	NULL);
INSERT INTO ArrayTbl VALUES(6,	3,		1,		9,		6,		5,		7,		4,		8,		2,		4);
INSERT INTO ArrayTbl VALUES(7,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL);


●9が少なくとも一つ含まれる行を選択する（IN述語）
SELECT * 
  FROM ArrayTbl
 WHERE 9 IN (c1, c2, c3, c4, c5, c6, c7, c8, c9, c10);


●9が少なくとも一つ含まれる行を選択する（ANY演算子）
SELECT * 
  FROM ArrayTbl
 WHERE 9 = ANY (c1, c2, c3, c4, c5, c6, c7, c8, c9, c10);


●9が一つだけの行を選択する
SELECT * 
  FROM ArrayTbl
 WHERE 1 = CASE WHEN c1 = 9 THEN 1 ELSE 0 END +
           CASE WHEN c2 = 9 THEN 1 ELSE 0 END +
           CASE WHEN c3 = 9 THEN 1 ELSE 0 END +
           CASE WHEN c4 = 9 THEN 1 ELSE 0 END +
           CASE WHEN c5 = 9 THEN 1 ELSE 0 END +
           CASE WHEN c6 = 9 THEN 1 ELSE 0 END +
           CASE WHEN c7 = 9 THEN 1 ELSE 0 END +
           CASE WHEN c8 = 9 THEN 1 ELSE 0 END +
           CASE WHEN c9 = 9 THEN 1 ELSE 0 END +
           CASE WHEN c10 = 9 THEN 1 ELSE 0 END;


●JSONのサンプル
{
  "member": [
    {
      "name": "広瀬",
      "age": 45,
      "height": 172
    },
    {
      "name": "小西",
      "age": 30,
      "height": 185
    },
    {
      "name": "栗田",
      "age": 30,
      "height": 169
    },
    {
      "name": "鎌田",
      "age": 45,
      "height": 169
    },
    {
      "name": "本間",
      "age": 22,
      "height": 169
    }
  ]
}

●テーブル作成とデータ登録は共通構文でOK
CREATE TABLE Member(
	id INTEGER PRIMARY KEY,
	memo JSON NOT NULL);

INSERT INTO Member VALUES(1, '{"name": "広瀬",  "age": 45,  "height": 172}');
INSERT INTO Member VALUES(2, '{"name": "小西",  "age": 30,  "height": 185}' );
INSERT INTO Member VALUES(3, '{"name": "栗田",  "age": 30,  "height": 169}' );
INSERT INTO Member VALUES(4, '{"name": "鎌田",  "age": 45,  "height": 169}' );
INSERT INTO Member VALUES(5, '{"name": "本間",  "age": 22,  "height": 169}' );

●PostgreSQL
SELECT M1.memo->>'name' AS name1, M2.memo->>'name' AS name2
  FROM Member M1 
    INNER JOIN Member M2
    ON M1.id > M2.id
 WHERE M1.memo->>'age' = M2.memo->>'age';

●Oracle
SELECT M1.memo.name.string() AS name1, M2.memo.name.string() AS name2
 FROM Member M1
   INNER JOIN Member M2
   ON M1.id > M2.id
WHERE M1.memo.age.number() = M2.memo.age.number();

●MySQL
SELECT M1.memo->>"$.name" AS name1, M2.memo->>"$.name" AS name2
  FROM Member M1 
    INNER JOIN Member M2
    ON M1.id > M2.id
 WHERE M1.memo->>"$.age" = M2.memo->>"$.age";


●MySQLで文字列連結（間違い）
SELECT 'abc' || 'def';


●MySQLでの文字列連結
SELECT CONCAT('abc', 'def');

●文字列連結（SQL Server）
SELECT 'abc' + 'def';

●OracleでのNULLと文字列の連結
SELECT 'abc' || NULL AS concat_string 
  FROM DUAL;

●3人目のデータ
INSERT INTO Member VALUES(6, '{"name": "北野",     "age": 30,  "height": 169}' );


●要素リストテーブル
CREATE TABLE ListElement
(id  INTEGER NOT NULL,
 seq INTEGER NOT NULL,
 element VARCHAR(16),
   PRIMARY KEY (id, seq) );

[ListElement:要素リストテーブル  id:ID  element:要素]

INSERT INTO ListElement VALUES (1, 1, 'りんご');
INSERT INTO ListElement VALUES (1, 2, 'バナナ');
INSERT INTO ListElement VALUES (2, 1, 'みかん');
INSERT INTO ListElement VALUES (2, 2, 'なし');
INSERT INTO ListElement VALUES (2, 3, 'キウイ');
INSERT INTO ListElement VALUES (3, 1, 'レモン');
