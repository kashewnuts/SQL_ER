# Django 4.2 ORM implementation of 03_ループ依存症.sql
# ループに依存したアンチパターンをDjango ORMで実装

from django.db import models
from django.db.models import Case, When, Value, Sum, F, IntegerField, Window
from django.db.models.functions import FirstValue, Lag

# ===== モデル定義 =====


class SalesIcecream(models.Model):
    shop_id = models.CharField(max_length=4)
    sale_date = models.DateField()
    sales_amt = models.IntegerField()

    class Meta:
        db_table = "salesicecream"
        unique_together = ["shop_id", "sale_date"]


class Receipts(models.Model):
    customer_id = models.CharField(max_length=4)
    seq = models.IntegerField()
    price = models.IntegerField()

    class Meta:
        db_table = "receipts"
        unique_together = ["customer_id", "seq"]


class StockHistory(models.Model):
    ticker_symbol = models.CharField(max_length=10)
    sale_date = models.DateField()
    closing_price = models.IntegerField()
    trend = models.IntegerField(default=0)  # -1, 0, 1

    class Meta:
        db_table = "stockhistory"
        unique_together = ["ticker_symbol", "sale_date"]


# ===== クエリ実装 =====


# ●患者1：累計計算のループ処理（アンチパターン）
def patient1_loop_cumulative():
    """
    Javaのループ処理をPythonで再現（アンチパターン）
    実際のWebアプリケーションでは絶対に使用しない
    """
    # このようなループ処理はDjangoで推奨されない
    # 大量のデータベースアクセスが発生し、パフォーマンスが悪い

    results = []
    cumulative = 0
    old_shop = ""

    # ORDER BYでソート済みのデータを取得
    sales_data = SalesIcecream.objects.order_by("shop_id", "sale_date")

    for sale in sales_data:
        current_shop = sale.shop_id

        # 店舗が変わったら累計をリセット
        if old_shop != current_shop:
            cumulative = sale.sales_amt
        else:
            cumulative += sale.sales_amt

        results.append(
            {
                "shop_id": current_shop,
                "sale_date": sale.sale_date,
                "sales_amt": sale.sales_amt,
                "cumulative": cumulative,
            }
        )

        old_shop = current_shop

    return results


# ●正しい解：ウィンドウ関数による累計計算
def window_function_cumulative():
    """
    ウィンドウ関数による累計計算（推奨）
    """
    return (
        SalesIcecream.objects.annotate(
            cumlative_amt=Window(
                expression=Sum("sales_amt"),
                partition_by=[F("shop_id")],
                order_by=F("sale_date").asc(),
            )
        )
        .values("shop_id", "sale_date", "sales_amt", "cumlative_amt")
        .order_by("shop_id", "sale_date")
    )


# ●ループの中で利用されているクエリ
def loop_base_query():
    """
    ループ処理で使用される基本クエリ
    """
    return SalesIcecream.objects.order_by("shop_id", "sale_date")


# ●患者2：最小枝番取得のループ処理（アンチパターン）
def patient2_loop_min_seq():
    """
    最小枝番取得のループ処理（アンチパターン）
    """
    results = []
    old_customer = ""

    # ORDER BYでソート済みのデータを取得
    receipts_data = Receipts.objects.order_by("customer_id", "seq", "price")

    for receipt in receipts_data:
        current_customer = receipt.customer_id

        # 顧客IDが変わったら、最小の連番を記録
        if old_customer != current_customer:
            results.append(
                {
                    "customer_id": current_customer,
                    "seq": receipt.seq,
                    "price": receipt.price,
                }
            )

        old_customer = current_customer

    return results


# ●正しい解：ウィンドウ関数による最小値取得
def window_function_min_seq():
    """
    ウィンドウ関数による最小枝番取得（推奨）
    """
    return (
        Receipts.objects.annotate(
            min_price=Window(
                expression=FirstValue("price"),
                partition_by=[F("customer_id")],
                order_by=F("seq").asc(),
            )
        )
        .filter(price=F("min_price"))
        .values("customer_id", "seq", "price")
    )


# ●患者3：株価トレンド更新のループ処理（アンチパターン）
def patient3_loop_stock_update():
    """
    株価トレンド更新のループ処理（アンチパターン）
    Django ORMでは bulk_update を使用すべき
    """
    # 危険: 大量のUPDATE文が個別に実行される
    old_ticker = ""
    old_price = 0

    stocks_data = StockHistory.objects.order_by("ticker_symbol", "sale_date")
    updates = []

    for stock in stocks_data:
        current_ticker = stock.ticker_symbol
        current_price = stock.closing_price

        if old_ticker == current_ticker:
            if current_price > old_price:
                trend = 1
            elif old_price == current_price:
                trend = 0
            else:
                trend = -1
        else:
            trend = 0

        stock.trend = trend
        updates.append(stock)

        old_price = current_price
        old_ticker = current_ticker

    # 一括更新（推奨）
    StockHistory.objects.bulk_update(updates, ["trend"])
    return len(updates)


# ●正しい解：ウィンドウ関数による株価トレンド計算
def window_function_stock_trend():
    """
    ウィンドウ関数による株価トレンド計算（推奨）

    SQLite3制約 (3.43.2+前提):
    - Lag() ウィンドウ関数はSQLite3 3.43.2以降で完全サポート
    - 複雑なCase/When式とウィンドウ関数の組み合わせではパフォーマンスが
      PostgreSQL/MySQLより劣る場合があります
    """
    return (
        StockHistory.objects.annotate(
            prev_price=Window(
                expression=Lag("closing_price"),
                partition_by=[F("ticker_symbol")],
                order_by=F("sale_date").asc(),
            )
        )
        .annotate(
            calculated_trend=Case(
                When(prev_price__isnull=True, then=Value(0)),  # 最初のレコード
                When(closing_price__gt=F("prev_price"), then=Value(1)),
                When(closing_price=F("prev_price"), then=Value(0)),
                When(closing_price__lt=F("prev_price"), then=Value(-1)),
                default=Value(0),
                output_field=IntegerField(),
            )
        )
        .values(
            "ticker_symbol",
            "sale_date",
            "closing_price",
            "prev_price",
            "calculated_trend",
        )
    )


# ●バルク更新による効率的なトレンド更新
def bulk_update_stock_trend():
    """
    ウィンドウ関数 + バルク更新による効率的な処理
    """
    # ウィンドウ関数でトレンドを計算
    calculated_data = window_function_stock_trend()

    # バルク更新用のリストを作成
    updates = []
    for data in calculated_data:
        stock = StockHistory.objects.get(
            ticker_symbol=data["ticker_symbol"], sale_date=data["sale_date"]
        )
        stock.trend = data["calculated_trend"]
        updates.append(stock)

    # 一括更新
    StockHistory.objects.bulk_update(updates, ["trend"])
    return len(updates)


# ●パフォーマンス比較
def performance_comparison():
    """
    ループ処理 vs ウィンドウ関数のパフォーマンス比較
    """
    return {
        "loop_approach": {
            "description": "N+1問題が発生、大量のクエリ実行",
            "queries": "データ件数分のクエリ",
            "performance": "非常に遅い",
        },
        "window_function_approach": {
            "description": "単一クエリで集合処理",
            "queries": "1つのクエリ",
            "performance": "高速",
        },
        "django_best_practices": [
            "select_related/prefetch_related を使用",
            "bulk_create/bulk_update を使用",
            "ウィンドウ関数を活用",
            "N+1問題を避ける",
        ],
    }


# ===== 使用例 =====
if __name__ == "__main__":
    print("【アンチパターン】患者1のループ累計:")
    print(patient1_loop_cumulative()[:5])  # 最初の5件のみ表示

    print("\n【推奨】ウィンドウ関数による累計:")
    print(list(window_function_cumulative())[:5])

    print("\n【アンチパターン】患者2のループ最小枝番:")
    print(patient2_loop_min_seq())

    print("\n【推奨】ウィンドウ関数による最小枝番:")
    print(list(window_function_min_seq()))

    print("\n【推奨】ウィンドウ関数による株価トレンド:")
    print(list(window_function_stock_trend())[:5])

    print("\nパフォーマンス比較:")
    print(performance_comparison())
