# TrackFit 設計ドキュメント

このディレクトリには、TrackFitプロジェクトの設計ドキュメントを格納しています。

## フォルダ構成

| フォルダ | 説明 |
|----------|------|
| [01_キャッチアップ](./01_キャッチアップ/) | ドメイン知識など、新規参画者が最初に把握すべき前提情報 |
| [02_環境構築](./02_環境構築/) | 開発環境のセットアップ手順 |
| [03_開発規約](./03_開発規約/) | コードスタイル、Git運用などの開発ルール |
| [04_画面設計書](./04_画面設計書/) | 画面遷移、イベント定義、バリデーションロジック |
| [05_データモデル](./05_データモデル/) | SwiftDataモデル定義、ER図 |
| [06_API設計書](./06_API設計書/) | Google Calendar API連携仕様 |

## ドキュメント作成方針

本ドキュメントは [Markdown設計ドキュメント規約](https://github.com/future-architect/arch-guidelines/blob/main/documents/forMarkdown/markdown_design_document.md) を参考に作成されています。

### 基本方針

- **Git管理**: 設計ドキュメントをコードと同一リポジトリで管理し、バージョン管理を行う
- **Markdown形式**: テキストベースで差分管理しやすい形式を採用
- **図表**: Mermaid.jsまたはPlantUMLで作成し、Git差分を確認しやすくする

## 関連リンク

- [プロジェクトREADME](../README.md)
- [Issue #122: ドキュメントフォルダ構造の作成](https://github.com/garyuu09/track-fit/issues/122)
