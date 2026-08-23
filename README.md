# dotfiles

> macOSの開発環境を再現するための個人用dotfiles

- Zsh、Git、Starship、Ghostty、SSHの設定をGNU Stowで配置
- CLIツールとGUIアプリを`Brewfile`からインストール
- GitHubとAIツール（Claude Code / Codex）のアカウントを個人用と仕事用で切り替え
- 既存の設定ファイルは自動で削除・上書きしない

## セットアップ

1. Command Line Toolsをインストールする

```sh
xcode-select --install
```

- 表示されたダイアログでインストールを完了してから、次へ進む。

2. Homebrewをインストールする

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  eval "$(/usr/local/bin/brew shellenv)"
fi
```

3. このリポジトリをcloneしてセットアップする

```sh
git clone https://github.com/97kuek/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

- 既存ファイルと競合する場合は、リンクを作る前に競合したファイルの一覧が表示される。
  表示されたファイルを退避してから、もう一度実行する。

4. Gitの名前とメールアドレスを設定する

```sh
git config --file ~/.gitconfig.local user.name "Your Name"
git config --file ~/.gitconfig.local user.email "you@example.com"
```

- `Your Name`と`you@example.com`は自分の情報に置き換える。
- 仕事用のアカウントも使う場合は「[SSHとGitのアカウント切り替え](#sshとgitのアカウント切り替え)」へ進む。

5. Zshを起動する

```sh
exec zsh
```

## 構成

Stowのパッケージごとにディレクトリを分けている。`install.sh`が`~`へリンクする。

| パッケージ | 変更するファイル | リンク先 |
| --- | --- | --- |
| `zsh` | `zsh/.zshrc`, `zsh/.config/zsh/config.zsh` | `~/.zshrc`, `~/.config/zsh/config.zsh` |
| `git` | `git/.gitconfig`, `git/.config/git/ignore` | `~/.gitconfig`, `~/.config/git/ignore` |
| `starship` | `starship/.config/starship.toml` | `~/.config/starship.toml` |
| `ghostty` | `ghostty/.config/ghostty/config.ghostty` | `~/.config/ghostty/config.ghostty` |
| `ssh` | `ssh/.ssh/config` | `~/.ssh/config` |

インストールするツール・アプリは`Brewfile`で管理する。

### Gitで管理しないファイル

秘密情報と端末固有の設定は、リポジトリの外に置いて自動で読み込む。

| ファイル | 用途 |
| --- | --- |
| `~/.config/zsh/local/*.zsh` | Zshの秘密情報・端末固有の設定 |
| `~/.gitconfig.local` | Gitの個人アカウント情報 |
| `~/.gitconfig.work` | Gitの仕事アカウント情報 |
| `~/.ssh/config.d/*.conf` | 公開したくないSSHホスト |
| `~/.ssh/id_*` | SSHの鍵 |

## SSHとGitのアカウント切り替え

`ssh/.ssh/config`にアカウントごとのホストを定義してある。鍵そのものはリポジトリで管理せず、
ローカルにだけ置く。

| 用途 | cloneに使うURL | 使われる鍵 |
| --- | --- | --- |
| 個人 | `git@github.com:user/repo.git` | `~/.ssh/id_ed25519` |
| 仕事 | `github-work:org/repo.git` | `~/.ssh/id_ed25519_work` |

どちらのホストも`IdentitiesOnly yes`を指定して、鍵を1本に固定している。`Host *`側に
`IdentityFile`を書いていないのは、`IdentityFile`が一致するブロック全部から積み上がる仕様のため。
共通の鍵をそこに置くと、仕事用の接続に個人用の鍵が混ざる。

仕事用の鍵を作ってGitHubに登録する。

```sh
ssh-keygen -t ed25519 -C "you@company.example" -f ~/.ssh/id_ed25519_work
ssh-add --apple-use-keychain ~/.ssh/id_ed25519_work
pbcopy < ~/.ssh/id_ed25519_work.pub   # GitHubのSSH keysに貼り付ける
ssh -T github-work                    # 接続確認
```

Gitのcommit情報は`~/.gitconfig.work`に書く。`git/.gitconfig`の`includeIf`が指す
ディレクトリ配下のリポジトリだけ、この設定が自動で適用される。

```sh
git config --file ~/.gitconfig.work user.name "Your Name"
git config --file ~/.gitconfig.work user.email "you@company.example"
```

- 対象ディレクトリを変えたい場合や増やしたい場合は、`git/.gitconfig`の
  `includeIf "gitdir:..."`を編集する。
- 適用されているか確かめるには、対象ディレクトリで`git config --get user.email`を実行する。

## Claude / Codexのアカウント切り替え

Claude Codeは`CLAUDE_CONFIG_DIR`、Codex CLIは`CODEX_HOME`を見て設定ディレクトリを決め、
認証情報もその中に保存する。ディレクトリを分ければアカウントが分かれる。

| プロファイル | Claude Code | Codex CLI |
| --- | --- | --- |
| `personal` | `~/.claude` | `~/.codex` |
| その他 | `~/.ai/<profile>/claude` | `~/.ai/<profile>/codex` |

```sh
claude-work           # 仕事アカウントでClaude Codeを起動
codex-work            # 仕事アカウントでCodexを起動
ai work <command>     # 任意のコマンドを仕事アカウントで実行
ai-use work           # 今のシェル全体を切り替える（プロンプトに表示される）
```

- 初回は各プロファイルでログインが必要。Claude Codeは`/login`、Codexは`codex login`。
- `claude-work`のようなラッパーはサブシェルで動くため、呼び出し元のシェルは変わらない。
  戻し忘れて仕事用リポジトリを個人アカウントで触る、という事故が起きない。
- `ai-use`で切り替えたシェルは、プロンプトにプロファイル名が表示される。
- `~/.claude/settings.json`は各プロファイルへsymlinkされ、設定が二重管理にならない。
- プロファイルを増やす場合は`zsh/.config/zsh/config.zsh`の`AI_PROFILES`に追記する。

## 注意

- APIトークンなどの秘密情報は、このリポジトリへcommitしない。
- SSHの秘密鍵は`ssh/`配下に置かない。`.gitignore`で`ssh/.ssh/config`以外を除外している。
- `install.sh`は何度実行しても同じ結果になる。設定を変えたあとの再適用にも使える。
