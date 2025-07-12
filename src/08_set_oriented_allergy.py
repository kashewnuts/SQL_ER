# Django 4.2 ORM implementation of 08_集合指向アレルギー.sql
# 集合指向でない処理のアンチパターンをDjango ORMで実装

from django.db import models
from django.db.models import (
    Case,
    When,
    Value,
    Count,
    F,
    Q,
    IntegerField,
    CharField,
    Window,
    Exists,
    OuterRef,
)

# ===== モデル定義 =====


class Addresses(models.Model):
    name = models.CharField(max_length=16)
    family_id = models.CharField(max_length=2)
    address = models.CharField(max_length=32)

    class Meta:
        db_table = "addresses"


class Departments(models.Model):
    department = models.CharField(max_length=16)
    division = models.CharField(max_length=16)
    check_flag = models.CharField(max_length=1, blank=True, null=True)
    check_date = models.DateField(blank=True, null=True)

    class Meta:
        db_table = "departments"


# ===== クエリ実装 =====


# ●同じ住所に住む人を見つける（集合指向でない例）
def find_same_address_non_set():
    """
    集合指向でないアプローチ（アンチパターン）
    ループ的な思考でN+1問題を引き起こす
    """
    # これは効率が悪い：各住所に対して個別にクエリ
    results = []
    all_addresses = Addresses.objects.values("address").distinct()

    for addr_item in all_addresses:
        address = addr_item["address"]
        people = list(
            Addresses.objects.filter(address=address).values("name", "family_id")
        )
        if len(people) > 1:
            results.extend(people)

    return results


# ●同じ住所に住む人を見つける（集合指向の解）
def find_same_address_set_oriented():
    """
    集合指向アプローチ（推奨）
    """
    return (
        Addresses.objects.values("address")
        .annotate(address_count=Count("address"))
        .filter(address_count__gt=1)
        .values("address", "address_count")
    )


# ●同じ住所の詳細リスト（JOIN使用）
def same_address_details():
    """
    自己結合による同じ住所の人々
    """
    return Addresses.objects.filter(
        address__in=Addresses.objects.values("address")
        .annotate(cnt=Count("address"))
        .filter(cnt__gt=1)
        .values("address")
    ).order_by("address", "name")


# ●家族IDでグループ化した住所一覧
def family_address_grouping():
    """
    家族単位での住所集約
    """
    return (
        Addresses.objects.values("family_id")
        .annotate(
            family_size=Count("name"),
            addresses=Count("address", distinct=True),
            address_list=models.functions.Concat("address", output_field=CharField()),
        )
        .filter(family_size__gt=1)
    )


# ●部署の作業完了チェック（非集合指向）
def department_completion_non_set():
    """
    部署ごとの完了チェック（非効率な方法）
    """
    results = []
    departments = Departments.objects.values("department", "division").distinct()

    for dept in departments:
        total_count = Departments.objects.filter(
            department=dept["department"], division=dept["division"]
        ).count()

        completed_count = Departments.objects.filter(
            department=dept["department"], division=dept["division"], check_flag="Y"
        ).count()

        results.append(
            {
                "department": dept["department"],
                "division": dept["division"],
                "total": total_count,
                "completed": completed_count,
                "is_complete": total_count == completed_count,
            }
        )

    return results


# ●部署の作業完了チェック（集合指向）
def department_completion_set_oriented():
    """
    集合指向による部署完了チェック（推奨）
    """
    return (
        Departments.objects.values("department", "division")
        .annotate(
            total_tasks=Count("*"),
            completed_tasks=Count(
                Case(When(check_flag="Y", then=1), output_field=IntegerField())
            ),
            completion_rate=F("completed_tasks") * 100.0 / F("total_tasks"),
            is_complete=Case(
                When(total_tasks=F("completed_tasks"), then=Value(True)),
                default=Value(False),
                output_field=models.BooleanField(),
            ),
        )
        .order_by("department", "division")
    )


# ●HAVING句を使った条件集約
def having_clause_example():
    """
    HAVING句による集約後のフィルタリング
    """
    return (
        Departments.objects.values("department")
        .annotate(
            division_count=Count("division"),
            completed_divisions=Count(
                Case(When(check_flag="Y", then="division"), output_field=IntegerField())
            ),
        )
        .filter(
            division_count__gt=2,  # HAVING相当
            completed_divisions__gte=1,
        )
    )


# ●ウィンドウ関数による集合処理
def window_function_set_processing():
    """
    ウィンドウ関数による高度な集合処理

    SQLite3制約 (3.43.2+前提):
    - DenseRank() ウィンドウ関数はSQLite3 3.43.2以降で完全サポート
    - 複雑なpartition_byとorder_byの組み合わせではパフォーマンスが
      PostgreSQL/MySQLより劣る場合があります
    """
    return Addresses.objects.annotate(
        family_size=Window(expression=Count("name"), partition_by=[F("family_id")]),
        address_rank=Window(
            expression=models.functions.DenseRank(),
            partition_by=[F("family_id")],
            order_by=F("address"),
        ),
    ).values("name", "family_id", "address", "family_size", "address_rank")


# ●EXISTS述語による相関
def exists_predicate_example():
    """
    EXISTS述語による存在チェック
    """
    # 同じ住所に他の人がいる人を検索
    return Addresses.objects.filter(
        Exists(
            Addresses.objects.filter(address=OuterRef("address")).exclude(
                name=OuterRef("name")
            )
        )
    ).values("name", "address")


# ●NOT EXISTS述語
def not_exists_predicate_example():
    """
    NOT EXISTS述語による非存在チェック
    """
    # 一人だけしか住んでいない住所の人
    return Addresses.objects.filter(
        ~Exists(
            Addresses.objects.filter(address=OuterRef("address")).exclude(
                name=OuterRef("name")
            )
        )
    ).values("name", "address")


# ●集合の差演算
def set_difference_operation():
    """
    集合の差演算（全部署 - 完了部署）
    """
    # 未完了の部署を取得
    all_departments = Departments.objects.values("department", "division").distinct()
    completed_departments = (
        Departments.objects.values("department", "division")
        .annotate(total=Count("*"), completed=Count(Case(When(check_flag="Y", then=1))))
        .filter(total=F("completed"))
        .values("department", "division")
    )

    # 差集合（未完了部署）
    completed_set = set((d["department"], d["division"]) for d in completed_departments)

    incomplete_departments = [
        d
        for d in all_departments
        if (d["department"], d["division"]) not in completed_set
    ]

    return incomplete_departments


# ●集合の積演算（AND条件）
def set_intersection_operation():
    """
    集合の積演算（条件の組み合わせ）
    """
    # 特定の条件を満たす部署の積集合
    condition1 = Q(check_flag="Y")
    condition2 = Q(check_date__isnull=False)

    return Departments.objects.filter(condition1 & condition2).values(
        "department", "division"
    )


# ●集合の和演算（OR条件）
def set_union_operation():
    """
    集合の和演算（複数条件のいずれか）
    """
    # いずれかの条件を満たす部署
    condition1 = Q(check_flag="Y")
    condition2 = Q(check_date__isnull=False)

    return (
        Departments.objects.filter(condition1 | condition2)
        .values("department", "division")
        .distinct()
    )


# ●集合指向思考のベストプラクティス
def set_oriented_best_practices():
    """
    集合指向プログラミングのベストプラクティス
    """
    return {
        "problem": "集合指向アレルギー - 行単位の処理への固執",
        "symptoms": [
            "ループによる1行ずつ処理",
            "N+1クエリ問題",
            "条件分岐の多用",
            "非効率な重複処理",
        ],
        "solutions": [
            "GROUP BY / HAVING の活用",
            "ウィンドウ関数の使用",
            "EXISTS/NOT EXISTS述語",
            "集合演算の活用",
        ],
        "django_best_practices": [
            "annotate/aggregate の積極活用",
            "select_related/prefetch_related でN+1解決",
            "Case/When による条件集約",
            "F式による効率的な比較",
        ],
        "performance_tips": [
            "クエリ数の最小化",
            "データベースレベルでの集約",
            "インデックス設計の最適化",
            "メモリ使用量の削減",
        ],
    }


# ===== 使用例 =====
if __name__ == "__main__":
    print("【アンチパターン】非集合指向の住所検索:")
    print(find_same_address_non_set()[:5])

    print("\n【推奨】集合指向の住所検索:")
    print(list(find_same_address_set_oriented()))

    print("\n【アンチパターン】非集合指向の部署完了チェック:")
    print(department_completion_non_set()[:3])

    print("\n【推奨】集合指向の部署完了チェック:")
    print(list(department_completion_set_oriented())[:3])

    print("\nウィンドウ関数による集合処理:")
    print(list(window_function_set_processing())[:5])

    print("\nEXISTS述語の例:")
    print(list(exists_predicate_example())[:5])

    print("\n集合指向ベストプラクティス:")
    print(set_oriented_best_practices())
