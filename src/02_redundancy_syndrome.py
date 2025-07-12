# Django 4.2 ORM implementation of 02_冗長性症候群.sql
# 冗長なSQL構造のアンチパターンをDjango ORMで実装

from django.db import models
from django.db.models import Case, When, Value, Sum, Q, IntegerField, CharField
from datetime import date, timedelta

# ===== モデル定義 =====


class PizzaSales(models.Model):
    customer_id = models.IntegerField()
    sale_date = models.DateField()
    sales_amt = models.IntegerField()

    class Meta:
        db_table = "pizzasales"
        unique_together = ["customer_id", "sale_date"]


# ===== クエリ実装 =====


# ●ワイリーの解：UNIONでクエリを繋げる
def union_redundant_solution():
    """
    冗長なUNIONクエリ（アンチパターン）
    各期間ごとに別々のクエリを作成
    """
    base_date = date(2024, 6, 30)

    # 0-30日前
    q1 = (
        PizzaSales.objects.filter(
            sale_date__range=(base_date - timedelta(days=30), base_date)
        )
        .values("customer_id")
        .annotate(
            term=Value("0-30日前は", output_field=CharField()),
            term_amt=Sum("sales_amt"),
        )
        .values("customer_id", "term", "term_amt")
    )

    # 31-60日前
    q2 = (
        PizzaSales.objects.filter(
            sale_date__range=(
                base_date - timedelta(days=60),
                base_date - timedelta(days=31),
            )
        )
        .values("customer_id")
        .annotate(
            term=Value("31日-60日前は", output_field=CharField()),
            term_amt=Sum("sales_amt"),
        )
        .values("customer_id", "term", "term_amt")
    )

    # 61-90日前
    q3 = (
        PizzaSales.objects.filter(
            sale_date__range=(
                base_date - timedelta(days=90),
                base_date - timedelta(days=61),
            )
        )
        .values("customer_id")
        .annotate(
            term=Value("61日-90日前は", output_field=CharField()),
            term_amt=Sum("sales_amt"),
        )
        .values("customer_id", "term", "term_amt")
    )

    # 91日以上前
    q4 = (
        PizzaSales.objects.filter(sale_date__lt=base_date - timedelta(days=91))
        .values("customer_id")
        .annotate(
            term=Value("91日以上前は", output_field=CharField()),
            term_amt=Sum("sales_amt"),
        )
        .values("customer_id", "term", "term_amt")
    )

    # UNIONで結合（Django ORMでは.union()を使用）
    return q1.union(q2, q3, q4).order_by("customer_id", "term")


# ●CASE式による解
def case_improved_solution():
    """
    CASE式を使った改善版（推奨）
    1つのクエリで全期間を処理
    """
    base_date = date(2024, 6, 30)

    return (
        PizzaSales.objects.values("customer_id")
        .annotate(
            term_0_30=Sum(
                Case(
                    When(
                        sale_date__range=(base_date - timedelta(days=30), base_date),
                        then="sales_amt",
                    ),
                    default=Value(0),
                    output_field=IntegerField(),
                )
            ),
            term_31_60=Sum(
                Case(
                    When(
                        sale_date__range=(
                            base_date - timedelta(days=60),
                            base_date - timedelta(days=31),
                        ),
                        then="sales_amt",
                    ),
                    default=Value(0),
                    output_field=IntegerField(),
                )
            ),
            term_61_90=Sum(
                Case(
                    When(
                        sale_date__range=(
                            base_date - timedelta(days=90),
                            base_date - timedelta(days=61),
                        ),
                        then="sales_amt",
                    ),
                    default=Value(0),
                    output_field=IntegerField(),
                )
            ),
            term_91_plus=Sum(
                Case(
                    When(
                        sale_date__lt=base_date - timedelta(days=91), then="sales_amt"
                    ),
                    default=Value(0),
                    output_field=IntegerField(),
                )
            ),
        )
        .filter(
            # 何らかの売上がある顧客のみ
            Q(term_0_30__gt=0)
            | Q(term_31_60__gt=0)
            | Q(term_61_90__gt=0)
            | Q(term_91_plus__gt=0)
        )
        .order_by("customer_id")
    )


# ●期間を動的に生成する汎用的な解法
def dynamic_period_analysis(base_date=None, period_days=30):
    """
    期間を動的に生成する汎用的な分析
    base_date: 基準日（デフォルト: 2024-06-30）
    period_days: 期間の日数（デフォルト: 30日）
    """
    if base_date is None:
        base_date = date(2024, 6, 30)

    periods = []
    for i in range(4):  # 4期間分
        start_days = (i + 1) * period_days
        end_days = i * period_days

        if i == 3:  # 最後の期間は「以上前」
            condition = Q(sale_date__lt=base_date - timedelta(days=start_days))
            label = f"{start_days}日以上前"
        else:
            condition = Q(
                sale_date__range=(
                    base_date - timedelta(days=start_days),
                    base_date - timedelta(days=end_days + 1),
                )
            )
            label = f"{end_days + 1}-{start_days}日前"

        periods.append((condition, label))

    # 動的にCase式を構築
    annotations = {}
    for i, (condition, label) in enumerate(periods):
        field_name = f"period_{i}"
        annotations[field_name] = Sum(
            Case(
                When(condition, then="sales_amt"),
                default=Value(0),
                output_field=IntegerField(),
            )
        )

    return PizzaSales.objects.values("customer_id").annotate(**annotations)


# ●UNIONとCASEのパフォーマンス比較用
def performance_comparison():
    """
    UNIONとCASE式のパフォーマンス比較
    実際の使用では .explain() や Django Debug Toolbar を使用
    """
    print("UNION版のクエリ数:", 4)  # 4つの個別クエリ + UNION
    print("CASE版のクエリ数:", 1)  # 1つのクエリ

    # Django ORMではraw SQLを取得してクエリ分析可能
    union_query = union_redundant_solution()
    case_query = case_improved_solution()

    return {"union_query": str(union_query.query), "case_query": str(case_query.query)}


# ===== 使用例 =====
if __name__ == "__main__":
    print("冗長なUNION解法:")
    print(list(union_redundant_solution()))

    print("\n改善されたCASE式解法:")
    print(list(case_improved_solution()))

    print("\n動的期間分析:")
    print(list(dynamic_period_analysis()))

    print("\nパフォーマンス比較:")
    print(performance_comparison())
