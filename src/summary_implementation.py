# Django 4.2 ORM - SQL Anti-patterns Implementation Summary
# 07_グレーノウハウ.sql, 09_リレーショナル原理主義.sql, 10_更新時合弁症.sql の要約実装

from django.db import models
from django.db.models import (
    Case, When, Value, Count, Min, F, CharField, Window, Lag, Lead
)

# ===== 07_グレーノウハウ (Gray Know-how) モデル =====

class OTLT(models.Model):
    """
    汎用ルックアップテーブル（アンチパターン）
    """
    code_type = models.CharField(max_length=16)
    code = models.CharField(max_length=16) 
    code_description = models.CharField(max_length=32)
    
    class Meta:
        db_table = 'otlt'

class Customers(models.Model):
    """
    統合顧客テーブル vs 分割設計
    """
    customer_id = models.CharField(max_length=8, primary_key=True)
    customer_name = models.CharField(max_length=32)
    customer_type = models.CharField(max_length=16)  # 'General' or 'Premier'
    discount_rate = models.DecimalField(max_digits=3, decimal_places=2, null=True)
    
    class Meta:
        db_table = 'customers'

class OrgChart(models.Model):
    """
    組織図（隣接リストモデル）
    """
    emp = models.CharField(max_length=16, primary_key=True)
    boss = models.CharField(max_length=16, null=True, blank=True)
    role = models.CharField(max_length=16)
    
    class Meta:
        db_table = 'orgchart'

# ===== 09_リレーショナル原理主義 モデル =====

class ServerLoad(models.Model):
    """
    サーバ負荷テーブル
    """
    server_id = models.CharField(max_length=8)
    time = models.DateTimeField()
    server_load = models.IntegerField()
    
    class Meta:
        db_table = 'serverload'
        unique_together = ['server_id', 'time']

class StockPrice(models.Model):
    """
    株価テーブル
    """
    company = models.CharField(max_length=8)
    time = models.DateTimeField()
    price = models.IntegerField()
    
    class Meta:
        db_table = 'stockprice'
        unique_together = ['company', 'time']

class Seats(models.Model):
    """
    座席管理テーブル
    """
    seat = models.CharField(max_length=3, primary_key=True)
    status = models.CharField(max_length=8)  # 'occupied', 'vacant'
    line_id = models.IntegerField()
    
    class Meta:
        db_table = 'seats'

# ===== 10_更新時合弁症 モデル =====

class OrderDetails(models.Model):
    """
    注文明細テーブル
    """
    order_id = models.CharField(max_length=8)
    order_detail_id = models.CharField(max_length=8)
    item_id = models.CharField(max_length=8)
    price = models.IntegerField()
    quantity = models.IntegerField()
    
    class Meta:
        db_table = 'orderdetails'
        unique_together = ['order_id', 'order_detail_id']

class Hotel(models.Model):
    """
    ホテル客室テーブル
    """
    floor_nbr = models.IntegerField()
    room_nbr = models.IntegerField()
    room_type = models.CharField(max_length=16, null=True, blank=True)
    
    class Meta:
        db_table = 'hotel'
        unique_together = ['floor_nbr', 'room_nbr']

class Salary(models.Model):
    """
    給与テーブル
    """
    emp_name = models.CharField(max_length=16, primary_key=True)
    salary = models.IntegerField()
    
    class Meta:
        db_table = 'salary'

# ===== 主要クエリ実装 =====

# ●07_グレーノウハウ - 汎用テーブルのアンチパターン
def otlt_antipattern():
    """
    汎用ルックアップテーブルの問題点
    Django ORMでは型安全性が失われる
    """
    # アンチパターン：すべてを文字列で格納
    return OTLT.objects.filter(code_type='GENDER').values('code', 'code_description')

def normalized_approach():
    """
    正規化されたテーブル設計（推奨）
    """
    # 推奨：専用のGenderChoicesを使用
    GENDER_CHOICES = [
        ('M', 'Male'),
        ('F', 'Female'),
        ('O', 'Other'),
    ]
    # Django modelsでChoicesFieldとして定義するのが適切

# ●階層データの処理
def hierarchy_adjacency_list():
    """
    隣接リストモデルによる階層検索
    """
    # Django ORMでは再帰クエリの制限あり
    # 代替案：django-mpttの使用を推奨
    return OrgChart.objects.filter(boss='社長').values('emp', 'role')

# ●09_リレーショナル原理主義 - ウィンドウ関数
def server_load_analysis():
    """
    サーバ負荷の前値比較（Lag関数）
    """
    return ServerLoad.objects.annotate(
        prev_load=Window(
            expression=Lag('server_load'),
            partition_by=[F('server_id')],
            order_by=F('time').asc()
        ),
        load_diff=F('server_load') - F('prev_load')
    ).values('server_id', 'time', 'server_load', 'prev_load', 'load_diff')

def stock_price_trends():
    """
    株価トレンド分析（Lead/Lag関数）
    """
    return StockPrice.objects.annotate(
        prev_price=Window(
            expression=Lag('price'),
            partition_by=[F('company')],
            order_by=F('time').asc()
        ),
        next_price=Window(
            expression=Lead('price'),
            partition_by=[F('company')],
            order_by=F('time').asc()
        )
    ).annotate(
        trend=Case(
            When(prev_price__isnull=True, then=Value('初回')),
            When(price__gt=F('prev_price'), then=Value('上昇')),
            When(price__lt=F('prev_price'), then=Value('下降')),
            default=Value('横ばい'),
            output_field=CharField()
        )
    ).values('company', 'time', 'price', 'prev_price', 'next_price', 'trend')

# ●座席の連続空席検索
def consecutive_vacant_seats():
    """
    連続する空席の検索
    Django ORMでは複雑な窓関数の制限あり
    """
    from django.db import connection
    
    # 複雑なウィンドウ関数はraw SQLで実装
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT seat, status,
                   LAG(status) OVER (ORDER BY seat) as prev_status,
                   LEAD(status) OVER (ORDER BY seat) as next_status
            FROM seats 
            WHERE line_id = 1
            ORDER BY seat
        """)
        return cursor.fetchall()

# ●10_更新時合弁症 - バルク更新
def bulk_price_update():
    """
    価格の一括更新（推奨）
    """
    # Django ORMのbulk_updateを使用
    orders = list(OrderDetails.objects.filter(item_id='ITEM001'))
    for order in orders:
        order.price = order.price * 1.1  # 10%値上げ
    
    OrderDetails.objects.bulk_update(orders, ['price'])
    return len(orders)

def conditional_salary_update():
    """
    条件付き給与更新
    """
    return Salary.objects.filter(
        salary__lt=300000
    ).update(
        salary=F('salary') * 1.1  # 10%昇給
    )

# ●重複データ削除
def remove_duplicate_records():
    """
    重複レコードの削除
    Django ORMでROW_NUMBER()の代替
    """
    
    # 最小IDを持つレコード以外を削除
    duplicates = Hotel.objects.values('floor_nbr', 'room_nbr').annotate(
        min_id=Min('id'),
        count=Count('id')
    ).filter(count__gt=1)
    
    for dup in duplicates:
        Hotel.objects.filter(
            floor_nbr=dup['floor_nbr'],
            room_nbr=dup['room_nbr']
        ).exclude(
            id=dup['min_id']
        ).delete()

# ===== Django ORM制限と対策 =====

def django_orm_limitations():
    """
    Django ORMの制限事項と対策
    """
    return {
        'unsupported_features': {
            'recursive_cte': 'WITH RECURSIVE - django-mptt等のライブラリで代替',
            'complex_window_frames': 'ROWS BETWEEN等 - raw SQLで実装',
            'pivot_operations': 'PIVOT/UNPIVOT - Case/When式で代替',
            'merge_statement': 'MERGE - bulk_create/bulk_update で代替',
            'advanced_json': 'JSON_OBJECT等 - Python辞書操作で代替'
        },
        'workarounds': {
            'hierarchy': 'django-mptt (Modified Preorder Tree Traversal)',
            'full_text_search': 'django.contrib.postgres.search',
            'complex_aggregation': 'raw SQL + cursor.fetchall()',
            'bulk_operations': 'bulk_create/bulk_update/bulk_delete',
            'custom_functions': 'database functions registration'
        },
        'best_practices': [
            'ORM優先、必要に応じてraw SQL',
            'select_related/prefetch_relatedでN+1回避', 
            'データベース固有機能は抽象化',
            'パフォーマンステストの実施',
            'インデックス設計の最適化'
        ]
    }

# ===== 使用例 =====
if __name__ == '__main__':
    print("汎用ルックアップテーブル（アンチパターン）:")
    print(list(otlt_antipattern()))
    
    print("\n階層データ（隣接リスト）:")
    print(list(hierarchy_adjacency_list()))
    
    print("\nサーバ負荷分析:")
    print(list(server_load_analysis())[:3])
    
    print("\n株価トレンド分析:")
    print(list(stock_price_trends())[:3])
    
    print("\nDjango ORM制限事項:")
    limitations = django_orm_limitations()
    print(f"未サポート機能: {list(limitations['unsupported_features'].keys())}")
    print(f"対策: {list(limitations['workarounds'].keys())}")
    
    print("\nベストプラクティス:")
    for practice in limitations['best_practices']:
        print(f"- {practice}")