第12章：演習の解答

# 序章

## 解答0-1

　解答はリスト12-1のとおりです。

●リスト12-1::Oracle、SQL Server、Db2の解答

```
UPDATE City
   SET city = CASE WHEN city = 'New York'   THEN 'Los Angels'
                   WHEN city = 'Los Angels' THEN 'New York'
                   ELSE NULL END
 WHERE city IN ('New York', 'Los Angels');
```

　本文中の考え方と同じで、`city`列の値をCASE式でくるっと入れ替えてやることができます。ただし、このクエリはPostgreSQLやMySQLでは動きません。図12-1のように主キーの一意制約違反となります。

●図12-1::PostgreSQLのエラー

```bash
ERROR:  重複したキー値は一意性制約"city_pkey"違反となります
DETAIL:  キー (city)=(Los Angels) はすでに存在します。
```

　UPDATEの実行中に一時的に`Los Angels`という値が2つ存在するようになるため、こうしたエラーが発生してしまいます。本来、一意制約は文の終了時に評価されるべきものなので、これは実装のほうが良くないのですが、それを言っても始まりません。

　このエラーを回避するには、主キーの一意制約を遅延制約に変えてやることです（リスト12-2）。

●リスト12-2::既存の主キーの一意制約を削除し、遅延制約を付加（PostgreSQL）

```
ALTER TABLE City DROP CONSTRAINT pk_City;
ALTER TABLE City ADD CONSTRAINT pk_City 
   UNIQUE (city) DEFERRABLE INITIALLY DEFERRED;
```

　これで制約のチェックはトランザクションの終了時点で行われるように変更され、CASE式を用いたUPDATEが動作するようになります。

　なお、MySQLは2024年時点で遅延制約をサポートしていないため、現在のところ、

1. 一意制約を削除
2. UPDATE文を実行
3. 一意制約を付加

という面倒な手段を取るか、退避用の値を用意するしかありません（リスト12-3）。

●リスト12-3::MySQLでの解

```
-- 制約の削除
ALTER TABLE City DROP PRIMARY KEY;  
-- 制約の付加
ALTER TABLE City ADD CONSTRAINT pk_City PRIMARY KEY (city);   
```

## 解答0-2

　自分より前に何行存在するかを求めるには、COUNT関数をウィンドウ関数として使うことで可能です。あとはその結果をCASE式のWHEN句に入れれば条件分岐の完成です（リスト12-4、図12-2）。

●リスト12-4::CASE式で3行未満かどうかで条件分岐

```
SELECT shop_id,
       sale_date,
       sales_amt,
       CASE WHEN COUNT(*) OVER (PARTITION BY shop_id ORDER BY sale_date) < 3
              THEN NULL
            ELSE ROUND(AVG(sales_amt) OVER (PARTITION BY shop_id 
                                                 ORDER BY sale_date
                            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 0) 
        END AS moving_avg
  FROM SalesIcecream;
```

●図12-2::実行結果

```bash
 shop_id | sale_date  | sales_amt | moving_avg
---------+------------+-----------+------------
 A       | 2024-06-01 |     67800 |              <- 1行しかないのでNULL
 A       | 2024-06-02 |     87000 |              <- 2行しかないのでNULL
 A       | 2024-06-05 |     11300 |      55367
 A       | 2024-06-10 |      9800 |      36033
 A       | 2024-06-15 |      9800 |      10300
 B       | 2024-06-02 |    178000 |              <- 1行しかないのでNULL
 B       | 2024-06-15 |     18800 |              <- 2行しかないのでNULL
 B       | 2024-06-17 |     19850 |      72217
 B       | 2024-06-20 |     23800 |      20817
 B       | 2024-06-21 |     18800 |      20817
 C       | 2024-06-01 |     12500 |              <- 1行しかないのでNULL
```

　なお、ウィンドウ関数が2つに増えたことによるパフォーマンス劣化を気にする人がいるかもしれませんが、この2つのウィンドウ関数はORDER BY句のキーが同じなので、実行計画上もソートは1回しか実行されません（図12-3、図12-4）。そのためパフォーマンスにも影響しませんのでご安心ください。

●図12-3::実行計画（PostgreSQL）

```bash
                      QUERY PLAN
------------------------------------------------------
 WindowAgg  (cost=1.30..1.77 rows=11 width=45)
   ->  WindowAgg  (cost=1.30..1.52 rows=11 width=21)
         ->  Sort  (cost=1.30..1.33 rows=11 width=13)
               Sort Key: shop_id, sale_date
               ->  Seq Scan on salesicecream  
                    (cost=0.00..1.11 rows=11 width=13)
```

●図12-4::実行計画（Oracle）

```bash
------------------------------------------------------------------------------------
| Id  | Operation          | Name          | Rows  | Bytes | Cost (%CPU)| Time     |
------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |               |     8 |   136 |     3  (34)| 00:00:01 |
|   1 |  WINDOW SORT       |               |     8 |   136 |     3  (34)| 00:00:01 |
|   2 |   TABLE ACCESS FULL| SALESICECREAM |     8 |   136 |     2   (0)| 00:00:01 |
------------------------------------------------------------------------------------
```

　実行計画も、見てのとおり、いたってシンプルなままです。美しい……。


# 第1章

## 解答1-1

　ウィンドウ関数でフレーム句が指定されていない場合、暗黙に`RANGE UNBOUNDED PRECEDING`が指定されているとみなされます(注:「PostgreSQL 16.0文書 SQLコマンド SELECT」https://www.postgresql.jp/document/16/html/sql-select.html)。これは、カレント行から行数の指定なく前にさかのぼるということです。そのため、フレーム句を明示せずにLAST_VALUE関数を使うと、常に自分より前の行の中で最大の枝番を探すことになるため、結局、カレント行が最大の枝番になってしまうのです。

　この問題に対処するには、フレーム句`RANGE BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING`を追加することで、カレント行よりも後ろの行から枝番の最大値を探すことが可能になります（リスト12-5、図12-5）。

●リスト12-5::解答のクエリ

```
SELECT *
  FROM (SELECT customer_id, seq, price,
               LAST_VALUE(seq) 
                 OVER (PARTITION BY customer_id 
                           ORDER BY seq
                           RANGE BETWEEN CURRENT ROW 
                                       AND UNBOUNDED FOLLOWING) AS max_seq
          FROM Receipts)
 WHERE seq = max_seq;
```

●図12-5::実行結果

```bash
 customer_id | seq | price | max_price
-------------+-----+-------+-----------
 A           |   3 |   700 |       700
 B           |  12 |  1000 |      1000
 C           |  70 |    50 |        50
 D           |   3 |  2000 |      2000
```

　なお、FIRST_VALUEとLAST_VALUEで特にコスト面での違いはないため、簡潔に書けるFIRST_VALUEを使うことで問題ありません。


## 解答1-2

　考え方はROW_NUMBER関数のときとほとんど同じで、顧客IDでパーティションを区切って、seqの昇順に並べたウィンドウに対して`NTH_VALUE`で3番目の値を指定しています（リスト12-6）。

●リスト12-6::n番目の一般化：NTH_VALUE関数

```
SELECT *
  FROM (SELECT customer_id, seq, price,
               NTH_VALUE(seq, 3) OVER (PARTITION BY customer_id 
                                           ORDER BY seq) AS seq_3rd
          FROM Receipts) TMP
 WHERE seq = seq_3rd;
```

## 解答1-3

　解答はリスト12-7のとおりです。

●リスト12-7::COALESCE関数を利用した解

```
SELECT COALESCE(E5.color, E4.color, E3.color, E2.color, E1.color) AS color,
       COALESCE(E5.length, E4.length, E3.length, E2.length,E1.length) AS length,
       COALESCE(E5.width, E4.width, E3.width, E2.width, E1.width) AS width,
       COALESCE(E5.hgt, E4.hgt, E3.hgt, E2.hgt, E1.hgt) AS hgt
  FROM Elements  E1, Elements  E2, Elements E3, Elements E4, Elements E5
 WHERE E1.lvl = 1
   AND E2.lvl = 2
   AND E3.lvl = 3
   AND E4.lvl = 4
   AND E5.lvl = 5;
```

　このクエリはJ.セルコによるものです（J.セルコ著、ミック訳『SQLパズル 第2版』「パズル53 テーブルを列ごとに折りたたむ」）。COALESCE関数は引数で与えられた列の中で最初のNULLではない値を返すため、WHERE句で各`lvl`列の値を取るように条件を縛ってやって、どのレベルの値がゼロでないかをレベル5から1へ順に調べています。

　一見すると結合が多くてパフォーマンスが悪いように見えますが、実行計画を見てみると、インデックスユニークスキャンが行われている（WHERE句で1行に絞り込めていることを意味する）ので、パフォーマンスも良好です（図12-6、図12-7）。

●図12-6::実行計画（PostgreSQL）

```bash
                                QUERY PLAN
--------------------------------------------------------------------------
 Nested Loop  (cost=0.75..40.88 rows=1 width=50)
   ->  Nested Loop  (cost=0.60..32.70 rows=1 width=200)
         ->  Nested Loop  (cost=0.45..24.52 rows=1 width=150)
               ->  Nested Loop  (cost=0.30..16.35 rows=1 width=100)
                     ->  Index Scan using elements_pkey on elements e1 
                           (cost=0.15..8.17 rows=1 width=50)
                           Index Cond: (lvl = 1)
                     ->  Index Scan using elements_pkey on elements e2  
                           (cost=0.15..8.17 rows=1 width=50)
                           Index Cond: (lvl = 2)
               ->  Index Scan using elements_pkey on elements e3  
                       (cost=0.15..8.17 rows=1 width=50)
                     Index Cond: (lvl = 3)
         ->  Index Scan using elements_pkey on elements e4  
                (cost=0.15..8.17 rows=1 width=50)
               Index Cond: (lvl = 4)
   ->  Index Scan using elements_pkey on elements e5  
          (cost=0.15..8.17 rows=1 width=50)
         Index Cond: (lvl = 5)
```

●図12-7::実行計画（Oracle）

```bash
-----------------------------------------------------------------------------------------------
| Id  | Operation                       | Name        | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                |             |     1 |   295 |     5   (0)| 00:00:01 |
|   1 |  NESTED LOOPS                   |             |     1 |   295 |     5   (0)| 00:00:01 |
|   2 |   NESTED LOOPS                  |             |     1 |   236 |     4   (0)| 00:00:01 |
|   3 |    NESTED LOOPS                 |             |     1 |   177 |     3   (0)| 00:00:01 |
|   4 |     NESTED LOOPS                |             |     1 |   118 |     2   (0)| 00:00:01 |
|   5 |      TABLE ACCESS BY INDEX ROWID| ELEMENTS    |     1 |    59 |     1   (0)| 00:00:01 |
|*  6 |       INDEX UNIQUE SCAN         | PK_ELEMENTS |     1 |       |     1   (0)| 00:00:01 |
|   7 |      TABLE ACCESS BY INDEX ROWID| ELEMENTS    |     1 |    59 |     1   (0)| 00:00:01 |
|*  8 |       INDEX UNIQUE SCAN         | PK_ELEMENTS |     1 |       |     0   (0)| 00:00:01 |
|   9 |     TABLE ACCESS BY INDEX ROWID | ELEMENTS    |     1 |    59 |     1   (0)| 00:00:01 |
|* 10 |      INDEX UNIQUE SCAN          | PK_ELEMENTS |     1 |       |     0   (0)| 00:00:01 |
|  11 |    TABLE ACCESS BY INDEX ROWID  | ELEMENTS    |     1 |    59 |     1   (0)| 00:00:01 |
|* 12 |     INDEX UNIQUE SCAN           | PK_ELEMENTS |     1 |       |     0   (0)| 00:00:01 |
|  13 |   TABLE ACCESS BY INDEX ROWID   | ELEMENTS    |     1 |    59 |     1   (0)| 00:00:01 |
|* 14 |    INDEX UNIQUE SCAN            | PK_ELEMENTS |     1 |       |     0   (0)| 00:00:01 |
-----------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   6 - access("E5"."LVL"=5)
   8 - access("E4"."LVL"=4)
  10 - access("E3"."LVL"=3)
  12 - access("E2"."LVL"=2)
  14 - access("E1"."LVL"=1)
```

　これもなかなかに見事な解と言うべきでしょう。


# 第2章

## 解答2-1

### テーブルのマッチング：IN述語の利用

　まず考えられるのが、CASE式の中でIN述語を使ってスカラサブクエリを作る方法です。

```
SELECT course_name,
       CASE WHEN course_id IN
                    (SELECT course_id FROM OpenCourses
                      WHERE month = '201806') THEN '○'
            ELSE '×' END AS "6 月",
       CASE WHEN course_id IN
                    (SELECT course_id FROM OpenCourses
                      WHERE month = '201807') THEN '○'
            ELSE '×' END AS "7 月",
       CASE WHEN course_id IN
                    (SELECT course_id FROM OpenCourses
                      WHERE month = '201808') THEN '○'
            ELSE '×' END AS "8 月"
  FROM CourseMaster;
```

　このクエリはサブクエリを使っていますが、相関サブクエリではない単純クエリなので理解しやすくパフォーマンスも悪くないのが利点です。他方、`OpenCourses`に3回アクセスせねばならないのが高コストに見えるかもしれませんが、実際にはWHERE句で主キーの一部である`month`列を使って条件指定しているので、データ量が増えても必ず一意検索になることが期待できるので、パフォーマンスは心配ありません。

　このことは、Oracleでの実行計画を見るとはっきりします（図12-8）。

●図12-8::IN述語の実行計画（Oracle）

```bash
------------------------------------------------------------------------------------
| Id  | Operation         | Name           | Rows  | Bytes | Cost (%CPU)| Time     |
------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |                |     4 |    60 |    11   (0)| 00:00:01 |
|*  1 |  INDEX UNIQUE SCAN| PK_OPENCOURSES |     1 |    21 |     1   (0)| 00:00:01 |
|*  2 |  INDEX UNIQUE SCAN| PK_OPENCOURSES |     1 |    21 |     1   (0)| 00:00:01 |
|*  3 |  INDEX UNIQUE SCAN| PK_OPENCOURSES |     1 |    21 |     1   (0)| 00:00:01 |
|   4 |  TABLE ACCESS FULL| COURSEMASTER   |     4 |    60 |     2   (0)| 00:00:01 |
------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - access("MONTH"='201806' AND "COURSE_ID"=:B1)
   2 - access("MONTH"='201807' AND "COURSE_ID"=:B1)
   3 - access("MONTH"='201808' AND "COURSE_ID"=:B1)
```

　主キーのインデックスを使って1行に絞り込むINDEX UNIQUE SCANが行われていることが確認できます。


### テーブルのマッチング：EXISTS述語の利用

　IN述語の代わりにEXISTS述語を使って条件を作ることもできます。

```
SELECT CM.course_name,
       CASE WHEN EXISTS
                  (SELECT course_id FROM OpenCourses OC
                    WHERE month = '201806'
                      AND OC.course_id = CM.course_id) THEN '○'
            ELSE '×' END AS "6 月",
       CASE WHEN EXISTS
                  (SELECT course_id FROM OpenCourses OC
                    WHERE month = '201807'
                      AND OC.course_id = CM.course_id) THEN '○'
            ELSE '×' END AS "7 月",
       CASE WHEN EXISTS
                  (SELECT course_id FROM OpenCourses OC
                    WHERE month = '201808'
                      AND OC.course_id = CM.course_id) THEN '○'
            ELSE '×' END AS "8 月"
  FROM CourseMaster CM;
```

　この場合の実行計画は、IN述語を使ったときと同じでINDEX UNIQUE SCANが使われて高速です（図12-9）。

●図12-9::EXISTS述語の実行計画

```bash
------------------------------------------------------------------------------------
| Id  | Operation         | Name           | Rows  | Bytes | Cost (%CPU)| Time     |
------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |                |     4 |    60 |     2   (0)| 00:00:01 |
|*  1 |  INDEX UNIQUE SCAN| PK_OPENCOURSES |     1 |    10 |     0   (0)| 00:00:01 |
|*  2 |  INDEX UNIQUE SCAN| PK_OPENCOURSES |     1 |    10 |     0   (0)| 00:00:01 |
|*  3 |  INDEX UNIQUE SCAN| PK_OPENCOURSES |     1 |    10 |     0   (0)| 00:00:01 |
|   4 |  TABLE ACCESS FULL| COURSEMASTER   |     4 |    60 |     2   (0)| 00:00:01 |
------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - access("MONTH"='201806' AND "OC"."COURSE_ID"=:B1)
   2 - access("MONTH"='201807' AND "OC"."COURSE_ID"=:B1)
   3 - access("MONTH"='201808' AND "OC"."COURSE_ID"=:B1)
```


## 解答2-2

　`RacingResults2`テーブルを前提とする場合は、`prize`（着順）の値によって0/1フラグをCASE式で作ってやれば簡単に条件分岐できます。あとはそれをSUM関数で集計するだけです。これが序章でも見た行持ちから列持ちへの変換（ピボット）であることに気付いたでしょうか（リスト12-8）。

●リスト12-8::CASE式によるピボット

```
SELECT horse_name,
       SUM(CASE WHEN prize = 1 THEN 1 ELSE 0 END) AS prize_1,
       SUM(CASE WHEN prize = 2 THEN 1 ELSE 0 END) AS prize_2,
       SUM(CASE WHEN prize = 3 THEN 1 ELSE 0 END) AS prize_3    
  FROM RacingResults2
GROUP BY horse_name;
```

　実行計画も簡単明瞭、実にシンプルです（図12-10、図12-11）。美しい……。

●図12-10::CASE式の実行計画（PostgreSQL）

```bash
                               QUERY PLAN
-------------------------------------------------------------------------
 HashAggregate  (cost=24.02..26.02 rows=200 width=148)
   Group Key: horse_name
   ->  Seq Scan on racingresults2  (cost=0.00..15.10 rows=510 width=128)
```

●図12-11::CASE式の実行計画（Oracle）

```bash
-------------------------------------------------------------------------------------
| Id  | Operation          | Name           | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |                |    11 |   374 |     3  (34)| 00:00:01 |
|   1 |  HASH GROUP BY     |                |    11 |   374 |     3  (34)| 00:00:01 |
|   2 |   TABLE ACCESS FULL| RACINGRESULTS2 |    18 |   612 |     2   (0)| 00:00:01 |
-------------------------------------------------------------------------------------
```


# 第3章

## 解答3-1

### Oracleにおけるサポート状況

　OracleのパラレルクエリはEnterprise Editionで利用可能です（Standard Editionでは不可）。データの取得を複数プロセスで並列的に処理する機能で、マルチコアを搭載するサーバでは、複数のCPUコアを使って処理を並列化させます（現在では基本的にサーバのCPUはマルチコアです）。

　パラレルクエリを有効化する方法はパラメータをONにしたりセッション単位で変更したりいろいろありますが、一般的なのはヒント句を使ってSQL単位でパラレル化してやる方法です。以下のようなヒント句の構文によって有効化できます。

```
SELECT /*+ PARALLEL(<並列度>) */ <列名> FROM <テーブル名> ... ;
```

参考：VLDBおよびパーティショニング・ガイド
`https://docs.oracle.com/cd/F19136_01/vldbg/degree-parallel.html`

　Standard Editionではパラレルクエリーは利用できませんが、DBMS_PARALLEL_EXECUTEパッケージを利用してある程度代替することも可能です。

参考：DBMS_PARALLEL_EXECUTE(マニュアル)
`https://docs.oracle.com/en/database/oracle/oracle-database/21/arpls/DBMS_PARALLEL_EXECUTE.html`


### SQL Serverにおけるサポート状況

　max degree of parallelism（MAXDOP）サーバ構成オプションを構成することによってパラレルクエリを使用できます。

参考：max degree of parallelism (サーバー構成オプション) の構成
`https://learn.microsoft.com/ja-jp/sql/database-engine/configure-windows/configure-the-max-degree-of-parallelism-server-configuration-option?view=sql-server-ver16`

### Db2におけるサポート状況

　`max_querydegree`というパラメータを使って最大並列度を設定します。

参考：max_querydegree - Maximum query degree of parallelism configuration parameter
`https://www.ibm.com/docs/en/db2/11.5?topic=parameters-max-querydegree-maximum-query-degree-parallelism`

### PostgreSQLにおけるサポート状況

　`max_parallel_workers_per_gather`というパラメータを使って最大並列度を設定します。

参考：PostgreSQL 15.4文書 パート II. SQL言語 第15章 パラレルクエリ
`https://www.postgresql.jp/document/15/html/parallel-query.html`

### MySQLにおけるサポート状況

　8.0.14以降で追加されたパラメータ`innodb_parallel_read_threads`で並列度を設定します。2024年時点ではまだごく一部のSQL文のみが並列化の対象となります。

参考：MySQL道普請便り 第192回 MySQLのパラレル操作について
`https://gihyo.jp/article/2023/03/mysql-rcn0192`

　パラレルクエリは、リソース（主にCPUコアとストレージの帯域）が潤沢にある環境では簡単にクエリの性能向上を図ることのできる優れたチューニング手段です。あまり難しいことを考えずにクエリのパフォーマンスを改善できます。また、DBMS側の機能であるため、クエリやアプリケーションのコードにほとんど修正が必要ないという利点があります（アプリケーション側でパラレル実行に改修するにはかなり大規模な変更が必要になります）。しかしあまり使いすぎるとリソース限界に突き当たってしまい、逆にデータベース全体の処理遅延を引き起こす諸刃の剣であることは忘れないでください。

## 解答3-2

　パーティションは日付や年などデータの値に基づいてデータを物理的に分割することで、SQL文でアクセスするデータ量を減らすというチューニング手段です。これもSQL文やアプリケーションに一切変更を行わずに性能向上を図れる非常に優れたパフォーマンス向上の手段です。ただし、DBMSによっては使えるエディションが限られていたりするので注意が必要です。

　パーティションには、以下のような種類があります。

<dl>
<dt>レンジパーティション</dt>
<dd>値の範囲に応じてデータをパーティションに振り分ける。売上月や年度といった順序を持つデータを特定の範囲に分割する。特に時系列の属性をキーにする場合に有効</dd>
<dt>リストパーティション</dt>
<dd>レンジパーティションと考え方はほぼ同じだが、商品コードや疾病コード、都道府県コードのように、離散的な値に対してデータを特定の範囲に分割する。値が連続的でない場合も設定可能なのが利点</dd>
<dt>ハッシュパーティション</dt>
<dd>キーとなる列の値に従ってデータを分散配置する。キーの一意性が高ければパーティションサイズがほぼ均等になるというメリットがある（裏を返すと、レンジパーティションやリストパーティションは、パーティションごとにデータの偏りが出る可能性がある）。顧客番号や口座IDのようにカーディナリティ（値の分散度）が高いキーに有効</dd>
</dl>

　DBMSごとのパーティションのサポート状況は以下のとおりです。

<dl>
<dt>Oracle(注:参考：「Oracle Partitioning」★改行★https://www.oracle.com/jp/database/technologies/datawarehouse-bigdata/partitioning.html
)</dt>
<dd>OracleのパーティションはEnterprise Editionで利用可能。表や索引をキーによって物理的に分割してやる機能で、WHERE句で指定される条件でキー列が使われた場合にストレージへのアクセス量を減らすことができる。値の範囲でデータを分割するレンジ・パーティションや値のリストに基づいてデータを分割するリスト・パーティション、カーディナリティの高い列に設定するハッシュパーティションが利用できる</dd>
<dt>SQL Server(注:参考：「パーティション テーブルとパーティション インデックス」★改行★https://learn.microsoft.com/ja-jp/sql/relational-databases/partitions/partitioned-tables-and-indexes)</dt>
<dd>SQL Serverでもパーティションがサポートされているが、SQL Serverの場合はデータを格納するファイルを分割するというかなり物理レベルに近いところまでユーザーに見せる機能となっている</dd>
<dt>Db2(注:参考：「パーティション表」★改行★https://www.ibm.com/docs/ja/db2/11.5?topic=schemes-partitioned-tables)</dt>
<dd>Db2のパーティションは使い勝手がOracleと似ていて、CREATE TABLE文のPARTITION BY節で指定されたキーの値に基づいてデータを物理的に分割する</dd>
<dt>PostgreSQL(注:参考：「PostgreSQL 15.4文書」「第5章 データ定義」「5.11. テーブルのパーティショニング」★改行★https://www.postgresql.jp/document/15/html/ddl-partitioning.html)</dt>
<dd>PostgreSQLのパーティションも、レンジパーティション、リストパーティション、ハッシュパーティションの3つ。PostgreSQLのパーティション化テーブルの実装方法は独特で、パーティションごとに分割された子テーブルまで作成してやる必要がある。これは少し抽象度の低い実装方法である（昔はテーブルの継承を使って実装されていたが、今ではこれを利用する機会はないと思われる）</dd>
<dt>MySQL(注:参考：「MySQL 8.0 リファレンスマニュアル」「24.1 MySQL のパーティショニングの概要」★改行★https://dev.mysql.com/doc/refman/8.0/ja/partitioning-overview.html)</dt>
<dd>MySQLもレンジ、リスト、ハッシュのパーティショニングが可能</dd>
</dl>

　パーティションを使う際の注意点は以下のとおりです。

<dl>
<dt>WHERE句でパーティションキーを検索条件に指定しないと意味がない</dt>
<dd>パーティションは、特定のキーによってデータの物理配置を決める。そのため、WHERE句でパーティションキーが指定されないと結局すべてのデータを読み込む必要があり、パーティションを設定した意味がない（それでクエリが遅くなるということもないが、単に恩恵を受けられない）</dd>
<dt>パーティションキーに大きな偏りがないか</dt>
<dd>パーティションキーに偏りがあるデータの場合、特定のパーティションにデータが集中することになり、そのパーティションにアクセスする場合だけクエリが遅延することになる。パーティションキーはできるだけ均等にデータを割り振れるものを採用する</dd>
<dt>複数のパーティションを組み合わせることもできる</dt>
<dd>「リスト＋レンジ」や「レンジ＋ハッシュ」のような複数の種類のパーティションを組み合わせることもできる。たとえば「レンジ＋ハッシュ」の場合、特定のキーでレンジごとにデータが分割されたあと、さらにハッシュキーでデータが分散される。これをコンポジット・パーティションと呼ぶ(注:「Oracle Partitioningのメリットを現場エンジニアが解説！～今さら聞けない！？その効果とは～」★改行★https://www.ashisuto.co.jp/db_blog/article/oracle-partitioning.html#oracle-partitioning-3-4)。ただしこの機能を利用できるDBMSは2024年現在でOracleとPostgreSQLとMySQLのみ。互換性が気になる場合は利用しないほうがよい</dd>
<dt>パーティション数の上限がある</dt>
<dd>どのDBMSでもパーティション数に上限が設定されている。たとえばOracleでは100万、SQL Serverでは15,000、MySQLでは8,192、Db2で32,767。PostgreSQLはドキュメントにはっきりした上限数の記述がないが、100程度にとどめることが推奨されている。通常の使い方をしている限り上限にあたる可能性は低いが、もしパーティションキーのカーディナリティが高い場合には注意が必要</dd>
</dl>

# 第4章

## 解答4-1

　この部署テーブルの定義では、部署ごとの情報を見ることができません。そこで、リスト12-9のようなチェック状態を属性として持つテーブルを作ればよいのです。

●リスト12-9::テーブル定義：部署チェック状態テーブル

```
CREATE TABLE DptCheck
(department  CHAR(16) NOT NULL,
 check_flag  BOOLEAN     NOT NULL,  /* TRUEならば完了、FALSEなら未完 */
   CONSTRAINT pk_DptCheck PRIMARY KEY (department));
```

　最初からこのような`department`単位のテーブルが用意されていれば、この問題に頭を悩ませる必要はなかったのです。`check_flag`の更新は、アプリケーションでもSQLでもできます。HAVING句やウィンドウ関数でこの問題を解くのも華やかで興味深いのですが、モデリングで解決してしまうという根本的な解法もぜひ忘れないでください。

　なお、SQL ServerはBOOLEAN型をサポートしていないため、0/1の値を取るBIT型で代用します。またOracle Databaseは23aiで初めて、BOOLEAN型をサポートしたので、今後はBOOLEAN型を使うことができます。それ以前のバージョンではNUMBER(1)にCHECK制約で0か1の値だけを取るようCHECK制約を付与するという方法が取られることが多かったです。

## 解答4-2

　次のようにリージョンテーブルを作成すれば簡単に解けます（図12-12）。

```
CREATE TABLE Region
(region_id  INTEGER,
 region     CHAR(32),
   CONSTRAINT pk_Region PRIMARY KEY(region_id));

 CREATE TABLE City
(city   CHAR(32) NOT NULL ,
 population INTEGER NOT NULL,
 region_id INTEGER,
   CONSTRAINT pk_City PRIMARY KEY (city),
   FOREIGN KEY (region_id) REFERENCES Region (region_id));
```

　たとえばデータの登録SQL文は以下のようになります。

```
INSERT INTO Region VALUES (1, 'East Coast');
INSERT INTO Region VALUES (2, 'West Coast');

INSERT INTO City VALUES('New York',     8460000,  1);
INSERT INTO City VALUES('Los Angels',   3840000,  2);
INSERT INTO City VALUES('San Francisco',815000,   2);
INSERT INTO City VALUES('New Orleans',  377000,   1);
```

　このテーブルを前提とすれば、次のような簡単なクエリで答えを求めることが可能です。`region_id`で`Region`テーブルと`City`テーブルを結合する非常にシンプルな解です。

```
SELECT R.region_id, SUM(C.population) AS sum_pop
  FROM Region R INNER JOIN City C
    ON R.region_id = C.region_id
 GROUP BY R.region_id;
```

```bash
 region_id | sum_pop
-----------+---------
         1 | 8837000
         2 | 4655000
```

　もし地域名（`region`）も結果に含めたければどうすればよいかは、本書をここまで読んだみなさんならすでにご存じと思いますので省略します。

# 第5章

## 解答5-1

　トリガの主なデメリットは以下のとおりです。

<dl>
<dt>ビジネスロジックがアプリケーション側とデータベース側に分断され、可読性が低くなる</dt>
<dd>トリガを使うとアプリケーションエンジニアの知らないところでテーブルに更新が入ることになり、あとあとアプリケーションの仕様書やコードを見ただけではビジネスロジックの全容を見渡すことが難しくなる。知らないうちにテーブルに更新が入っているのを不思議に思って調べてみたら「そこで更新が行われていたのか！」と驚愕することがしばしばある。テストのときにデータフロー全体を追うのも難しくなる</dd>
<dt>構文が実装によってバラバラのためロックイン症候群を引き起こす</dt>
<dd>トリガが標準に入ったのはSQL:1999からだが、それ以前から各DBMSは実装を進めており、構文が統一されていない。そのため互換性もないのが現状。あまりトリガを多用するとマイグレーションのコストが上がることになるので要注意</dd>
<dt>デバッグがしにくい</dt>
<dd>JavaやPythonなど統合開発環境が整備されている言語と違って、トリガの開発環境は非常に貧弱。そのため規模の大きい処理をトリガで実装せねばならない場合などは、コーディングの難易度が非常に高くなる（これはトリガだけでなくストアドプロシージャやストアドファンクション全般に当てはまる）</dd>
<dt>トリガーがエラーになった場合、元のトランザクションもロールバックされる</dt>
<dd>これはトランザクションの一貫性を保つうえではしかたない仕様ではあるが、トリガがエラーになると、発火元となった更新文のトランザクション全体がロールバックされる。しかしこの動作は、発火元のトランザクションのほうは実行に成功しているのにロールバックされているように見えて、混乱の原因となる。また、たかだかロギングに失敗したくらいで業務的に重要なメインの更新のほうまで巻き込んでロールバックされるのは迷惑なケースもある。トリガは特に監査ログや集計列の更新など付随的な機能に使われることが多いため、メインの機能までトリガに引きずられるのは困りもの</dd>
</dl>

　トリガに関しては、Oracle社もマニュアルで以下のような注意事項を述べています。データベースベンダーが特定の機能に関してこのようなコメントを行うことは異例ですが、それだけトリガの無秩序な使用による問題が発生しやすいということです。

> トリガーは、データベースのカスタマイズに役立ちますが、必要な場合のみ使用してください。トリガーを過剰に使用すると相互依存関係が複雑になる可能性があり、大規模なアプリケーションでは管理が困難になります。
> 32KBを超えないようにトリガーのサイズを制限します。トリガーが多くのコードの行を必要とする場合、トリガーから起動されるストアド・プロシージャへのビジネス・ロジックの移行を検討してください。

──「Oracle Database 2日で開発者ガイド 11g リリース1（11.1）」https://docs.oracle.com/cd/E15817_01/appdev.111/e05694/tdddg_triggers.htm

　最新版のマニュアルでは該当する記載はありませんが、この警告ともとれる記述は今でも一聴に値します。トリガーの無秩序な使用は厳に慎むべきです。


## 解答5-2

　下記に各DBMSのストアドプロシージャの解説サイトを紹介します。しかし、繰り返しになりますがストアドプロシージャは極力使わないでください。

### Oracle
開発者向けのPL/SQL

`https://www.oracle.com/jp/database/technologies/appdev/plsql.html`

### SQL server
Transact-SQL リファレンス (データベース エンジン)

`https://learn.microsoft.com/ja-jp/sql/t-sql/language-reference`

### Db2
ストアード・プロシージャーとしてのアプリケーション・プログラムの使用

`https://www.ibm.com/docs/ja/db2-for-zos/12?topic=zos-use-application-program-as-stored-procedure`

### PostgreSQL
PostgreSQLでストアドプロシージャを使用する

`https://www.fujitsu.com/jp/products/software/resources/feature-stories/postgres/article-index/stored-procedure/`

### MySQL
MySQL 8.0 リファレンスマニュアル 「第25章  ストアドオブジェクト」

`https://dev.mysql.com/doc/refman/8.0/ja/stored-objects.html`

### Redshift
Amazon Redshift でのストアドプロシージャの概要

`https://docs.aws.amazon.com/ja_jp/redshift/latest/dg/stored-procedure-create.html`

### BigQuery
SQL ストアド プロシージャを操作する

`https://cloud.google.com/bigquery/docs/procedures?hl=ja`

　どの実装もけっこう真面目にストアドプロシージャをサポートしているのですが、ロバート風に言うなら「どうせ使いどころなどないのにご苦労なことだ」というところです。

# 第6章

## 解答6-1

　解答はPostgreSQLですが、ほかのDBMSでも結合条件`M2.id > M3.id`を増やす点は同様です（リスト12-10）。

●リスト12-10::PostgreSQLでの解

```
SELECT M1.memo->'name' AS name1, 
       M2.memo->'name' AS name2, 
       M3.memo->'name' AS name3
  FROM Member M1 
    INNER JOIN Member M2
    ON M1.id > M2.id
      INNER JOIN Member M3
      ON M2.id > M3.id
 WHERE M1.memo->>'age' = M2.memo->>'age'
   AND M2.memo->>'age' = M3.memo->>'age';
```

## 解答6-2

　Redshiftでは、配列およびJSONはSUPERというデータ型を使用して格納します。

- SUPER タイプ - Amazon Redshift
`https://docs.aws.amazon.com/ja_jp/redshift/latest/dg/r_SUPER_type.html`

　JSONに対する関数は以下のようなものが利用可能です。パス要素から参照されるキーと値のペアを値として返す`JSON_EXTRACT_PATH_TEXT`などが用意されています。

- JSON関数 - Amazon Redshift
`https://docs.aws.amazon.com/ja_jp/redshift/latest/dg/json-functions.html`


　BigQueryでは、配列に対してARRAY型を使用できます。

- 配列の操作 - BigQuery
`https://cloud.google.com/bigquery/docs/arrays`

　配列に対しては長さを調べるARRAY_LENGTH関数や配列の要素を展開するUNNEST関数が用意されています。

　BigQueryはJSON型もサポートしています。

- Google SQL での JSONデータの操作
`https://cloud.google.com/bigquery/docs/json-data`


## 解答6-3

　現状、OracleとDb2が標準に準拠しているぐらいであとは実装ごとにバラバラです。

●OracleとDb2

```
SELECT id,
       LISTAGG(element, ',') WITHIN GROUP (ORDER BY seq) AS csv
  FROM ListElement
 GROUP BY id;
```

●MySQL

```
SELECT id,
       GROUP_CONCAT(element ORDER BY seq SEPARATOR ',' ) AS csv
  FROM ListElement
 GROUP BY id;
```


●PostgreSQL

```
SELECT id,
       ARRAY_TO_STRING(ARRAY_AGG(element ORDER BY seq), ',') AS csv
  FROM ListElement 
 GROUP BY id;
```

●SQL server

```
SELECT id, STRING_AGG(element, ',') WITHIN GROUP (ORDER BY seq) AS 
  FROM ListElement
 GROUP BY id;
```

　Oracle、MySQL、SQL Serverにはそれぞれ専用の関数が存在しているのでそれを使うだけですが、PostgreSQLにはないので、一度ARRAY_AGG関数で配列を作ってから、ARRAY_TO_STRING関数で配列を文字列型（区切り文字はカンマ）に変換しています。

# 第7章

## 解答7-1

　開始年度と終了年度によって市町村の有効期間を管理するため、図12-13のようなテーブルレイアウトになります。

●図12-13::開始終了付き主キー[ img/12_20_開始終了付き主キー.ai ]

　主キーは`(開始年度, 市町村コード)`で、終了年度を含めていませんが、これは開始年度が決まれば終了年度も決まるため、終了年度をキーに含めるのは冗長だからです。ただ、開始年度と終了年度のペアは検索条件で使う可能性があるので、この2列にインデックスを作っておくのは気が利いているかもしれません。

## 解答7-2

　シーケンスオブジェクトとID列を比較した場合、まず大きな違いが、前者が特定のテーブルに紐付いていないのに対して、後者が特定の一つのテーブルが持つ列として定義されることです。そのため、複数のテーブルでIDを共有したい場合には後者は不向きです。また、ID列で払い出された連番は後からUPDATE文によって更新できないケースがあるため（リスト12-11、リスト12-12、リスト12-13）(注:この動作は正確には実装によって異なり、SQL Serverでは更新不可能ですが、MySQLでは更新可能です。またOracleとPostgreSQL、Db2では、GENERATED ALWAYS AS IDENTITYオプションで作成されたID列は更新不可能ですが、GENERATED BY DEFAULT AS IDENTITYオプションを指定した場合には更新可能な列となります。このあたりは少し実装ごとに揺らぎがあり複雑な事情になっています。この統一感のなさの原因は、根本的にはID列やシーケンスオブジェクトの標準化がSQL:2003と遅かったからです。)、あとから更新が入る可能性がある場合も、ID列を使うのはリスクがあります。総じて、シーケンスオブジェクトのほうが柔軟性に優れると言ってよいでしょう。シーケンスオブジェクトで採番された数値は、いったんテーブルに格納されてしまえばただの数値として扱うことができます。またシーケンスオブジェクトは、採番の間隔、開始値、最大値、キャッシュの有無、サイクリックに循環するかどうかなど、細かいオプションを指定することもできます。

●リスト12-11::更新不可のID列の定義（Oracle／PostgreSQL／Db2）

```
CREATE TABLE ID_Table
(key_col INTEGER NOT NULL,
 id_col  INTEGER GENERATED ALWAYS AS IDENTITY);

INSERT INTO ID_Table (key_col) VALUES(1);
INSERT INTO ID_Table (key_col) VALUES(2);
INSERT INTO ID_Table (key_col) VALUES(3);

-- エラーになる
UPDATE ID_Table 
   SET id_col = 4
 WHERE id_col = 3;
```

●リスト12-12::更新可能なID列の定義（MySQL）

```
CREATE TABLE ID_Table
(key_col INTEGER AUTO_INCREMENT PRIMARY KEY);

INSERT INTO ID_Table VALUES();
INSERT INTO ID_Table VALUES();
INSERT INTO ID_Table VALUES();


-- key_col列を3から4に変更する更新文（エラーにならない）
UPDATE ID_Table 
   SET key_col = 4
 WHERE key_col = 3;
```

●リスト12-13::更新不可能なID列の定義（SQL Server）

```
CREATE TABLE ID_Table
(key_col INTEGER IDENTITY PRIMARY KEY,
 col_1   INTEGER NOT NULL);

INSERT INTO ID_Table (col_1) VALUES(1);
INSERT INTO ID_Table (col_1) VALUES(2);
INSERT INTO ID_Table (col_1) VALUES(3);

-- key_col列を3から4に変更する更新文（エラーになる）
UPDATE ID_Table 
   SET key_col = 4
 WHERE key_col = 3;
```

　なお、こうした連番機能を使うことによるロックイン症候群を心配した人もいるかもしれません。2024年現在では、主要なDBMSはシーケンスオブジェクトとID列をサポートしているのでそれほど移植性を気にする必要はないのですが（構文上の違いは若干ありますが、それほど多用する機能でもないので改修コストは低いでしょう）、MySQLがシーケンスオブジェクトをサポートしていないのが残念なところです。早期のサポートが望まれます。

　また、シーケンスオブジェクトやID列がなかった時代には、採番テーブルというものを作ってアプリケーションで連番の払い出しを行っていたのですが、排他制御が難しく重複値を生み出したりI/O競合による性能劣化の原因になったりするので、現在ではこの選択肢はまず採用する局面はありません。結論としては、サロゲートキーとして連番を払い出したいケースにおいては、まずシーケンスオブジェクトが第一選択肢となるでしょう。

## 解答7-3

　データマートは、BI/DWH系のデータベースには必ずと言ってよいほど作られているメジャーなテーブルです。ER上必要な存在ではないためこれを忌避する理論家もいますが、パフォーマンス上の利点が大きいため現実には多くの開発現場で採用されています。

　これを実現する手段のうち、一番単純なのは通常のテーブルとして持つ方法です。これのメリットは、実装が簡単なことです。特にエディションやバージョン、実装の違いを意識することなく実現できます。一方、デメリットは実データを持つためストレージ容量を消費すること、更新のための処理を実装する必要があることです。

　一方、ビューであれば、実際にはデータを持たないためストレージの消費はゼロです。ただし、データを持たないということはデータマートにアクセスするたびに元のデータテーブルへの複雑なクエリが実行されるため、レポーティングの速度が遅くなります。これではデータマートを作る意義が薄れてしまいます。

　マテリアライズド・ビューは、両者の中間のような存在で、ビューとして定義するのですが実際のデータを保持するというテーブルの性格も持っています。リフレッシュコマンドで任意のタイミングでデータマートのデータを最新化することもできます。テーブルとほぼ同様の性格を持つため、主キーやインデックスを設定できるなど、パフォーマンスに配慮した機能を持っています。一方、マテリアライズド・ビューのデメリットは、実装ごとにサポート状況が異なることです。Oracle、SQL Server、Db2、PostgreSQL、Redshift、BigQueryはサポートしていますが、MySQLは2024年時点でサポートしていません。また、更新された一部分のみをリフレッシュする差分リフレッシュ（高速リフレッシュ）の機能は、Oracleはサポートしていますが、ほかのDBMSは2024年時点でまだ実装していません。

## 解答7-4

　リーフノードは部下を持たないノードということですから、それは「名前が`boss`列に1回も登場しない」という条件として記述できます。するとリスト12-14のようなNOT EXISTS述語を使って書くことができます（図12-14）。

●リスト12-14::NOT EXISTS述語を使った解答

```
SELECT emp
  FROM OrgChart O1
 WHERE NOT EXISTS 
       (SELECT * 
          FROM OrgChart O2
         WHERE O1.emp = O2.boss);
```

●図12-14::実行結果

```bash
 emp
------
 猪狩
 加藤
 木島
 大神
```

　解答としてはこれでよいのですが、中にはNOT IN述語を使ってリスト12-15のように書いた人もいるかもしれません。

●リスト12-15::NOT IN述語による解答（間違い）

```
SELECT emp
  FROM OrgChart
 WHERE emp NOT IN (SELECT boss FROM OrgChart);
```

　このクエリは正しいように見えるのに、結果を1行も返しません。空っぽです。なぜこんなことが起きるのでしょうか？ それは社長である足立氏の`boss`列がNULLだからです。NOT IN述語は引数となる集合の中にNULLが一つでも入っていた場合、問答無用で結果が空になるのです。これが有名なSQL七不思議の一つ「NOT IN述語の結果が空になるんですけど」です。なぜこんな不整合が発生するのかという理由はかなり入り組んでいるので説明は省略しますが、一言でいうとSQLが3値論理を採用してしたことによる代償です。もし興味ある方がいたら拙著『達人に学ぶ SQL徹底指南書 第2版』（翔泳社、2018年）第4章「3値論理とNULL」を読んでみてください。そこまで気にならないという方は、とりあえず、NULLに関わるとロクなことにならないという教訓だけ覚えておいてください。NULLはSQLの火薬庫みたいなものなので、不用意に触るとケガをします。

## 解答7-5

　解答はリスト12-16のとおりです（図12-15）。

●リスト12-16::Oracle以外の答え

```
WITH RECURSIVE NumberGenerate (num) AS
(SELECT 1 AS num /* 開始点となるクエリ */
 UNION ALL
 SELECT num + 1 AS num /* 再帰的に繰り返されるクエリ */
   FROM NumberGenerate
  WHERE num <= 99)
SELECT num
  FROM NumberGenerate;
```

※OracleとSQL Serverでは1行目のキーワード`RECURSIVE`を削除してください。

●図12-15::クエリの結果

```bash
num
----
  1
  2
  3
  ・
  ・
  ・
  100
```

　1を開始点として、再帰的に`num + 1`の式を99まで繰り返します。`WHERE num <= 99`の条件がないと無限ループに陥るので実行時は注意してください。このクエリは、スキーマにまったくテーブルを用意することなく連番を生成できるので便利です。

　フィボナッチ数列はリスト12-17のような再帰共通表式で生成できます（図12-16）。

●リスト12-17::99までのフィボナッチ数列の生成（PostgreSQL、MySQL）

WITH RECURSIVE Fib (a, b) AS
(SELECT 0 AS a, 1 AS b /* 開始点となるクエリ */
 UNION ALL
 SELECT b, a + b /* 再帰的に繰り返されるクエリ */
   FROM Fib
  WHERE b <= 99)
 SELECT a
   FROM Fib;

●図12-16::フィボナッチ数列

```bash
 a
----
  0
  1
  1
  2
  3
  5
  8
 13
 21
 34
 55
 89
```

　例によって、PostgreSQLとMySQL以外で実行する場合は`RECURSIVE`を削除してください。Oracleではなぜかこのクエリはエラーになって動きません（ORA-32044というエラーが発生します）。

　なお、自然数と同じ考え方で連続する日付を生成することもできます（リスト12-18）。

●リスト12-18::再帰共通表式で連続する日付を求める（PostgreSQL）

```
WITH RECURSIVE DateGenerate (cur_date, depth) AS
(SELECT CURRENT_DATE AS cur_date, 1 AS depth /* 開始点となるクエリ */
 UNION ALL
 SELECT cur_date + 1 AS cur_date, depth + 1 AS depth  /* 再帰的に繰り返されるクエリ */
   FROM DateGenerate
  WHERE depth <= 10)
SELECT cur_date
  FROM DateGenerate;
```

　現在の日付が2024年1月27日だとすると、図12-17のような結果が得られます。きちんと月も切り替わっています。

●図12-17::実行結果

```bash
  cur_date
------------
 2024-01-27
 2024-01-28
 2024-01-29
 2024-01-30
 2024-01-31
 2024-02-01
 2024-02-02
 2024-02-03
 2024-02-04
 2024-02-05
 2024-02-06
```

　現在日付を取得する関数や日付の計算を行う関数は実装ごとに微妙に違うので、それぞれの実装ごとにクエリが少し異なります（リスト12-19、リスト12-20）。

●リスト12-19::再帰共通表式で連続する日付を求める（Oracle）

```
WITH DateGenerate (cur_date, depth) AS
(SELECT CURRENT_DATE AS cur_date, 1 AS depth /* 開始点となるクエリ */
   FROM DUAL
 UNION ALL
 SELECT cur_date + 1 AS cur_date, depth + 1 AS depth  /* 再帰的に繰り返されるクエリ */
   FROM DateGenerate
  WHERE depth <= 10)
SELECT cur_date
  FROM DateGenerate;
```

※Oracleではテーブルを必要としない場合も疑似表DUALを使う必要がありましたが、23ai以降は不要となりました。

●リスト12-20::再帰共通表式で連続する日付を求める（MySQL）

```
WITH RECURSIVE DateGenerate (cur_date, depth) AS
(SELECT CURRENT_DATE AS cur_date, 1 AS depth /* 開始点となるクエリ */
 UNION ALL
 SELECT DATE_ADD(cur_date, INTERVAL 1 DAY) AS cur_date, depth + 1 AS depth  /* 再帰的に繰り返されるクエリ */
   FROM DateGenerate
  WHERE depth <= 10)
SELECT cur_date
  FROM DateGenerate;
```

# 第8章

## 解答8-1

　解答はリスト12-21のとおりです（図12-18）。

●リスト12-21::HAVING句による別解

```
SELECT family_id
  FROM Addresses
 GROUP BY family_id
HAVING COUNT(DISTINCT address) > 1;
```

●図12-18::実行結果

```bash
 family_id
-----------
       100
       500
```

　`DISTINCT`で住所の重複をなくしてもなお1よりも大きいということは、家族内で住所が異なるということです。こちらのほうがオーソドックスな考え方だと感じる方もいるかもしれません。著者の周囲では半々という印象です。実行計画は図12-19、図12-20のとおりで、本文の実行計画とほぼ同じになります。

●図12-19::HAVING句の別解の実行計画（PostgreSQL）

```bash
                              QUERY PLAN
----------------------------------------------------------------------
 GroupAggregate  (cost=1.23..1.36 rows=2 width=4)
   Group Key: family_id
   Filter: (count(DISTINCT address) > 1)
   ->  Sort  (cost=1.23..1.26 rows=9 width=36)
         Sort Key: family_id, address
         ->  Seq Scan on addresses  (cost=0.00..1.09 rows=9 width=36)
```

●図12-20::HAVING句の別解の実行計画（Oracle）

```bash
----------------------------------------------------------------------------------
| Id  | Operation            | Name      | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------
|   0 | SELECT STATEMENT     |           |     9 |   423 |     3  (34)| 00:00:01 |
|*  1 |  HASH GROUP BY       |           |     9 |   423 |     3  (34)| 00:00:01 |
|   2 |   VIEW               | VM_NWVW_1 |     9 |   423 |     3  (34)| 00:00:01 |
|   3 |    HASH GROUP BY     |           |     9 |   423 |     3  (34)| 00:00:01 |
|   4 |     TABLE ACCESS FULL| ADDRESSES |     9 |   423 |     2   (0)| 00:00:01 |
----------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter(COUNT("$vm_col_1")>1)
```

## 解答8-2

　解答はリスト12-22のとおりです（図12-21）。

●リスト12-22::NOT EXISTS述語を使った解

```
SELECT DISTINCT department
  FROM Departments D1
 WHERE NOT EXISTS
        (SELECT *
           FROM Departments D2
          WHERE D1.department = D2.department
            AND D2.check_flag = '未完');
```

●図12-21::実行結果

```bash
      department       |       division
-----------------------+-----------------------
 研究開発部            | 基礎理論課
 研究開発部            | 応用技術課
 総務部                | 一課
```

　EXISTS述語はSQLの中で唯一、行集合を引数に取る二階の述語です。ウィンドウ関数やHAVING句による解法が一般的になるまでは、SQLで「すべての」を表すためによく用いられていたのですが、そのやり方が少し特殊です。このケースだと「すべての課が完了している」を「終わっていない課が一つもない」という二重否定に読み替えているのです。この読み替えがわかりにくいため、ウィンドウ関数が登場して以来、あまり使われなくなりました。しかし、もしかすると昔のコードを改修するときに目にする機会があるかもしれないので、ここで取り上げたしだいです。

　なお、NOT EXISTSが相関サブクエリを引数にとっていることでパフォーマンスを不安に思った人もいるかもしれませんが、データ量が増えても`D1.department = D2.department`で主キーのインデックスを利用できるので、結合をしている割にはそれほどパフォーマンスも悪くありません。また、ウィンドウ関数と同じく結果を集約せずヒラで取得できるのも利点です。

　EXISTS述語についてもっと深く学んでみたいと思った方は、拙著『達人に学ぶ SQL徹底指南書 第2版』（翔泳社、2018年）第5章「EXISTS述語の使い方」を参照してください。

# 第9章

## 解答9-1

　求める条件は「連続した3つの座席がすべて空席であること」です。SQLにおいて「すべての」を表現するには、少し工夫がいるのでした。覚えているでしょうか？

　まず古典的なやり方は、NOT EXISTS述語を使って「連続した3つの座席のうち一つも空席ではない座席は存在しない」という二重否定に読み替えてやることです（リスト12-23）。

●リスト12-23::人数分の空席を探す：リレーショナル原理主義的な解法

```
SELECT S1.seat AS start_seat, '～' , S2.seat AS end_seat
  FROM Seats S1, Seats S2
 WHERE S2.seat = S1.seat + (:head_cnt -1) --始点と終点を決める
   AND NOT EXISTS
        (SELECT *
           FROM Seats S3
          WHERE S3.seat BETWEEN S1.seat AND S2.seat
            AND S3.status <> 'E' );
```

　`:head_cnt`は座りたい人数を表すホスト言語から渡されるパラメータです。今回は3を代入することになります。

　さて、これで求める結果は得られるのですが、問題はパフォーマンスです。`Seats`テーブルを3つも使っていることからお察しのとおり、このクエリのパフォーマンスはお世辞にも良いとは言えません。実行計画を見てみましょう（図12-22、図12-23）。

●図12-22::リレーショナル原理主義の実行計画（PostgreSQL）

```bash
                                QUERY PLAN
---------------------------------------------------------------------------
 Nested Loop Anti Join  (cost=1.34..4.94 rows=13 width=40)
   Join Filter: ((s3.seat >= s1.seat) AND (s3.seat <= s2.seat))
   ->  Hash Join  (cost=1.34..2.54 rows=15 width=8)
         Hash Cond: ((s1.seat + 2) = s2.seat)
         ->  Seq Scan on seats s1  (cost=0.00..1.15 rows=15 width=4)
         ->  Hash  (cost=1.15..1.15 rows=15 width=4)
               ->  Seq Scan on seats s2  (cost=0.00..1.15 rows=15 width=4)
   ->  Materialize  (cost=0.00..1.21 rows=5 width=4)
         ->  Seq Scan on seats s3  (cost=0.00..1.19 rows=5 width=4)
               Filter: (status <> 'E'::bpchar)
```

●図12-23::リレーショナル原理主義の実行計画（Oracle）

```bash
---------------------------------------------------------------------------------
| Id  | Operation            | Name     | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------
|   0 | SELECT STATEMENT     |          |     1 |    11 |     6  (34)| 00:00:01 |
|   1 |  MERGE JOIN ANTI     |          |     1 |    11 |     6  (34)| 00:00:01 |
|   2 |   SORT JOIN          |          |    15 |    90 |     3  (34)| 00:00:01 |
|   3 |    NESTED LOOPS      |          |    15 |    90 |     2   (0)| 00:00:01 |
|   4 |     TABLE ACCESS FULL| SEATS    |    15 |    45 |     2   (0)| 00:00:01 |
|*  5 |     INDEX UNIQUE SCAN| PK_SALES |     1 |     3 |     0   (0)| 00:00:01 |
|*  6 |   FILTER             |          |       |       |            |          |
|*  7 |    SORT JOIN         |          |     1 |     5 |     3  (34)| 00:00:01 |
|*  8 |     TABLE ACCESS FULL| SEATS    |     1 |     5 |     2   (0)| 00:00:01 |
---------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   5 - access("S2"."SEAT"="S1"."SEAT"+2)
   6 - filter("S3"."SEAT"<="S2"."SEAT")
   7 - access("S3"."SEAT">="S1"."SEAT")
       filter("S3"."SEAT">="S1"."SEAT")
   8 - filter("S3"."STATUS"<>'E')
```

　`Seats`テーブルへの3回のアクセスに加えて結合も発生しています（Oracleはうまくインデックスを使っているのでテーブルアクセスは2回です）。どちらのDBMSにおいても、`Seats`テーブルのデータ量が増えたときには重量級のクエリになるでしょう。

　一方、モダンSQLで解くとリスト12-24のようなクエリになります。

●リスト12-24::人数分の空席を探す：モダンSQLの解法

```
SELECT seat, '～', seat + (:head_cnt -1)
  FROM (SELECT seat,
               LEAD(seat, (:head_cnt -1)) OVER(ORDER BY seat) AS end_seat
          FROM Seats
         WHERE status = 'E') TMP
 WHERE end_seat - seat = (:head_cnt -1);
```

　状態が空席のシートだけに着目すると、もしシート群が長さ3のシーケンスを構成するとすれば、そのシーケンスの始点と終点の間には「終点 - 始点 = 2」という関係が成り立つはずです。これが1以下でも4以上でもダメです。そうすると、LEAD関数で2行前に進めた座席番号と比較すればよいのです。それがWHERE句の`end_seat - seat = (:head_cnt -1)`の条件です。

　それでは実行計画を見てみましょう（図12-24、図12-25）。

●図12-24::モダンSQLの実行計画（PostgreSQL）

```bash
                               QUERY PLAN
------------------------------------------------------------------------
 Subquery Scan on tmp  (cost=1.35..1.68 rows=1 width=40)
   Filter: ((tmp.end_seat - tmp.seat) = 2)
   ->  WindowAgg  (cost=1.35..1.53 rows=10 width=8)
         ->  Sort  (cost=1.35..1.38 rows=10 width=4)
               Sort Key: seats.seat
               ->  Seq Scan on seats  (cost=0.00..1.19 rows=10 width=4)
                     Filter: (status = 'E'::bpchar)
```

●図12-25::モダンSQLの実行計画（Oracle）

```bash
-----------------------------------------------------------------------------
| Id  | Operation           | Name  | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------
|   0 | SELECT STATEMENT    |       |     1 |    26 |     3  (34)| 00:00:01 |
|*  1 |  VIEW               |       |     1 |    26 |     3  (34)| 00:00:01 |
|   2 |   WINDOW SORT       |       |     1 |     5 |     3  (34)| 00:00:01 |
|*  3 |    TABLE ACCESS FULL| SEATS |     1 |     5 |     2   (0)| 00:00:01 |
-----------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter("END_SEAT"-"SEAT"=2)
   3 - filter("STATUS"='E')
```

　どちらの実行計画でも、テーブルスキャンが1回、ソートが1回と非常にシンプルで高速なものになったことがわかります。

## 解答9-2

　伝統的な`NOT EXISTS`を使った解法では、ラインIDが同じという条件を裏返してやればOKです（リスト12-25）。

●リスト12-25::人数分の空席を探す：行の折り返しも考慮する──リレーショナル原理主義の解法

```
SELECT S1.seat AS start_seat, '～' , S2.seat AS end_seat
  FROM Seats2 S1, Seats2 S2
 WHERE S2.seat = S1.seat + (:head_cnt -1) --始点と終点を決める
   AND NOT EXISTS
        (SELECT *
           FROM Seats2 S3
          WHERE S3.seat BETWEEN S1.seat AND S2.seat
            AND ( S3.status <> 'E' OR S3.line_id <> S1.line_id));
```


　ウィンドウ関数を用いる解では、行の折り返しをPARTITION BY句で表現できるので先のクエリからの修正も非常に軽微です（リスト12-26）。

●リスト12-26::人数分の空席を探す：行の折り返しも考慮する──モダンSQLの解法

```
SELECT seat, '～', seat + (:head_cnt -1)
  FROM (SELECT seat,
               LEAD(seat, (:head_cnt -1)) 
                 OVER(PARTITION BY line_id
                          ORDER BY seat) AS end_seat
          FROM Seats2
         WHERE status = 'E') TMP
 WHERE end_seat - seat = (:head_cnt -1);
```

　実行計画はどちらも「解答9-1」とほとんど変わらないため省略します。一つ言えることは、この場合の可読性とパフォーマンスもウィンドウ関数を使うモダンSQLのほうが圧倒的に有利だということです。

## 解答9-3

　解答はリスト12-27のとおりです。

●リスト12-27::LAG関数で1行前の値と比較する

```
WITH VIEW_LAG (keycol, seq, pre_val) 
AS (SELECT keycol, seq, 
           LAG(val, 1) OVER(PARTITION BY keycol 
                                ORDER BY seq) 
      FROM OmitTbl)
UPDATE OmitTbl
   SET val = CASE WHEN (SELECT pre_val 
                          FROM VIEW_LAG
                         WHERE VIEW_LAG.keycol = OmitTbl.keycol
                           AND VIEW_LAG.seq = OmitTbl.seq) = val 
                  THEN NULL
                  ELSE val END;
```

　1行前の`val`列の値を持ってくるので、LAG関数を使っているのがポイントです。この解は共通表式を使っているのでOracleでは動きませんが、ビューにするだけなので、各自やってみてください。サブクエリを丸ごとCASE式の条件の中に入れて相関サブクエリっぽく使うテクニックも、UPDATE文を使う際に非常に重要なテクニックなので覚えておいてください。


# 第10章

## 解答10-1

　条件分岐した更新を一気に行う手段は、序章で出てきました。そう、CASE式を使うのです。覚えていたでしょうか（リスト12-28、図12-26）。

●リスト12-28::CASE式で一気に更新する

```
UPDATE Salary
   SET salary = CASE WHEN salary <= 200000
                       THEN salary * 1.5
                     WHEN salary >= 300000
                       THEN salary * 0.8
                     ELSE salary END;
```

●図12-26::更新後の結果

```bash
 emp_name | salary
----------+--------
 トム     | 300000
 ジョード | 225000
 ウルフ   | 360000
 クロウ   | 250000
```

　なお、最後の`ELSE salary`は、どの条件にも合致しなかった社員の給料はそのまま据え置きにするための措置です。このサンプルデータではクロウがこのタイプの社員です。この句がないとクロウの給料をNULLで更新しにいってしまいエラーになります。

## 解答10-2

　1日前も欠勤していたかどうかを相関サブクエリでチェックすればよいので、基本はリスト12-29のようなUPDATE文が答えとなります。相関サブクエリの中で更新対象のテーブルに相関名を付けていないのは、SQL Serverの独自仕様に対応するためです（第1章を参照）。

●リスト12-29::UPDATE（Oracle、PostgreSQL）

```
UPDATE Absenteeism
   SET severity_points = 0,
       reason = '長期病欠'
 WHERE EXISTS
   (SELECT *
      FROM Absenteeism A2
     WHERE Absenteeism.emp_id = A2.emp_id
       AND Absenteeism.absent_date =
           (A2.absent_date + INTERVAL '1' DAY));
```

　SQL ServerとSnowflakeはINTERVAL型をサポートしていないので、DATEADD関数で代用する必要があります（リスト12-30）。

●リスト12-30::UPDATE文（SQL ServerとSnowflake）

```
UPDATE Absenteeism
   SET severity_points = 0,
       reason = '長期病欠'
 WHERE EXISTS
   (SELECT *
      FROM Absenteeism A2
     WHERE Absenteeism.emp_id = A2.emp_id
       AND DATEADD(DAY, -1, Absenteeism.absent_date) = A2.absent_date);
```

　MySQLはUPDATE文での相関サブクエリを認めていないという謎仕様があるので、共通表式を使う必要があります（リスト12-31）。

●リスト12-31::UPDATE文（MySQL）

```
WITH A2 AS (SELECT * FROM Absenteeism)
UPDATE Absenteeism
   SET severity_points = 0,
       reason = '長期病欠'
 WHERE EXISTS
   (SELECT *
      FROM A2
     WHERE Absenteeism.emp_id = A2.emp_id
       AND Absenteeism.absent_date =
           (A2.absent_date + INTERVAL '1' DAY));
```
