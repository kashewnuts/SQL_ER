# Django 4.2 ORM implementation of 00_序章.sql
# SQLアンチパターンの序章のサンプルをDjango ORMで実装

from django.db import models
from django.db.models import (
    Case,
    When,
    Value,
    Sum,
    Avg,
    F,
    IntegerField,
    CharField,
    RowRange,
    Window,
)
from django.db.models.functions import Round

# ===== モデル定義 =====


class Warehouse(models.Model):
    warehouse_id = models.IntegerField(primary_key=True)
    region = models.CharField(max_length=32)

    class Meta:
        db_table = "warehouse"


class City(models.Model):
    city = models.CharField(max_length=32, primary_key=True)
    population = models.IntegerField()

    class Meta:
        db_table = "city"


class ItemPrice(models.Model):
    item_id = models.CharField(max_length=3)
    year = models.IntegerField()
    item_name = models.CharField(max_length=32)
    price_tax_ex = models.IntegerField()
    price_tax_in = models.IntegerField()

    class Meta:
        db_table = "itemprice"
        unique_together = ["item_id", "year"]


class SalesIcecream(models.Model):
    shop_id = models.CharField(max_length=4)
    sale_date = models.DateField()
    sales_amt = models.IntegerField()

    class Meta:
        db_table = "salesicecream"
        unique_together = ["shop_id", "sale_date"]


class Weights(models.Model):
    student_id = models.CharField(max_length=4, primary_key=True)
    weight = models.IntegerField()

    class Meta:
        db_table = "weights"


# ===== クエリ実装 =====


# ●倉庫IDから拠点の都市を割り出すクエリ（DECODE関数）
# Django ORMではDECODE関数は直接サポートされていないため、CASE式で代替
def warehouse_city_decode():
    """
    DECODE関数はDjangoでサポートされていないため、CASE式を使用

    * DECODE関数はOracleの特有の関数であり、Django ORMではCASE式を使用して同様の機能を実現する
    """
    return Warehouse.objects.annotate(
        city=Case(
            When(warehouse_id=1, then=Value("New York")),
            When(warehouse_id=2, then=Value("New Jersey")),
            When(warehouse_id=3, then=Value("Los Angels")),
            When(warehouse_id=4, then=Value("Seattle")),
            When(warehouse_id=5, then=Value("San Francisco")),
            default=Value("Non domestic"),
            output_field=CharField(),
        )
    ).values("city", "region")


# ●CASE式による汎用的なクエリ
def warehouse_city_case():
    return Warehouse.objects.annotate(
        city=Case(
            When(warehouse_id=1, then=Value("New York")),
            When(warehouse_id=2, then=Value("New Jersey")),
            When(warehouse_id=3, then=Value("Los Angels")),
            When(warehouse_id=4, then=Value("Seattle")),
            When(warehouse_id=5, then=Value("San Francisco")),
            default=Value(None),
            output_field=CharField(),
        )
    ).values("city", "region")


# ●単純CASE式の書き方（Django ORMでは通常のCASE式と同じ）
def warehouse_city_simple_case():
    """
    DjangoのCase/When構文は既に単純CASE式に相当
    """
    return warehouse_city_case()


# ●CASE式は短絡評価
def warehouse_city_short_circuit():
    return Warehouse.objects.annotate(
        city=Case(
            When(warehouse_id__in=[1, 2], then=Value("New York")),
            When(warehouse_id=2, then=Value("New Jersey")),  # この条件は実行されない
            When(warehouse_id=3, then=Value("Los Angels")),
            When(warehouse_id=4, then=Value("Seattle")),
            When(warehouse_id=5, then=Value("San Francisco")),
            default=Value(None),
            output_field=CharField(),
        )
    ).values("city", "region")


# ●戻り値は同じデータ型でなければエラーになる
def warehouse_city_mixed_types():
    """
    Django ORMでは型の不整合はPythonレベルでエラーになる
    """
    # このクエリは実際には実行時エラーになる可能性がある
    return Warehouse.objects.annotate(
        city=Case(
            When(warehouse_id=1, then=Value("New York")),
            When(warehouse_id=2, then=Value(100)),  # 型が異なる
            When(warehouse_id=3, then=Value("Los Angels")),
            When(warehouse_id=4, then=Value(500)),  # 型が異なる
            When(warehouse_id=5, then=Value("San Francisco")),
            default=Value(None),
            output_field=CharField(),  # CharField指定で文字列に変換される
        )
    ).values("city", "region")


# ●患者2のコード（SQL Server PIVOT）
def city_pivot_sql_server():
    """
    SQL ServerのPIVOT構文はDjangoで直接サポートされていない
    代替案：Case式を使用したピボット
    """
    # Django ORMでは直接的なPIVOTサポートなし
    # 代替案は以下のcase_pivot_solution()を参照
    pass


# ●ロバートの解：CASE式を使うピボット
def case_pivot_solution():
    return City.objects.aggregate(
        new_york=Sum(
            Case(
                When(city="New York", then="population"),
                default=Value(0),
                output_field=IntegerField(),
            )
        ),
        los_angels=Sum(
            Case(
                When(city="Los Angels", then="population"),
                default=Value(0),
                output_field=IntegerField(),
            )
        ),
        san_francisco=Sum(
            Case(
                When(city="San Francisco", then="population"),
                default=Value(0),
                output_field=IntegerField(),
            )
        ),
        new_orleans=Sum(
            Case(
                When(city="New Orleans", then="population"),
                default=Value(0),
                output_field=IntegerField(),
            )
        ),
    )


# ●SUM関数なしでCASE式を使うと
def case_without_sum():
    return City.objects.annotate(
        new_york=Case(
            When(city="New York", then="population"),
            default=Value(0),
            output_field=IntegerField(),
        ),
        los_angels=Case(
            When(city="Los Angels", then="population"),
            default=Value(0),
            output_field=IntegerField(),
        ),
        san_francisco=Case(
            When(city="San Francisco", then="population"),
            default=Value(0),
            output_field=IntegerField(),
        ),
        new_orleans=Case(
            When(city="New Orleans", then="population"),
            default=Value(0),
            output_field=IntegerField(),
        ),
    ).values("new_york", "los_angels", "san_francisco", "new_orleans")


# ●ワイリーの解答（UNIONを使う）
def union_solution():
    # 2003年以前は税抜き価格
    q1 = (
        ItemPrice.objects.filter(year__lte=2003)
        .annotate(price=F("price_tax_ex"))
        .values("item_name", "year", "price")
    )

    # 2004年以降は税込み価格
    q2 = (
        ItemPrice.objects.filter(year__gte=2004)
        .annotate(price=F("price_tax_in"))
        .values("item_name", "year", "price")
    )

    return q1.union(q2, all=True)


# ●ヘレンの解答（CASE式を使う）
def case_solution():
    return ItemPrice.objects.annotate(
        price=Case(
            When(year__lte=2003, then="price_tax_ex"),
            When(year__gte=2004, then="price_tax_in"),
            default=Value(None),
            output_field=IntegerField(),
        )
    ).values("item_name", "year", "price")


# ●ワイリーの解（WHERE句でCASE式）
def where_case_solution():
    return (
        ItemPrice.objects.annotate(
            price=Case(
                When(year__lte=2003, then="price_tax_ex"),
                When(year__gte=2004, then="price_tax_in"),
                default=Value(None),
                output_field=IntegerField(),
            )
        )
        .filter(price__gte=600)
        .values("item_name", "year")
    )


# ●集計単位を変換して人口の合計を求める
def region_population_sum():
    return (
        City.objects.annotate(
            region=Case(
                When(city__in=["New York", "New Orleans"], then=Value("East Coast")),
                When(
                    city__in=["San Francisco", "Los Angels"], then=Value("West Coast")
                ),
                default=Value(None),
                output_field=CharField(),
            )
        )
        .values("region")
        .annotate(sum_pop=Sum("population"))
        .exclude(region__isnull=True)
    )


# ●OracleとPostgreSQLとMySQL以外での書き方
def region_population_sum_verbose():
    """
    Django ORMでは GROUP BY に同じ式を書く必要はない
    """
    return region_population_sum()  # Djangoでは上記と同じ


# ●値の入れ替え：患者のUPDATE文
def swap_population_naive():
    """
    複数のUPDATE文による値の入れ替え（危険）
    """
    City.objects.filter(city="New York").update(population=3840000)
    City.objects.filter(city="Los Angels").update(population=8460000)


# ●ヘレンの解：UPDATE文でCASE式を使う
def swap_population_case():
    """
    Django ORMでのCASE式を使った安全な値の入れ替え
    """
    City.objects.filter(city__in=["New York", "Los Angels"]).update(
        population=Case(
            When(city="New York", then=Value(3840000)),
            When(city="Los Angels", then=Value(8460000)),
            default=F("population"),
            output_field=IntegerField(),
        )
    )


# ●スカラサブクエリで一般化したUPDATE文
def swap_population_subquery():
    """
    サブクエリを使った値の入れ替え
    Django ORMでは OuterRef を使用
    """

    # DjangoではこのようなCASE内でのサブクエリは複雑になる
    # 実用的ではないため、一時的な値を使った方法が推奨される
    pass


# ●患者のクエリ：相関サブクエリで累計を求める
def cumulative_with_subquery():
    """
    相関サブクエリによる累計計算
    Django ORMでも可能だが、ウィンドウ関数が推奨
    """
    from django.db.models import OuterRef, Subquery

    return SalesIcecream.objects.annotate(
        cumlative_amt=Subquery(
            SalesIcecream.objects.filter(
                shop_id=OuterRef("shop_id"), sale_date__lte=OuterRef("sale_date")
            )
            .aggregate(total=Sum("sales_amt"))
            .values("total")
        )
    ).values("shop_id", "sale_date", "sales_amt", "cumlative_amt")


# ●ロバートの解：ウィンドウ関数
def cumulative_with_window():
    """
    ウィンドウ関数による累計計算
    Django 2.0以降でサポート
    """
    return SalesIcecream.objects.annotate(
        cumlative_amt=Window(
            expression=Sum("sales_amt"),
            partition_by=[F("shop_id")],
            order_by=F("sale_date").asc(),
        )
    ).values("shop_id", "sale_date", "sales_amt", "cumlative_amt")


# ●ウィンドウ関数で移動平均を求める
def moving_average_window():
    """
    ウィンドウ関数による移動平均
    Django 2.0以降でサポート
    """
    return SalesIcecream.objects.annotate(
        moving_avg=Round(
            Window(
                expression=Avg("sales_amt"),
                partition_by=[F("shop_id")],
                order_by=F("sale_date").asc(),
                frame=RowRange(start=-2, end=0),  # 2 PRECEDING AND CURRENT ROW
            ),
            0,
        )
    ).values("shop_id", "sale_date", "sales_amt", "moving_avg")


# ●平均を求めるクエリ
def average_weight():
    return Weights.objects.aggregate(avg_weight=Round(Avg("weight"), 0))


# ●クラスの平均と学生の体重を比較する
def students_above_average():
    avg_weight = Weights.objects.aggregate(avg=Avg("weight"))["avg"]
    return Weights.objects.filter(weight__gt=avg_weight)


# ●正しい解：ウィンドウ関数を使う
def students_above_average_window():
    """
    ウィンドウ関数による平均との比較
    """
    queryset = (
        Weights.objects.annotate(avg_weight=Round(Window(expression=Avg("weight")), 0))
        .filter(weight__gt=F("avg_weight"))
        .values("student_id", "weight", "avg_weight")
    )

    return queryset


# ===== 使用例 =====
if __name__ == "__main__":
    # 各クエリの実行例
    print("CASE式による都市名取得:")
    print(list(warehouse_city_case()))

    print("\nピボットテーブル（集約）:")
    print(case_pivot_solution())

    print("\nUNIONによる価格取得:")
    print(list(union_solution()))

    print("\nウィンドウ関数による累計:")
    print(list(cumulative_with_window()))

    print("\n平均を上回る学生:")
    print(list(students_above_average_window()))
