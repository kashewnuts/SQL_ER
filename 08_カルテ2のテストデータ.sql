-- テーブル定義
CREATE TABLE Departments
(department  CHAR(16) NOT NULL,
 division    CHAR(16) NOT NULL,
 check_flag       CHAR(8)  NOT NULL,
   CONSTRAINT pk_Departments PRIMARY KEY (department, division));


-- オリジナル(研究開発部, 総務部)
DELETE FROM Departments;
INSERT INTO Departments VALUES ('営業部', '一課', '完了');
INSERT INTO Departments VALUES ('営業部', '二課', '完了');
INSERT INTO Departments VALUES ('営業部', '三課', '未完');
INSERT INTO Departments VALUES ('研究開発部', '基礎理論課', '完了');
INSERT INTO Departments VALUES ('研究開発部', '応用技術課', '完了');
INSERT INTO Departments VALUES ('総務部', '一課', '完了');
INSERT INTO Departments VALUES ('人事部', '採用課', '未完');


-- すべて完了
DELETE FROM Departments;
INSERT INTO Departments VALUES ('営業部', '一課', '完了');
INSERT INTO Departments VALUES ('営業部', '二課', '完了');
INSERT INTO Departments VALUES ('営業部', '三課', '完了');
INSERT INTO Departments VALUES ('研究開発部', '基礎理論課', '完了');
INSERT INTO Departments VALUES ('研究開発部', '応用技術課', '完了');
INSERT INTO Departments VALUES ('総務部', '一課', '完了');
INSERT INTO Departments VALUES ('人事部', '採用課', '完了');
INSERT INTO Departments VALUES ('人事部', '人事課', '完了');

-- すべて完了
DELETE FROM Departments;
INSERT INTO Departments VALUES ('営業部', '一課', '完了');
INSERT INTO Departments VALUES ('研究開発部', '基礎理論課', '完了');
INSERT INTO Departments VALUES ('総務部', '一課', '完了');
INSERT INTO Departments VALUES ('人事部', '採用課', '完了');


-- (営業部, 人事部)
DELETE FROM Departments;
INSERT INTO Departments VALUES ('営業部', '一課', '完了');
INSERT INTO Departments VALUES ('営業部', '二課', '完了');
INSERT INTO Departments VALUES ('営業部', '三課', '完了');
INSERT INTO Departments VALUES ('研究開発部', '基礎理論課', '未完');
INSERT INTO Departments VALUES ('研究開発部', '応用技術課', '完了');
INSERT INTO Departments VALUES ('総務部', '一課', '未完');
INSERT INTO Departments VALUES ('人事部', '採用課', '完了');
INSERT INTO Departments VALUES ('人事部', '人事課', '完了');


-- なし
DELETE FROM Departments;
INSERT INTO Departments VALUES ('営業部', '一課', '未完');
INSERT INTO Departments VALUES ('営業部', '二課', '完了');
INSERT INTO Departments VALUES ('営業部', '三課', '完了');
INSERT INTO Departments VALUES ('研究開発部', '基礎理論課', '未完');
INSERT INTO Departments VALUES ('研究開発部', '応用技術課', '完了');
INSERT INTO Departments VALUES ('総務部', '一課', '未完');
INSERT INTO Departments VALUES ('人事部', '採用課', '完了');
INSERT INTO Departments VALUES ('人事部', '人事課', '未完');


-- 総務部
DELETE FROM Departments;
INSERT INTO Departments VALUES ('営業部', '一課', '未完');
INSERT INTO Departments VALUES ('営業部', '二課', '完了');
INSERT INTO Departments VALUES ('営業部', '三課', '完了');
INSERT INTO Departments VALUES ('研究開発部', '基礎理論課', '未完');
INSERT INTO Departments VALUES ('研究開発部', '応用技術課', '完了');
INSERT INTO Departments VALUES ('総務部', '一課', '完了');
INSERT INTO Departments VALUES ('人事部', '採用課', '完了');
INSERT INTO Departments VALUES ('人事部', '人事課', '未完');

-- 総務部
DELETE FROM Departments;
INSERT INTO Departments VALUES ('営業部', '一課', '未完');
INSERT INTO Departments VALUES ('営業部', '二課', '未完');
INSERT INTO Departments VALUES ('営業部', '三課', '完了');
INSERT INTO Departments VALUES ('研究開発部', '基礎理論課', '完了');
INSERT INTO Departments VALUES ('研究開発部', '応用技術課', '未完');
INSERT INTO Departments VALUES ('総務部', '一課', '完了');
INSERT INTO Departments VALUES ('人事部', '採用課', '未完');
INSERT INTO Departments VALUES ('人事部', '人事課', '完了');



-- すべて
DELETE FROM Departments;
INSERT INTO Departments VALUES ('営業部', '一課', '完了');

-- なし
DELETE FROM Departments;
INSERT INTO Departments VALUES ('営業部', '一課', '未完');

-- なし
DELETE FROM Departments;
