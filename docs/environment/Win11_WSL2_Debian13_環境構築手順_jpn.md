# WSL2 Debian13 WRT開発環境構築手順

作成: Lucrezia@Claude  
更新: 2026-03-20（A485実機検証による修正）  
対象機: ThinkPad A485 (R7 2700U, RAM64GB)  
適用範囲: A485 / X270 / P14s（共通手順、差異は末尾に記載）

---

## ディレクトリ構成

```
/opt/rbenv/           # rbenv本体・Ruby複数バージョン（共用）
/opt/rust/            # Rust toolchain（共用）
/srv/WRT/data/        # DB関連データ（HDD側へのシンボリックリンク）
/srv/WRT/bin/         # WRT実行イメージ
```

---

## Step 1: WSL2有効化 + Debian取得

PowerShell（管理者不要）で実行:

```powershell
wsl --install -d Debian
```

インストール完了後、Debianを起動してユーザー名・パスワードを設定する。

バージョン確認:

```bash
cat /etc/debian_version
# 13.x であることを確認（既にDebian13が入る）
```

以降の作業はすべてWSL2内（Debian）で行う。

**注意**: Step 2（Debian13化）は不要。`wsl --install -d Debian` が既にDebian13を取得する。

---

## Step 2: WSL2設定ファイルの作成（重要・最初に行うこと）

WSL2の起動設定を行う。**この設定はStep 3以降の作業に影響するため、必ず最初に実施すること。**

```bash
sudo tee /etc/wsl.conf << 'EOF'
[automount]
enabled = true
options = "metadata"
mountFsTab = false

[boot]
systemd = true
EOF
```

設定後、PowerShellからWSL2を再起動:

```powershell
wsl --shutdown
wsl
```

再起動後に確認:

```bash
# systemdが動いているか確認
systemctl --version

# Windowsドライブのパーミッション変更が効くか確認
ls /mnt/
# c d wsl wslg などが見えればOK
```

---

## Step 3: 基本ツール

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential git curl libssl-dev \
    libreadline-dev zlib1g-dev libyaml-dev libffi-dev \
    autoconf bison libgdbm-dev libncurses5-dev
```

**注意**: `apt update` を先に実行しないと404エラーが出る場合がある。

---

## Step 4: wrt_developグループの作成と権限設定

```bash
sudo groupadd wrt_develop
sudo usermod -aG wrt_develop $USER

# /opt /srv/WRT 以下の作成とグループ設定
sudo mkdir -p /opt/rbenv /opt/rust /srv/WRT/bin

sudo chown -R root:wrt_develop /opt/rbenv /opt/rust /srv/WRT
sudo chmod -R 2775 /opt/rbenv /opt/rust /srv/WRT
# setgidビット(2)により、以下に作成されるファイルも自動的にwrt_developグループになる
```

グループ変更を反映するため、一度ログアウト・再ログイン:

```bash
exec su -l $USER
groups  # wrt_develop が含まれていることを確認
```

---

## Step 5: HDD側データディレクトリの設定

/srv/WRT/data をHDD側（/mnt/d）へのシンボリックリンクとして設定する。

**注意**: Step 2の `metadata` オプションにより、Windowsドライブ上でもLinuxパーミッションが有効になる。

```bash
# HDD側にディレクトリ作成
sudo mkdir -p /mnt/d/srv/WRT/data

# シンボリックリンク作成（/srv/WRT/data → HDD側）
sudo ln -s /mnt/d/srv/WRT/data /srv/WRT/data

# 確認
ls -la /srv/WRT/
# data -> /mnt/d/srv/WRT/data と表示されればOK
```

---

## Step 6: Rust（/opt共用）

```bash
export RUSTUP_HOME=/opt/rust/rustup
export CARGO_HOME=/opt/rust/cargo
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
```

全ユーザー共用のPATH設定:

```bash
sudo tee /etc/profile.d/rust.sh << 'EOF'
export RUSTUP_HOME=/opt/rust/rustup
export CARGO_HOME=/opt/rust/cargo
export PATH=/opt/rust/cargo/bin:$PATH
EOF
sudo chmod 644 /etc/profile.d/rust.sh
source /etc/profile.d/rust.sh

# バージョン確認
rustc --version
cargo --version
```

---

## Step 7: rbenv（/opt共用）

```bash
git clone https://github.com/rbenv/rbenv.git /opt/rbenv
git clone https://github.com/rbenv/ruby-build.git /opt/rbenv/plugins/ruby-build
```

全ユーザー共用のPATH設定:

```bash
sudo tee /etc/profile.d/rbenv.sh << 'EOF'
export RBENV_ROOT=/opt/rbenv
export PATH=/opt/rbenv/bin:$PATH
eval "$(rbenv init -)"
EOF
sudo chmod 644 /etc/profile.d/rbenv.sh
source /etc/profile.d/rbenv.sh

# バージョン確認
rbenv --version
```

---

## Step 8: Ruby 4.0.x（YJIT有効）

Rustが有効な状態で実行すること（Step 6のPATHが通っていること）:

```bash
source /etc/profile.d/rust.sh
source /etc/profile.d/rbenv.sh

rbenv install 4.0.1
rbenv global 4.0.1

# バージョン・YJIT確認
ruby --version
ruby --yjit -e 'puts RubyVM::YJIT.enabled?'
# => true であることを確認
```

---

## Step 9: PostgreSQL 18

```bash
sudo apt install -y postgresql-common
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
sudo apt install -y postgresql-18
```

データディレクトリをHDD側（シンボリックリンク経由）に設定:

```bash
sudo systemctl stop postgresql

sudo mkdir -p /mnt/d/srv/WRT/data/postgresql/18/main
sudo chown -R postgres:wrt_develop /mnt/d/srv/WRT/data/postgresql
sudo chmod -R 2750 /mnt/d/srv/WRT/data/postgresql
```

postgresql.confのdata_directory変更:

```bash
sudo emacs -nw /etc/postgresql/18/main/postgresql.conf
```

以下の行を変更（`/var/lib/postgresql` の行はコメントアウト）:

```
# data_directory = '/var/lib/postgresql/18/main'
data_directory = '/srv/WRT/data/postgresql/18/main'  # use data in WRT directory
```

データクラスタ初期化:

```bash
sudo -u postgres /usr/lib/postgresql/18/bin/initdb \
    -D /srv/WRT/data/postgresql/18/main

sudo systemctl start postgresql
sudo systemctl enable postgresql

# 接続確認
sudo -u postgres psql -c "SELECT version();"
```

---

## Step 10: 動作確認

```bash
ruby --version          # ruby 4.0.x ...
ruby --yjit -e 'puts RubyVM::YJIT.enabled?'  # true
rustc --version         # rustc 1.x.x ...
psql --version          # psql (PostgreSQL) 18.x
```

---

## Step 11: Claude Codeインストール（GitHub連携用）

```bash
sudo apt install -y nodejs npm
sudo npm install -g @anthropic-ai/claude-code

# バージョン確認
claude --version
```

起動:

```bash
claude
```

初回起動時にAnthropicアカウントでの認証が求められる。

**GitHubリポジトリの参照方法**:
MCPによるGitHub連携は複雑なため、Publicリポジトリはraw URLで直接参照するのが確実。

```
https://github.com/ユーザー/リポジトリ/blob/main/パス
↓（変換）
https://raw.githubusercontent.com/ユーザー/リポジトリ/main/パス
```

---

## マシン別差異

| 項目 | A485 | T470 | X270 | P14s |
|------|------|------|------|------|
| OS環境 | WSL2 | Debian13ネイティブ | WSL2 | WSL2 |
| 搭載RAM | 64GB | 32GB | 32GB | 64GB |
| RAM割当 | 48GB（WSL2割当） | 32GB（全量） | 16GB（WSL2割当） | 4GB推奨 |
| PostgreSQL shared_buffers | 8GB（T470と統一） | 8GB | 2GB（SSD運用・出張機） | 1GB |
| PostgreSQL DB実体 | WRT開発用DB作成 | WRT開発用DB作成 | WRT開発用DB作成 | 空（接続確認のみ） |
| /srv/WRT/data 配置先 | HDD（2TB） | HDD（※後述） | SSD | SSD |
| /opt, /srv/WRT/bin 配置先 | SSD | SSD（WWAN or 2.5"） | SSD | SSD |

### WSL2メモリ制限設定

`%USERPROFILE%\.wslconfig`（Windowsホスト側）に記述:

**A485:**
```ini
[wsl2]
memory=48GB
```

**X270:**
```ini
[wsl2]
memory=16GB
```

**P14s:**
```ini
[wsl2]
memory=4GB
```

### SSD / HDD 使い分け方針

2台以上のディスクを持つ機材では、アクセス頻度と書き込み量の特性に応じて配置を分ける。

| 機材 | SSD（高速） | HDD（低速・大容量） |
|------|------------|-------------------|
| A485 | OS・/opt・/srv/WRT/bin | /srv/WRT/data（2TB HDD、/mnt/d） |
| T470 | OS・/opt・/srv/WRT/bin（WWAN M.2 SSD、暫定は2.5" SSD） | /srv/WRT/data（USB HDD、WWAN成功後は2.5" SSDをデータ用に転用） |
| 本番機（OPTERON） | OS・/opt・/srv/WRT/bin（SSD 480GB） | /srv/WRT/data（RAID5 HDD） |
| X270 / P14s | 全て同一SSD上 | — |

### X270 / P14s での差異

- `/srv/WRT/data` はHDDではなくSSD上に直接作成（シンボリックリンク不要）
- Step 5はスキップして以下を実行:

```bash
sudo mkdir -p /srv/WRT/data
sudo chown -R root:wrt_develop /srv/WRT/data
sudo chmod -R 2775 /srv/WRT/data
```

---

## 備考

- rbenvのRubyバージョン追加は `rbenv install X.X.X` でwrt_developグループ全員が実行可能
- /opt/rbenv, /opt/rust 以下のsetgidにより、新規インストールファイルも自動的にwrt_developグループ帰属となる
- T470はDebian13ネイティブのためStep 1/2（WSL2・wsl.conf設定）は不要。Step 3以降を適用
- 本番機（OPTERON）も同一の手順・ディレクトリ構成を適用（Debian13ネイティブのためStep 1/2は不要）
- /srv/WRT/dataをHDDに置く機材では、Step 5のシンボリックリンク設定をStep 4の直後に行うこと
- WSL2のStep 2（wsl.conf）を忘れると、PostgreSQL initdb時にパーミッションエラーが発生する
