# 自作スキル

ここに置いたスキルを`install.sh`が`~/.claude/skills/`と`~/.codex/skills/`の両方へ
シンボリックリンクする。実体はこのリポジトリの1箇所だけなので、
ここを直せばClaudeとCodexの両方に反映される。

外部のスキルはここに置かない。プラグインとして`../plugins.txt`に宣言する。

## 追加する

スキル1つにつきディレクトリを1つ作り、`SKILL.md`を置く。
ディレクトリ名と`name`は揃える。

```sh
mkdir -p ai/skills/my-skill
```

```markdown
---
name: my-skill
description: いつ使うスキルなのかを1行で書く。CLIはこの説明を読んで使うかどうかを決める。
---

Claudeに踏ませたい手順をそのまま書く。
```

`./install.sh`を実行するとリンクされ、次に起動したセッションから使えるようになる。

## 注意

- `description`はCLIが常時読み込む。長いと毎回のトークンを食うので1行に収める。
- `SKILL.md`の書式はClaudeとCodexで共通だが、`allowed-tools`のようなClaude固有の
  項目はCodex側では無視される。両方で使うスキルは共通の項目だけで書く。
- リンク先に同じ名前の実体があると、上書きせずに警告を出して飛ばす。
