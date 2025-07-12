# Django 4.2 ORM implementation of 05_時代錯誤症候群.sql
# 古いSQL記法のアンチパターンをDjango ORMで実装

from django.db import models
from django.db.models import (
    Case,
    When,
    Value,
    Sum,
    F,
    Q,
    IntegerField,
    OuterRef,
    Subquery,
)

# ===== モデル定義 =====


class Suppliers(models.Model):
    sup = models.CharField(max_length=1, primary_key=True)
    city = models.CharField(max_length=16)
    area = models.CharField(max_length=16)
    ship_flg = models.CharField(max_length=16)  # '可' or '不可'
    item_cnt = models.IntegerField()

    class Meta:
        db_table = "suppliers"


class Manufacturers(models.Model):
    mfs = models.CharField(max_length=1, primary_key=True)
    city = models.CharField(max_length=16)
    area = models.CharField(max_length=16)
    req_flg = models.CharField(max_length=16)  # '要' or '不要'

    class Meta:
        db_table = "manufacturers"


# ===== クエリ実装 =====


# ●ワイリーの解：冗長なUNION（アンチパターン）
def wiley_redundant_union():
    """
    冗長なUNION ALLによる解法（アンチパターン）
    出荷可能業者と不可能業者を別々に処理
    """
    # 出荷可能業者のパート
    shippable_suppliers = (
        Suppliers.objects.filter(ship_flg="可")
        .values("city")
        .annotate(able_cnt=Sum("item_cnt"))
    )

    # 出荷可能業者で条件を満たすもの
    q1 = (
        Suppliers.objects.filter(ship_flg="可")
        .filter(city__in=[s["city"] for s in shippable_suppliers])
        .extra(
            where=[
                "item_cnt >= (SELECT SUM(item_cnt) * 0.5 FROM suppliers WHERE ship_flg = '可' AND city = suppliers.city)"
            ]
        )
        .values("sup", "city", "ship_flg", "item_cnt")
    )

    # 出荷不可能業者のパート
    non_shippable_suppliers = (
        Suppliers.objects.filter(ship_flg="不可")
        .values("city")
        .annotate(disable_cnt=Sum("item_cnt"))
    )

    # 出荷不可能業者で条件を満たすもの
    q2 = (
        Suppliers.objects.filter(ship_flg="不可")
        .filter(city__in=[s["city"] for s in non_shippable_suppliers])
        .extra(
            where=[
                "item_cnt >= (SELECT SUM(item_cnt) * 0.5 FROM suppliers WHERE ship_flg = '不可' AND city = suppliers.city)"
            ]
        )
        .values("sup", "city", "ship_flg", "item_cnt")
    )

    # UNION ALL（Django ORMでは.union()を使用）
    return q1.union(q2, all=True)


# ●ヘレンの解：共通表式を利用（CTEの代替）
def helen_cte_alternative():
    """
    共通表式（CTE）の代替としてサブクエリを使用
    Django ORMではCTEの直接サポートなし（Django 4.2時点）

    SQLite3制約 (3.43.2+前提):
    - 複雑なサブクエリとCase/When式の組み合わせはSQLite3 3.43.2以降で
      改善されているが、パフォーマンスはPostgreSQL/MySQLより劣る場合があります
    - 集約関数の組み合わせは基本的にサポートされています
    """
    # CTEの代替：annotateでサブクエリ結果を追加
    suppliers_with_totals = Suppliers.objects.values("city").annotate(
        able_cnt=Sum(
            Case(
                When(ship_flg="可", then="item_cnt"),
                default=Value(0),
                output_field=IntegerField(),
            )
        ),
        disable_cnt=Sum(
            Case(
                When(ship_flg="不可", then="item_cnt"),
                default=Value(0),
                output_field=IntegerField(),
            )
        ),
    )

    # 辞書形式で都市別集計を取得
    city_totals = {
        item["city"]: {"able_cnt": item["able_cnt"], "disable_cnt": item["disable_cnt"]}
        for item in suppliers_with_totals
    }

    # 出荷可能業者
    q1 = Suppliers.objects.filter(ship_flg="可").annotate(
        threshold=Value(0)  # プレースホルダー
    )

    # 出荷不可能業者
    q2 = Suppliers.objects.filter(ship_flg="不可").annotate(
        threshold=Value(0)  # プレースホルダー
    )

    # Python側でフィルタリング（非効率だが理解しやすい）
    result = []
    for supplier in Suppliers.objects.all():
        city_data = city_totals.get(supplier.city, {"able_cnt": 0, "disable_cnt": 0})

        if supplier.ship_flg == "可":
            threshold = city_data["able_cnt"] * 0.5
        else:
            threshold = city_data["disable_cnt"] * 0.5

        if supplier.item_cnt >= threshold:
            result.append(
                {
                    "sup": supplier.sup,
                    "city": supplier.city,
                    "ship_flg": supplier.ship_flg,
                    "item_cnt": supplier.item_cnt,
                }
            )

    return result


# ●ロバートの解：分岐をCASE式で表現（推奨）
def robert_case_expression():
    """
    CASE式による分岐処理（推奨）
    UNIONを使わずに単一クエリで処理
    """
    # 都市別・出荷状況別の集計を事前計算
    city_stats = Suppliers.objects.values("city").annotate(
        able_cnt=Sum(
            Case(
                When(ship_flg="可", then="item_cnt"),
                default=Value(0),
                output_field=IntegerField(),
            )
        ),
        disable_cnt=Sum(
            Case(
                When(ship_flg="不可", then="item_cnt"),
                default=Value(0),
                output_field=IntegerField(),
            )
        ),
    )

    # 辞書形式で保存
    city_lookup = {stat["city"]: stat for stat in city_stats}

    # 単一クエリでCASE式を使用
    from django.db.models import Subquery, OuterRef

    return (
        Suppliers.objects.annotate(
            able_cnt=Subquery(
                Suppliers.objects.filter(
                    city=OuterRef("city"), ship_flg="可"
                ).aggregate(total=Sum("item_cnt"))["total"]
            ),
            disable_cnt=Subquery(
                Suppliers.objects.filter(
                    city=OuterRef("city"), ship_flg="不可"
                ).aggregate(total=Sum("item_cnt"))["total"]
            ),
        )
        .annotate(
            threshold=Case(
                When(ship_flg="可", then=F("able_cnt") * 0.5),
                When(ship_flg="不可", then=F("disable_cnt") * 0.5),
                default=Value(0),
                output_field=IntegerField(),
            )
        )
        .filter(item_cnt__gte=F("threshold"))
        .values("sup", "city", "ship_flg", "item_cnt")
    )


# ●Django ORMでのCTE代替パターン
def django_cte_patterns():
    """
    Django ORMでのCTE（Common Table Expression）代替パターン
    """
    # パターン1: Subqueryを使用
    subquery_pattern = Suppliers.objects.filter(
        item_cnt__gte=Subquery(
            Suppliers.objects.filter(
                city=OuterRef("city"), ship_flg=OuterRef("ship_flg")
            )
            .aggregate(avg_cnt=Sum("item_cnt") * 0.5)
            .values("avg_cnt")
        )
    )

    # パターン2: annotateを使用した段階的構築
    annotate_pattern = (
        Suppliers.objects.values("city", "ship_flg")
        .annotate(total_cnt=Sum("item_cnt"), threshold=F("total_cnt") * 0.5)
        .values("city", "ship_flg", "threshold")
    )

    # パターン3: Pythonでの後処理
    python_pattern = list(Suppliers.objects.all())

    return {
        "subquery": list(subquery_pattern.values()),
        "annotate": list(annotate_pattern),
        "python": python_pattern[:5],  # サンプルのみ
    }


# ●WITH句の代替実装
def with_clause_alternative():
    """
    WITH句（CTE）の代替実装
    Django 4.2ではネイティブCTEサポートなし
    """
    # Step 1: 都市別集計（WITH句相当）
    city_aggregates = Suppliers.objects.values("city").annotate(
        able_cnt=Sum(
            Case(
                When(ship_flg="可", then="item_cnt"),
                default=Value(0),
                output_field=IntegerField(),
            )
        ),
        disable_cnt=Sum(
            Case(
                When(ship_flg="不可", then="item_cnt"),
                default=Value(0),
                output_field=IntegerField(),
            )
        ),
    )

    # Step 2: メインクエリで集計結果を使用
    result = []
    city_dict = {agg["city"]: agg for agg in city_aggregates}

    for supplier in Suppliers.objects.all():
        city_agg = city_dict.get(supplier.city, {"able_cnt": 0, "disable_cnt": 0})

        if supplier.ship_flg == "可":
            threshold = city_agg["able_cnt"] * 0.5
        else:
            threshold = city_agg["disable_cnt"] * 0.5

        if supplier.item_cnt >= threshold:
            result.append(
                {
                    "sup": supplier.sup,
                    "city": supplier.city,
                    "ship_flg": supplier.ship_flg,
                    "item_cnt": supplier.item_cnt,
                    "threshold": threshold,
                }
            )

    return result


# ●現代的なアプローチ（Django 4.2推奨）
def modern_django_approach():
    """
    Django 4.2での現代的なアプローチ
    """
    return (
        Suppliers.objects.annotate(
            city_able_total=Sum(
                Case(
                    When(Q(city=F("city")) & Q(ship_flg="可"), then="item_cnt"),
                    default=Value(0),
                    output_field=IntegerField(),
                )
            ),
            city_disable_total=Sum(
                Case(
                    When(Q(city=F("city")) & Q(ship_flg="不可"), then="item_cnt"),
                    default=Value(0),
                    output_field=IntegerField(),
                )
            ),
        )
        .annotate(
            required_threshold=Case(
                When(ship_flg="可", then=F("city_able_total") * 0.5),
                When(ship_flg="不可", then=F("city_disable_total") * 0.5),
                default=Value(0),
                output_field=IntegerField(),
            )
        )
        .filter(item_cnt__gte=F("required_threshold"))
        .values("sup", "city", "ship_flg", "item_cnt", "required_threshold")
    )


# ●アンチパターンの解説
def anti_pattern_explanation():
    """
    時代錯誤症候群のアンチパターン解説
    """
    return {
        "problem": "時代錯誤症候群 - 古いSQL記法の使用",
        "symptoms": [
            "冗長なUNION ALLの多用",
            "WITH句（CTE）の未使用",
            "複雑な結合条件",
            "サブクエリの乱用",
        ],
        "solutions": [
            "WITH句（CTE）の活用",
            "CASE式による条件分岐",
            "ウィンドウ関数の使用",
            "モダンなSQL構文の採用",
        ],
        "django_alternatives": [
            "annotate/aggregateの活用",
            "Subqueryクラスの使用",
            "Case/When式の活用",
            "F式による効率的な計算",
        ],
        "limitations": [
            "Django 4.2時点でCTEの直接サポートなし",
            "複雑な集計はPython側処理が必要な場合あり",
            "パフォーマンス調整が重要",
        ],
    }


# ===== 使用例 =====
if __name__ == "__main__":
    print("ワイリーの冗長UNION解法:")
    print(list(wiley_redundant_union())[:3])

    print("\nヘレンのCTE代替解法:")
    print(helen_cte_alternative()[:3])

    print("\nロバートのCASE式解法（推奨）:")
    print(list(robert_case_expression())[:3])

    print("\nDjango CTEパターン:")
    patterns = django_cte_patterns()
    print(f"Subquery: {len(patterns['subquery'])}件")
    print(f"Annotate: {len(patterns['annotate'])}件")

    print("\n現代的Djangoアプローチ:")
    print(list(modern_django_approach())[:3])

    print("\nアンチパターン解説:")
    print(anti_pattern_explanation())
