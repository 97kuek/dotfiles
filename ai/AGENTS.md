# 共通の指示

Claude CodeとCodexが、すべてのプロジェクトで最初に読む指示。
実体は`~/dotfiles/ai/AGENTS.md`で、`~/.claude/CLAUDE.md`と`~/.codex/AGENTS.md`はそこへのリンク。
プロジェクトごとの指示は、各リポジトリの`CLAUDE.md`や`AGENTS.md`に書く。

## やりとり

- 日本語で答える。コード、コマンド、ファイル名、エラーメッセージは原文のまま書く
- 分からないことや、決めるべきことがあるときは推測で進めず、選択肢と推奨を示して聞く

## 環境

- macOS（Apple Silicon）、シェルはzsh
- パッケージはHomebrewで入れる
- Pythonはuvでプロジェクトごとの仮想環境を作る。バージョンはpyenvで切り替える
- NodeのバージョンはVoltaで切り替える

## 設定ファイル

- `~/.zshrc`、`~/.gitconfig`、`~/.claude/CLAUDE.md`などは`~/dotfiles`へのシンボリックリンク
- Claude Codeの`settings.json`は、`~/dotfiles/ai/claude/settings.json`の内容を`~/dotfiles/ai/install.sh`で書き込んだもの
- 設定を変えるときは、リンク先ではなく`~/dotfiles`側のファイルを編集する
- 秘密情報や端末固有の設定は`~/.config/zsh/local/*.zsh`に置き、Gitに入れない

## Git

- コミットとpushは、頼まれたときだけ行う
- コミットメッセージやブランチ名は、そのリポジトリの既存の書き方に合わせる

## 秘密情報

- APIキー、トークン、鍵、`.env`の中身を、コード、コミット、ログ、返答に含めない
