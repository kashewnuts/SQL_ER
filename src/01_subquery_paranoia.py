# Django 4.2 ORM implementation of 01_サブクエリ・パラノイア.sql
# サブクエリのアンチパターンをDjango ORMで実装

from django.db import models
from django.db.models import F, Min, Window, OuterRef, Subquery
from django.db.models.functions import FirstValue

# ===== モデル定義 =====


class Receipts(models.Model):
    customer_id = models.CharField(max_length=4)
    seq = models.IntegerField()
    price = models.IntegerField()

    class Meta:
        db_table = "receipts"
        unique_together = ["customer_id", "seq"]


# ===== クエリ実装 =====


# ●患者1の解：サブクエリを用いて最小の枝番を取得する
def patient_subquery_solution():
    """
    相関サブクエリによる最小枝番の取得
    """
    # 最小枝番を取得するサブクエリ
    min_seq_subquery = Receipts.objects.filter(
        customer_id=OuterRef("customer_id")
    ).aggregate(min_seq=Min("seq"))

    return Receipts.objects.filter(
        seq__in=Subquery(
            Receipts.objects.filter(customer_id=OuterRef("customer_id")).aggregate(
                min_seq=Min("seq")
            )["min_seq"]
        )
    ).values("customer_id", "seq", "price")


# より直接的なサブクエリ実装
def patient_subquery_with_join():
    """
    JOINを使った最小枝番の取得（元SQLに忠実）
    """
    # サブクエリで最小枝番を取得
    min_seqs = Receipts.objects.values("customer_id").annotate(min_seq=Min("seq"))

    # メインクエリでJOIN
    return Receipts.objects.filter(
        customer_id__in=[item["customer_id"] for item in min_seqs],
        seq__in=[item["min_seq"] for item in min_seqs],
    ).values("customer_id", "seq", "price")


# ●サブクエリ内部のSELECT文の結果：最小の枝番を取得する
def get_min_seq_per_customer():
    """
    顧客ごとの最小枝番を取得
    """
    return Receipts.objects.values("customer_id").annotate(min_seq=Min("seq"))


# ●ロバートの解：FIRST_VALUE関数
def roberts_window_solution():
    """
    ウィンドウ関数を使った解決法
    Django 2.0以降でサポート
    """
    return (
        Receipts.objects.annotate(
            min_seq=Window(
                expression=FirstValue("seq"),
                partition_by=[F("customer_id")],
                order_by=F("seq").asc(),
            )
        )
        .filter(seq=F("min_seq"))
        .values("customer_id", "seq", "price")
    )


# ●ウィンドウ関数単独で実行してみる
def window_function_demo():
    """
    ウィンドウ関数の動作確認
    """
    return Receipts.objects.annotate(
        min_seq=Window(
            expression=FirstValue("seq"),
            partition_by=[F("customer_id")],
            order_by=F("seq").asc(),
        )
    ).values("customer_id", "seq", "price", "min_seq")


# ===== 使用例 =====
if __name__ == "__main__":
    print("患者のサブクエリ解法:")
    print(list(patient_subquery_solution()))

    print("\n最小枝番一覧:")
    print(list(get_min_seq_per_customer()))

    print("\nロバートのウィンドウ関数解法:")
    print(list(roberts_window_solution()))

    print("\nウィンドウ関数デモ:")
    print(list(window_function_demo()))
