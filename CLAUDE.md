# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

このプロジェクトは、SQLアンチパターンの教育サンプルコードです。元のSQLファイル（日本語名）と、それらをDjango 4.2 ORMで実装したPythonコードで構成されています。

## 開発環境

### uvによる依存関係管理
```bash
# 依存関係のインストール
uv sync

# Pythonスクリプト実行
uv run python src/django_orm_implementation.py

# コードリンティング
uv run ruff check src/

# 自動修正
uv run ruff check --fix src/

# テスト実行
uv run pytest
```

### MySQL データベース
```bash
# データベース起動
docker compose up -d

# MySQL接続（rootユーザー）
docker compose exec -e MYSQL_PWD=root db mysql -u root sample

# データベース停止
docker compose down
```

データベース接続情報：
- Host: localhost:3306
- Database: sample
- User: user / Password: password
- Root Password: root

## アーキテクチャ

### SQLアンチパターンの分類
プロジェクトは12のSQLアンチパターンをカバーし、各パターンについて元のSQL（問題のあるパターン）とDjango ORMでの改善実装を提供：

0. **序章** (`00_introduction.py`) - CASEとWindow関数
1. **サブクエリ・パラノイア** (`01_subquery_paranoia.py`) - 過度なサブクエリ使用
2. **冗長性症候群** (`02_redundancy_syndrome.py`) - 重複コードによる非効率
3. **ループ依存症** (`03_loop_dependency.py`) - N+1問題とループ処理
4. **スーパーソルジャー病** (`04_super_soldier_syndrome.py`) - 過度に複雑な単一クエリ
5. **時代錯誤症候群** (`05_anachronism_syndrome.py`) - 古い記法の使用
6. **ロックイン病** (`06_lock_in_syndrome.py`) - ベンダー固有機能への依存
7. **集合指向アレルギー** (`08_set_oriented_allergy.py`) - 行指向思考の問題
8. **SQL Anti-patterns** (`summary_implementation.py`) - 以下の要約実装
  * 07_グレーノウハウ
  * 09_リレーショナル原理主義
  * 10_更新時合弁症

### Django ORM実装パターン

各ファイルは以下の構造で統一：
- **モデル定義**: SQLテーブルに対応するDjangoモデル
- **アンチパターン実装**: 元のSQLを忠実に再現（問題を示すため）
- **推奨実装**: Django ORMのベストプラクティス
- **制限事項**: Django ORMで対応困難な機能の説明

### Django ORM制限への対策

- **未サポート機能**: PostgreSQL配列型、再帰CTE、PIVOT構文
- **代替実装**: 正規化テーブル、raw SQL、サードパーティライブラリ
- **パフォーマンス**: select_related/prefetch_related、bulk操作の活用

## Django ORM対応状況

✅ **対応済み機能**:
- CASE式 → `Case/When`
- ウィンドウ関数 → `Window`クラス
- サブクエリ → `Subquery/OuterRef`
- 集約関数 → `Sum/Count/Avg`等
- UNION → `.union()`

❌ **対応困難な機能**:
- PostgreSQL配列型・JSON操作
- DBMS固有関数
- 複雑なウィンドウ関数フレーム
- 再帰共通表式

## テーブル設計

主要なテーブル群（各アンチパターンで使用）：
- `Warehouse/City` - 基本的なマスタテーブル
- `ItemPrice/SalesIcecream` - 時系列データ
- `Receipts/Orders` - トランザクションデータ
- `Suppliers/Manufacturers` - 複雑な関係構造

各SQLファイルには対応するCREATE TABLEとサンプルデータが含まれている。