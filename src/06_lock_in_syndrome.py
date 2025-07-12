# Django 4.2 ORM implementation of 06_ロックイン病.sql
# ベンダー依存のアンチパターンをDjango ORMで実装

from django.db import models
from django.contrib.postgres.fields import ArrayField, JSONField
from django.db.models import Q, Value, CharField, Count

# ===== モデル定義 =====


# PostgreSQL配列型を使った従業員子供テーブル（非推奨）
class EmpChildArray(models.Model):
    """
    PostgreSQL配列型の使用例（アンチパターン）
    Django ORMでは限定的にサポート

    SQLite3制約 (3.43.2+前提):
    - ArrayField はSQLite3では依然としてサポートされていません
    - JSON形式での配列模擬が代替手段となります
    - 配列操作（__contains, array_length等）は使用できません
    """

    emp_id = models.CharField(max_length=4, primary_key=True)
    emp_name = models.CharField(max_length=16)
    # PostgreSQL専用のArrayField（他DBMSでは動作しない）
    children = ArrayField(
        models.CharField(max_length=16), size=10, default=list, blank=True
    )

    class Meta:
        db_table = "empchildarray"


# 正規化された関係構造（推奨）
class Employee(models.Model):
    emp_id = models.CharField(max_length=4, primary_key=True)
    emp_name = models.CharField(max_length=16)

    class Meta:
        db_table = "employee"


class EmployeeChild(models.Model):
    employee = models.ForeignKey(Employee, on_delete=models.CASCADE)
    child_seq = models.IntegerField()
    child_name = models.CharField(max_length=16)

    class Meta:
        db_table = "employeechild"
        unique_together = ["employee", "child_seq"]


# 疑似配列テーブル（アンチパターン）
class ArrayTbl(models.Model):
    """
    固定列による疑似配列（アンチパターン）
    """

    c1 = models.CharField(max_length=1, blank=True, null=True)
    c2 = models.CharField(max_length=1, blank=True, null=True)
    c3 = models.CharField(max_length=1, blank=True, null=True)
    c4 = models.CharField(max_length=1, blank=True, null=True)
    c5 = models.CharField(max_length=1, blank=True, null=True)
    c6 = models.CharField(max_length=1, blank=True, null=True)
    c7 = models.CharField(max_length=1, blank=True, null=True)
    c8 = models.CharField(max_length=1, blank=True, null=True)
    c9 = models.CharField(max_length=1, blank=True, null=True)
    c10 = models.CharField(max_length=1, blank=True, null=True)

    class Meta:
        db_table = "arraytbl"


# JSON使用例
class Member(models.Model):
    """
    JSONフィールドの使用例

    SQLite3制約 (3.43.2+前提):
    - JSONField はSQLite3 3.43.2以降で基本的な操作をサポート
    - 高度なJSON操作（->>、JSON_EXTRACT等）も改善されている
    - JSON検索のパフォーマンスはPostgreSQL/MySQLより劣る場合があります
    """

    id = models.AutoField(primary_key=True)
    # PostgreSQL JSONField、他DBMSでは制限あり
    memo = JSONField(default=dict, blank=True)

    class Meta:
        db_table = "member"


# 要素リスト（推奨）
class ListElement(models.Model):
    """
    配列の代替として要素リストを使用（推奨）
    """

    list_id = models.IntegerField()
    seq = models.IntegerField()
    element = models.CharField(max_length=16)

    class Meta:
        db_table = "listelement"
        unique_together = ["list_id", "seq"]


# ===== クエリ実装 =====


# ●PostgreSQL配列操作（DBMS依存）
def postgresql_array_operations():
    """
    PostgreSQL配列操作
    Django ORMでの配列操作は限定的
    """
    # Django ORMでは配列の直接操作が制限される
    # 以下は PostgreSQL 専用の操作例

    # 配列長取得（Django ORMでは直接サポートなし）
    # 代替案：raw SQLを使用
    from django.db import connection

    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT emp_id, emp_name, 
                   array_length(children, 1) as child_count
            FROM empchildarray
            WHERE array_length(children, 1) >= 2
        """)
        results = cursor.fetchall()

    return results


# ●配列検索（ANY演算子）
def array_search_operations():
    """
    PostgreSQL配列内検索
    Django ORMでは__contains演算子を使用
    """
    # PostgreSQL専用：配列内検索
    if hasattr(EmpChildArray, "children"):
        # ArrayFieldの場合のみ実行可能
        return EmpChildArray.objects.filter(children__contains=["タロウ"]).values(
            "emp_id", "emp_name", "children"
        )

    # 代替案：正規化されたテーブルでの検索
    return Employee.objects.filter(employeechild__child_name="タロウ").values(
        "emp_id", "emp_name"
    )


# ●正規化された関係での子供検索（推奨）
def normalized_child_search():
    """
    正規化されたテーブルでの子供検索（推奨）
    """
    return (
        Employee.objects.filter(employeechild__child_name__in=["タロウ", "ジロウ"])
        .distinct()
        .annotate(child_count=Count("employeechild"))
        .values("emp_id", "emp_name", "child_count")
    )


# ●JSON操作（DBMS固有）
def json_operations():
    """
    JSON操作の例
    DBMS固有の構文をDjango ORMで抽象化

    SQLite3制約 (3.43.2+前提):
    - extra() 内のJSON演算子 (->>)  はSQLite3 3.43.2以降でサポート
    - JSON検索操作のパフォーマンスはPostgreSQL/MySQLより劣る場合があります
    - JSONインデックス機能は限定的です
    """
    # PostgreSQL: ->> 演算子
    # MySQL: ->> 演算子
    # Oracle: .string() メソッド

    # Django ORMでは統一的なJSON操作が可能
    return (
        Member.objects.filter(memo__name__isnull=False)
        .extra(
            select={
                "json_name": "memo->>'name'",  # PostgreSQL/MySQL
                "json_age": "memo->>'age'",
            }
        )
        .values("id", "json_name", "json_age")
    )


# ●文字列連結（DBMS固有演算子の代替）
def string_concatenation():
    """
    DBMS固有の文字列連結演算子の代替
    Oracle: ||, MySQL: CONCAT, SQL Server: +
    """
    from django.db.models.functions import Concat

    # Django ORMでは統一的なConcat関数を使用
    return Employee.objects.annotate(
        full_info=Concat("emp_id", Value(": "), "emp_name", output_field=CharField())
    ).values("emp_id", "emp_name", "full_info")


# ●疑似配列の検索（アンチパターン）
def pseudo_array_search():
    """
    固定列による疑似配列検索（アンチパターン）
    """
    # c1からc10までの列を個別にチェック
    q_objects = Q()
    for i in range(1, 11):
        field_name = f"c{i}"
        q_objects |= Q(**{field_name: "A"})

    return ArrayTbl.objects.filter(q_objects)


# ●要素リストでの検索（推奨）
def element_list_search():
    """
    要素リストでの検索（推奨）
    """
    return ListElement.objects.filter(element="A").values("list_id").distinct()


# ●DBMS互換性のためのAbstraction Layer
class DatabaseAbstractionLayer:
    """
    DBMS固有機能の抽象化レイヤー
    """

    @staticmethod
    def get_array_length(model_class, array_field, target_length):
        """
        配列長取得の抽象化
        """
        from django.db import connection

        if "postgresql" in connection.settings_dict["ENGINE"]:
            # PostgreSQL
            return model_class.objects.extra(
                where=[f"array_length({array_field}, 1) >= %s"], params=[target_length]
            )
        else:
            # 他のDBMS：正規化テーブルで代替
            return Employee.objects.annotate(child_count=Count("employeechild")).filter(
                child_count__gte=target_length
            )

    @staticmethod
    def json_extract(model_class, json_field, key):
        """
        JSON抽出の抽象化
        """
        from django.db import connection

        if "postgresql" in connection.settings_dict["ENGINE"]:
            # PostgreSQL
            return model_class.objects.extra(
                select={f"json_{key}": f"{json_field}->>{key}"}
            )
        elif "mysql" in connection.settings_dict["ENGINE"]:
            # MySQL
            return model_class.objects.extra(
                select={f"json_{key}": f"{json_field}->>'$.{key}'"}
            )
        else:
            # 他のDBMS：制限あり
            return model_class.objects.all()


# ●ベンダーロックイン回避策
def vendor_lock_in_solutions():
    """
    ベンダーロックイン回避策
    """
    return {
        "problem": "ベンダーロックイン病 - DBMS固有機能への依存",
        "symptoms": [
            "PostgreSQL配列型の使用",
            "DBMS固有JSON操作",
            "固有の文字列演算子",
            "特殊データ型への依存",
        ],
        "solutions": [
            "標準SQL機能の使用",
            "正規化されたテーブル設計",
            "ORMによる抽象化",
            "ポータブルなデータ型の採用",
        ],
        "django_best_practices": [
            "CharField/TextField等の標準フィールド使用",
            "ForeignKey関係による正規化",
            "Database抽象化レイヤーの活用",
            "DBMS固有機能は最小限に",
        ],
        "migration_strategies": [
            "段階的なスキーマ移行",
            "データ変換スクリプト",
            "ダウンタイム最小化",
            "後方互換性の維持",
        ],
    }


# ===== 使用例 =====
if __name__ == "__main__":
    print("PostgreSQL配列操作:")
    print(postgresql_array_operations()[:3])

    print("\n正規化テーブルでの子供検索:")
    print(list(normalized_child_search()))

    print("\n文字列連結（統一API）:")
    print(list(string_concatenation())[:3])

    print("\n疑似配列検索（アンチパターン）:")
    print(list(pseudo_array_search())[:3])

    print("\n要素リスト検索（推奨）:")
    print(list(element_list_search())[:3])

    print("\nベンダーロックイン回避策:")
    print(vendor_lock_in_solutions())
