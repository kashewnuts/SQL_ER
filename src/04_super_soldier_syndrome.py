# Django 4.2 ORM implementation of 04_スーパーソルジャー病.sql
# 過度に複雑なクエリのアンチパターンをDjango ORMで実装

from django.db import models
from django.db.models import Count, Max, F, Window
from django.db.models.functions import Extract

# ===== モデル定義 =====


class Orders(models.Model):
    order_id = models.IntegerField(primary_key=True)
    order_shop = models.CharField(max_length=32)
    order_name = models.CharField(max_length=32)
    order_date = models.DateField()

    class Meta:
        db_table = "orders"


class OrderReceipts(models.Model):
    order = models.ForeignKey(Orders, on_delete=models.CASCADE)
    order_receipt_id = models.IntegerField()
    item_group = models.CharField(max_length=32)
    delivery_date = models.DateField()

    class Meta:
        db_table = "orderreceipts"
        unique_together = ["order", "order_receipt_id"]


class Departments(models.Model):
    department = models.CharField(max_length=16)
    division = models.CharField(max_length=16)
    start_date = models.DateField()

    class Meta:
        db_table = "departments"


# ===== クエリ実装 =====


# ●ワイリーの解：WHERE句に間違いあり（エラーになる例）
def wiley_wrong_alias():
    """
    Django ORMでは別名（alias）をWHERE句で直接使用できない
    このパターンはエラーになる
    """
    # これはDjango ORMではコンパイル時エラーになる
    # SQLのように別名をWHERE句で使用することはできない

    # 正しくは annotate + filter を使用
    pass


# ●ワイリーの解：修正版
def wiley_corrected_version():
    """
    配送日と注文日の差が3日以上の注文
    """
    return (
        Orders.objects.select_related()
        .filter(orderreceipts__delivery_date__gt=F("order_date") + 3)
        .annotate(diff_days=F("orderreceipts__delivery_date") - F("order_date"))
        .values("order_id", "order_name", "diff_days")
    )


# ●Django ORMでの日付計算（timedelta使用）
def date_calculation_django():
    """
    Djangoでの日付計算
    """
    from datetime import timedelta

    return (
        Orders.objects.select_related()
        .annotate(diff_days=F("orderreceipts__delivery_date") - F("order_date"))
        .filter(orderreceipts__delivery_date__gt=F("order_date") + timedelta(days=3))
        .values("order_id", "order_name", "diff_days")
    )


# ●SQL Serverでの日付の減算（Django ORMでは対応不要）
def sql_server_datediff():
    """
    SQL ServerのDATEDIFF関数はDjangoでサポートされていない
    代替案：Extractを使用した年月日の計算
    """
    # Django ORMでは直接的なDATEDIFF関数はない
    # 日付の差は単純な減算で計算可能
    return (
        Orders.objects.select_related()
        .annotate(
            order_year=Extract("order_date", "year"),
            delivery_year=Extract("orderreceipts__delivery_date", "year"),
            diff_days=F("orderreceipts__delivery_date") - F("order_date"),
        )
        .filter(diff_days__gte=3)
        .values("order_id", "order_name", "diff_days")
    )


# ●ヘレンの解：MAX関数を使う
def helen_max_function():
    """
    GROUP BYとMAX関数による重複排除
    """
    return (
        Orders.objects.select_related()
        .filter(orderreceipts__delivery_date__gt=F("order_date") + 3)
        .values("order_id")
        .annotate(
            order_name=Max("order_name"),
            max_diff_days=Max(F("orderreceipts__delivery_date") - F("order_date")),
        )
    )


# ●ワイリーの解：MAX関数を使って注文明細数を取得
def wiley_max_with_count():
    """
    注文ごとの明細数を取得（GROUP BYとMAX使用）
    """
    return Orders.objects.values("order_id").annotate(
        order_name=Max("order_name"),
        order_date=Max("order_date"),
        item_count=Count("orderreceipts"),
    )


# ●ヘレンの解：ウィンドウ関数を使う（推奨）
def helen_window_function():
    """
    ウィンドウ関数による注文明細数取得（推奨）
    重複を避けつつ効率的に処理
    """
    return (
        Orders.objects.select_related()
        .annotate(
            item_count=Window(
                expression=Count("orderreceipts"), partition_by=[F("order_id")]
            )
        )
        .distinct()
        .values("order_id", "order_name", "order_date", "item_count")
    )


# ●複雑クエリの分解例
def complex_query_breakdown():
    """
    複雑なクエリを段階的に分解
    スーパーソルジャー病の対策
    """
    # ステップ1: 基本的な注文情報を取得
    base_orders = Orders.objects.all()

    # ステップ2: 配送遅延のある注文をフィルタ
    delayed_orders = base_orders.filter(
        orderreceipts__delivery_date__gt=F("order_date") + 3
    )

    # ステップ3: 集約情報を追加
    result = delayed_orders.values("order_id").annotate(
        order_name=Max("order_name"),
        max_diff_days=Max(F("orderreceipts__delivery_date") - F("order_date")),
        item_count=Count("orderreceipts"),
    )

    return result


# ●サブクエリを使った複雑な条件分岐
def complex_conditional_query():
    """
    複雑な条件分岐を含むクエリ
    """
    from django.db.models import Subquery, OuterRef

    # サブクエリ：各注文の最大配送遅延日数
    max_delay_subquery = OrderReceipts.objects.filter(
        order_id=OuterRef("order_id")
    ).aggregate(max_delay=Max(F("delivery_date") - F("order__order_date")))["max_delay"]

    return (
        Orders.objects.annotate(
            max_delay=Subquery(
                OrderReceipts.objects.filter(order_id=OuterRef("order_id"))
                .aggregate(max_delay=Max(F("delivery_date") - F("order__order_date")))
                .values("max_delay")
            )
        )
        .filter(max_delay__gte=3)
        .values("order_id", "order_name", "max_delay")
    )


# ●パフォーマンス最適化のベストプラクティス
def performance_optimized_query():
    """
    パフォーマンスを考慮した最適化されたクエリ
    """
    return (
        Orders.objects.select_related()
        .prefetch_related("orderreceipts_set")
        .annotate(
            item_count=Count("orderreceipts"),
            max_delivery_delay=Max(F("orderreceipts__delivery_date") - F("order_date")),
        )
        .filter(max_delivery_delay__gte=3)
        .values(
            "order_id", "order_name", "order_date", "item_count", "max_delivery_delay"
        )
    )


# ●アンチパターンの回避策
def anti_pattern_solutions():
    """
    スーパーソルジャー病の回避策
    """
    return {
        "problem": "スーパーソルジャー病 - 過度に複雑な単一クエリ",
        "symptoms": [
            "巨大で読みにくいクエリ",
            "パフォーマンスの問題",
            "デバッグの困難",
            "メンテナンスの複雑さ",
        ],
        "solutions": [
            "クエリの分割",
            "ビューやCTEの活用",
            "ウィンドウ関数の適切な使用",
            "インデックスの最適化",
        ],
        "django_best_practices": [
            "select_related/prefetch_relatedの使用",
            "クエリセットの段階的構築",
            "annotate/aggregateの適切な使用",
            "Djangoクエリアナライザーの活用",
        ],
    }


# ===== 使用例 =====
if __name__ == "__main__":
    print("ワイリーの修正版:")
    print(list(wiley_corrected_version()))

    print("\nヘレンのMAX関数解法:")
    print(list(helen_max_function()))

    print("\nヘレンのウィンドウ関数解法（推奨）:")
    print(list(helen_window_function()))

    print("\n複雑クエリの分解例:")
    print(list(complex_query_breakdown()))

    print("\nパフォーマンス最適化版:")
    print(list(performance_optimized_query()))

    print("\nアンチパターン回避策:")
    print(anti_pattern_solutions())
