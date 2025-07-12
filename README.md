# SQLアンチパターン教育サンプルコード - Django ORM実装版

このプロジェクトは、SQLアンチパターンの教育を目的としたサンプルコード集です。元のSQLファイル（日本語名）と、それらをDjango 4.2 ORMで実装したPythonコードで構成されています。

## 🎯 プロジェクトの目的

- SQLアンチパターンの理解と学習
- Django ORMによる適切な実装方法の習得
- SQL vs Django ORMの比較学習
- データベース設計のベストプラクティス習得

## 📚 カバーするアンチパターン

1. **サブクエリ・パラノイア** - 過度なサブクエリ使用
2. **冗長性症候群** - 重複コードによる非効率
3. **ループ依存症** - N+1問題とループ処理
4. **スーパーソルジャー病** - 過度に複雑な単一クエリ
5. **時代錯誤症候群** - 古い記法の使用
6. **ロックイン病** - ベンダー固有機能への依存
7. **集合指向アレルギー** - 行指向思考の問題

## 🚀 クイックスタート

### 前提条件
- Python 3.13+
- uv（パッケージマネージャー）
- Docker & Docker Compose

### セットアップ

```bash
# 依存関係のインストール
uv sync

# データベース起動
docker compose up -d

# サンプル実行
uv run python src/django_orm_implementation.py
```

## 📖 使用方法

詳細な開発方法、アーキテクチャ、コマンドについては **[CLAUDE.md](./CLAUDE.md)** を参照してください。

### 主要コマンド

```bash
# コードリンティング
uv run ruff check src/

# テスト実行  
uv run pytest

# データベース接続
docker compose exec -e MYSQL_PWD=root db mysql -u root sample
```

## 🏗️ プロジェクト構成

```
├── src/                    # Django ORM実装
│   ├── 01_subquery_paranoia.py
│   ├── 02_redundancy_syndrome.py
│   └── ...
├── *.sql                   # 元のSQLアンチパターン例
├── compose.yml             # MySQL Docker設定
└── CLAUDE.md              # 詳細な開発ガイド
```

## 🛠️ 技術スタック

- **言語**: Python 3.13
- **フレームワーク**: Django 4.2 ORM
- **データベース**: MySQL 8.4 (推奨) / SQLite3 3.43.2+ (開発用)
- **パッケージ管理**: uv
- **リンター**: ruff
- **テスト**: pytest

## 📋 対応状況

✅ **Django ORMで対応済み**:
- CASE式、ウィンドウ関数、サブクエリ、集約関数、UNION

❌ **対応困難な機能**:
- PostgreSQL配列型、DBMS固有関数、複雑なウィンドウ関数フレーム

### データベース互換性

| 機能 | PostgreSQL | MySQL | SQLite3 (3.43.2+) |
|------|------------|-------|--------------------|
| ウィンドウ関数 | ✅ 完全 | ✅ 完全 | ✅ 完全 (パフォーマンス注意) |
| JSON操作 | ✅ 完全 | ✅ 完全 | ✅ 基本サポート |
| ArrayField | ✅ 完全 | ❌ 非サポート | ❌ 非サポート |

> **注意**: 各実装ファイルにはSQLite3 3.43.2以降での制約情報をdocstringに記載しています。

## 📝 ライセンス

このプロジェクトは教育目的で作成されています。

## 🤝 コントリビューション

プルリクエストやイシューの報告を歓迎します。詳細は [CLAUDE.md](./CLAUDE.md) の開発ガイドを参照してください。