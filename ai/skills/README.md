# 自作スキル

ここに置いたスキルを`ai/install.sh`が`~/.agents/skills/`へシンボリックリンクする。
Codexはそこを直接読み、Claude Codeには`~/.claude/skills/`へもう一段リンクする。
実体はこのリポジトリの1箇所だけなので、ここを直せばClaudeとCodexの両方に反映される。

外部のスキルはここに置かない。1つだけ入れたいものは`../skills.txt`、
まとめて配られているものは`../plugins.txt`に宣言する。

## 追加する

スキル1つにつきディレクトリを1つ作り、`SKILL.md`を置く。
ディレクトリ名と`name`は揃える。`synced`という名前はClaude Codeが予約しているので使わない。

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

`./ai/install.sh`を実行するとリンクされる。Claude Codeは実行中のセッションにも反映し、
Codexは次に起動したセッションから使える。`docs/skills.md`の一覧にも追記する。

## 注意

- `description`はCLIが常時読み込む。長いと毎回のトークンを食うので1行に収める。
- `SKILL.md`の書式はClaudeとCodexで共通だが、`allowed-tools`のようなClaude固有の
  項目はCodex側では無視される。両方で使うスキルは共通の項目だけで書く。
- リンク先に同じ名前の実体があると、上書きせずに警告を出して飛ばす。
