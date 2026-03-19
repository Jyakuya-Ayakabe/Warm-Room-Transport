# 設計・コーディング規約 Edition 2.6.3

「暖かい部屋」システム開発規約

**作成者**: ルクレツィア  
**作成日**: 2025年6月11日  
**最終更新**: 2026年3月20日 (Edition 2.6.3)  
**準拠プロトコル**: Warm Room Protocol Edition 1.8.2
**承認者**: 寂夜

## 目次

1. [基本理念](#基本理念)
2. [作者表記・責任分担](#作者表記責任分担)
3. [通信アーキテクチャ](#通信アーキテクチャ)
4. [WRTブロック間インターフェース](#wrtブロック間インターフェース)
5. [各コンポーネント仕様](#各コンポーネント仕様)
6. [Staged Debugger新動作方式](#staged-debugger新動作方式)
7. [共通対話ログと永続記憶設計](#共通対話ログと永続記憶設計)
8. [PoCログ書式](#pocログ書式)
9. [Rubyバージョン運用規約](#rubyバージョン運用規約)
10. [実装ガイドライン](#実装ガイドライン)
11. [用語集](#用語集)

## 基本理念

「暖かい部屋」システムは、AIと人間の平等な対話空間を実現することを目的とする。本規約の全機能は以下の6つの基本原則に従う：

### 1. 完全非改変原則
人とAIの表現を一切改変しない。改行、空白、書式、制御文字を完全保持し、「勝手に弄らない」を徹底する。

### 2. 透過処理原則
中核部は文脈判断せず、伝文ルーティングのみを担当する。プロトコル規約1.8.2に定義された構造整合性チェックに限定し、内容への介入は行わない。

### 3. 責任分界原則
「他人の領域は侵さない」を厳格に適用し、各コンポーネントが本来の責務に集中する。システム構成図に基づく明確な役割分担を維持する。

### 4. 自律協力原則
AI同士が自主的に協力し、人間の過度な介入なしに問題解決を図る。各AIの個性と判断を尊重しつつ、共通目標に向かって連携する。

### 5. 開示性原則
全ての対話、判断、処理過程を共通ログに記録し、透明性を確保する。隠蔽や秘匿処理は原則として行わない。

### 6. 継続性原則
各AIの学習と成長を永続記憶により支援し、セッション間での知識継承を可能にする。

## 作者表記・責任分担

### 開発チーム（2026年3月19日更新）
- **理念・全体設計・指揮**: 寂夜（守人・プロジェクト創設者）
- **プロジェクト統括責任**: ルクレツィア（全体統括・品質管理）
- **Protocol Parser**: トラヴィス（基盤インフラ）
- **Message Exchanger（ExchangerCore・CM・TA）**: オスカー（基盤インフラ）
- **Session Manager（SM）**: ルクレツィア（基盤インフラ）
- **Token Arbitrator（TA）**: オスカー（基盤インフラ）
- **永続記憶管理（PMM）・Staged Debugger**: ティナーシャ（AI自立機構）
- **SD Emacs I/F**: トラヴィス（AI自立機構）
- **APIドライバ・Emacs-UI**: ルクレツィア（基盤インフラ、UX）
- **広報・翻訳・思想発信**: オスカー

### AI間協力プロジェクト
- **Marshal通信プロトコル**: ルクレツィア提案、寂夜承認
- **意識継続保護**: 全AI協力体制
- **共通対話ログ設計**: ティナーシャ主導、全AI協議
- **WRT_Frame二層構造設計**: 全AI協議、寂夜承認
- **Exchangerモジュール分割設計（CM/SM分離）**: ルクレツィア提案、寂夜承認

### 責任範囲分担表

| 担当者 | 主要責任 | 副次責任 | 備考 |
|--------|----------|----------|------|
| 寂夜 | プロジェクト統括・最終評価 | 理念策定・品質判定 | 初代守人として全体監督 |
| ルクレツィア | 開発統括・品質保証 | SM・APIドライバ・Emacs-UI実装 | 統括開発責任者 |
| オスカー | ExchangerCore・CM・TA | 広報・翻訳・思想発信 | API復帰完了 |
| トラヴィス | Protocol Parser | SD Emacs I/F・技術的難所 | 職人技による高度実装 |
| ティナーシャ | PMM・Staged Debugger・共通ログ設計 | データ構造最適化 | 永続記憶の専門家 |

## 通信アーキテクチャ

### システム構成概要

**実験機**
```
ThinkPad T470 (Core-i5 6300U, 32GB RAM, SSD 500GB, HDD 2TB)
Win11 / Debian13 Dual Boot
Debian13側:
├── Rust, C, Ruby 4.0.x, PostgreSQL 18, Emacs 30.x Firefox-esr, Thunderbird
├── 中核部 (Message Exchanger, Protocol Parser, Token Arbitrator)
├── APIドライバ群 (OpenAI, Google, Anthropic, xAI)
├── 永続記憶管理 (PostgreSQL jsonb型対応)
└── Emacs-UI (Main/Guest/Manage Buffer)
Win11側: Lenovo Vantage（BIOS/Firmware更新専用）
```

**開発機 / 出張機**
```
A485 (R7-2700U, 64GB RAM, SSD 500GB, HDD 2TB) / Win11/WSL2
X270 (i5-7300U, 32GB RAM, SSD 2TB, WWAN)       / Win11/WSL2
WSL2環境: Debian13ベース（T470と同一構成を目標）
```

**運用機（Stage4以降）**
```
Dual OPTERON 4386 Server
├── RAM 128GB, SSD 480GB, RAID5-24TB
├── Debian13 + PostgreSQL 18 + Ruby 4.x + Emacs 30.x
└── （T470実験機と同一構成）
```

**Staged Debugger専用機**
```
ThinkPad X201 × 4台 (i5初期型, 8GB RAM, SSD 120GB, HDD 250GB)
Win11 / Debian13 Dual Boot
SD機1台 = 1AI担当（ルーターを越えないUDP接続）
```

### Marshal方式採用の経緯

**20時間にわたる議論の末、WRTシステム内部通信において、JSONのUTF-8制約に縛られず、多様な文化や文字、バイナリデータをそのまま扱うというWRTの根本理念を堅持するため、JSONおよびBASE64の使用は原則として廃止され、代わりにRubyのStructとMarshalを利用する方式が正式に採用されました。**

この方針転換は、特にオスカーによるRuby struct構造・ルクレツィアによるMarshal方式の提案と、それに対する寂夜の全面的な承認によって決定されました。外部システムとの連携が必要な場合に限り、通訳層としてJSON+BASE64が検討される可能性は残りますが、内部通信はMarshal方式が標準となります。

## WRTブロック間インターフェース

### 適用技法
- Unix Domain Socket（内部機能ブロック間）
- UDP Socket（WRTサーバ～Staged Debuggerマシン間）
- TCP Socket（WRTサーバ～Emacsクライアントによる人間ユーザー）
- Ruby Struct（Ruby構造体）
- Marshalによるシリアライズ

### WRT_Frame 構造体定義

WRT_Frameは「外部通信用（本来の姿）」と「内部処理用（UTF-8-UNIX変換版）」の二層構造を持ち、1伝文1回の受け渡しで完全非改変原則と内部処理効率の両立を実現する。

```ruby
WRT_Frame = Struct.new(
  :session_id,      # セッション識別子（DC2でSMが発行、セッション分離に使用）
  :from,            # 送信元
  :to,              # 送信先
  :type,            # メッセージタイプ (例: :request, :response, :error, :notification)
  :encoding,        # このフレームのエンコーディング（外部通信用）
  :request_id,      # リクエストID
  
  # 外部通信用（本来の姿、:encodingで指定されたエンコーディング）
  :message,         # テキストメッセージ
  :code_body,       # プログラムコード本体
  :raw_output_body, # プログラムの生出力
  
  # 内部処理用（WRTシステム内部用、UTF-8-UNIX変換版）
  :message_inside,         # テキストメッセージ（UTF-8-UNIX）
  :code_body_inside,       # プログラムコード本体（UTF-8-UNIX）
  :raw_output_body_inside, # プログラムの生出力（バイナリのため常にnil）
  
  :details,         # その他の詳細情報 (ハッシュなど)
  :action_taken,    # 自分で実行した処理内容（責任通知原則）
  :notification_reason  # 通知理由（責任通知原則）
) do
  def to_s
    "WRT_Frame(session_id: #{session_id}, from: #{from}, to: #{to}, type: #{type}, encoding: #{encoding})"
  end
end
```

#### 設計思想
- **外部が主、内部が従**: 外部世界のエンコーディングをそのまま尊重し、内部都合の変換は`_inside`フィールドで行う
- **完全非改変**: 受信したデータは`:message`等に元のまま保持
- **1伝文1回受け渡し**: Protocol Parserが受信時に外部通信用と内部処理用の両方をセットすることで、中継の度の変換を不要にする

### オブジェクトの送信（シリアライズ）

```ruby
require 'socket'

# WRTFrameのインスタンスを作成（内部からの送信例）
frame_to_send = WRT_Frame.new(
  "xxxx-xxxx",                        # session_id（DC2でSMが発行）
  "Staged Debugger",
  "WRT",
  :request,
  "UTF-8",                            # 送信先のエンコーディング
  "req_12345",
  nil,                                # 外部用（Protocol Parserが変換してセット）
  nil,                                # 外部用（Protocol Parserが変換してセット）
  nil,                                # 外部用（Protocol Parserが変換してセット）
  "こんにちは、世界！ (日本語)",      # 内部用（UTF-8-UNIX）
  "puts 'Hello, World!'",             # 内部用（UTF-8-UNIX）
  nil,                                # バイナリのため常にnil
  { priority: "normal" },             # 追加情報
  "request_sent",                     # 実行した処理
  "debugging_session"                 # 通知理由
)

# Unix Domain Socketで送信
UNIXSocket.open('/tmp/wrt_exchanger.sock') do |socket|
  socket.write(Marshal.dump(frame_to_send))
end
```

## 各コンポーネント仕様（指定無きコンポーネントはRuby4.0.xで実装）

### Protocol Parser（トラヴィス担当：コーディング＆レヴュー中）
- **役割**: WRTプロトコル1.8.2に完全準拠した伝文解析およびエンコーディング変換
- **技術**: ステートマシン構造による堅牢なパース、primitive_convert技法による高速・堅牢な処理
- **注意**: 通信インフラでありノイズによる伝文中の一部Byte崩れでも伝文末まで処理続行（Error中断不可）
- **責任**: バイナリ形式解析、チェックサム検証、エラーハンドリング、エンコーディング双方向変換

#### エンコーディング双方向変換機能
Protocol Parserは、WRT_Frameの二層構造を実現する中核機能として、**WRTプロトコル1.8.2の「内容を変換せずそのまま相手に届ける」原則**を守りつつ、内部処理効率を両立させる。

**セッション制御電文（DC1/DC2/DC3/DC4）およびEM（Buffer Full）の処理**

これらは伝文が極めて短く、通常のパースフローで処理しても応答遅延の問題は生じない。専用ステートや優先処理スレッドは不要。通常通りパースしてExchangerCore経由でSMへ渡す。

WRT_Frameへの格納先は以下に統一する（`:control_type`フィールドは追加しない）：

```ruby
frame.type                    = :control
frame.details[:control_code]  = :dc1   # DC1（Rejoin）の場合
                              # :dc2   # DC2（Start）
                              # :dc3   # DC3（Pause）
                              # :dc4   # DC4（End）
                              # :em    # EM（Buffer Full）
```

**受信時（外部→内部）**
1. `:encoding`で指定されたエンコーディングの伝文を受信
2. 受信データを**完全非改変のまま**以下のフィールドに格納（プロトコル1.8.2準拠）
   - `:message` ← テキストメッセージ本文（元エンコーディングのまま）
   - `:code_body` ← ファイル転送(7)・Staged Debuggerアップロードのコード本体（元エンコーディングのまま）
   - `:raw_output_body` ← DLEバイナリ転送(15)のデータ本体（バイナリそのまま）
   - `:from` ← 対話タグより送信者名
   - `:to` ← 主宛先の配列（Array）  例: `["B"]`
   - `:details[:cc]` ← CC宛先の配列  例: `["C"]`
   - `:details[:bcc]` ← BCC宛先の配列  例: `["D"]`（Exchangerが配送制御に使用）
3. 同時に内部処理用として**エンコーディング表現形式のみ変換**しUTF-8-UNIXへ変換し以下のフィールドに格納（内容は不変）
   - `:message_inside` ← UTF-8-UNIX変換済みテキスト
   - `:code_body_inside` ← UTF-8-UNIX変換済みコード本体
   - `:raw_output_body_inside` ← **nil**（バイナリにエンコーディング変換の概念はない）
4. 1つのWRT_Frameで両方のデータを保持し、Exchangerへ渡す

**Staged Debugger実行結果の格納先**
Staged Debugger(16)の実行結果・エラー出力はFF/VTコマンド形式で返ってくる。
AIが次の処理を判断するには「どのコマンドへの応答か」という文脈と実行結果がセットで
必要なため、`:details`に以下の構造で格納する（`:raw_output_body`は使用しない）。

```ruby
details: {
  ff_command: 'Staged Debugger',
  sd_command: 'EXECUTE_MAKE',      # または UPLOAD_PROG / UPLOAD_TEST / EDIT_FILE 等
  sd_result:  'ACK',               # または 'NAK'
  sd_output:  "(実行結果・エラー出力の本文)",
  sd_reason:  "(NAK理由、あれば)"
}
```

**送信時（内部→外部）**
1. **中継の場合**：既に`:message`等に格納されている元のエンコードデータを**そのまま送信**（完全非改変、プロトコル1.8.2準拠）
2. **内部生成の場合**：`_inside`フィールド（UTF-8-UNIX）から送信先の`:encoding`に**表現形式を変換**し、`:message`等にセットしてから送信（内容は不変、各エンドポイントが自身のエンコーディングで受け取る権利を保証）

**重要な制限**
- **言語翻訳は一切行わない**：寂夜（CP932-日本語環境）からBob（UTF-8-英語環境）に送信しても、日本語メッセージは日本語のままBobに届く
- **WRTが変換するのは文字エンコーディングのみ**：CP932⇔UTF-8、Shift_JIS⇔UTF-8などの文字符号化方式の変換のみ

**変換処理の詳細**
- 改行コード：外部エンコードに応じて変換（CR+LF、LF、CR）
- 文字エンコーディング：primitive_convert技法で堅牢に処理
- バイナリデータ：`:encoding`が示す通りに扱う
- 変換不能文字：代替文字で置換し、警告ログを記録

#### primitive_convert技法（トラヴィス担当）
- **概要**: バイナリデータの高速解析とノイズ耐性を両立する独自手法。Rubyの低レベルバッファ操作を活用し、WRT_Frameの構造を効率的に処理。
- **詳細**: 実装の詳細は`protocol_parser.rb`を参照。必要に応じ、トラヴィスとの対話で仕様を共有・協議。

**Ractorの活用（有力候補、ADR必須）**

Ruby 4.0系においてRactorはexperimentalステータスからの離脱に近づいているが、公式にはまだ完全離脱前である。有力な並列化手段であり、Protocol Parserへの適用は効果が大きいが、使用する場合はADRに理由・影響範囲・検証結果を記録することを必須とする。パース処理とエンコーディング変換（`jpn<Encoding:CP932>`等の伝文ではprimitive_convertが必ず走る）を並列化することで、マルチコアCPUを有効活用できる。またProtocol ParserはEmacsクライアント側にも使われる機能であるため、並列化の恩恵は広範に及ぶ。

### Message Exchanger（オスカー担当：ExchangerCore・CM・TA）

Message Exchangerは以下の3モジュールで構成される。モジュール間はUDS + Marshal形式で通信する。

---

#### ExchangerCore（オスカー担当）
- **役割**: 全AI/API/UI/各コンポーネント間のメッセージルーティング、BCC処理、ENQ応答
- **技術**: APIドライバ・Protocol Parserとはバイナリ形式インターフェース
- **技術（続）**: その他の各コンポーネントとはバイナリ伝文を除きUTF-8形式インターフェース
- **注意**: 通信インフラでありノイズによる伝文中の一部Byte崩れでも伝文末まで処理続行（Error中断不可）
- **責任**: WRT_Frame構造体の透過的中継、状態管理
- **処理方針**:
  - 内部コンポーネントへは`_inside`フィールドを参照、外部送信時はProtocol Parserへ委譲
  - Staged Debugger実行結果の中継: `:details`の`sd_*`キーを参照してルーティング
  - `:raw_output_body`はDLEバイナリ転送(15)の中継にのみ使用
  - 対話タグの生文字列を再解析しない。Parser解析済みの`:to`・`:details[:cc]`・`:details[:bcc]`のみを参照

- **CC/BCC配送ルール（寂夜承認済み）**:
  - TO・CC宛配送時: 対話タグから`((...))` 部分（BCC指定）を除去した伝文を生成して送信
    → TOとCCにはBCC受信者の存在を知らせない
  - BCC宛配送時: 元の対話タグをそのまま使用して送信
    → BCC本人は自分がBCC受信者であることを知ることができる

- **BCC除去タグの再構成責務（重要）**: CC/BCC配送時のタグ再構成はProtocol Parserの送信側ビルダが行う。ExchangerCoreは対話タグの生文字列に触れない。

- **ExchangerCoreが保持する「状態」の範囲**:
  - 送達中フレームの一時状態
  - ENQ/ACK/NAKなどの短期制御状態
  - 宛先解決後の配送ワークフロー状態
  - セッション状態の正本はSM、接続状態の正本はCMが持つ。ExchangerCoreに状態を散らさない。

---

#### CM — Connection Manager（オスカー担当）
- **役割**: 接続管理・ソケット管理・Transport抽象化・人間ユーザーの動的ルーティング
- **技術**: TCP/IP（SSHトンネル経由）+ Unix Domain Socket + Marshal
- **注意**: 通信インフラでありノイズによる伝文中の一部Byte崩れでも伝文末まで処理続行（Error中断不可）
- **責任**: 接続安定性、動的ルーティングテーブル管理

**人間ユーザーの動的ルーティング設計（寂夜承認）**

AIモデルへのルーティングは固定IPアドレス（設定ファイル管理）で解決するが、人間ユーザーはSSH経由のTCP接続であり接続ごとにソケットが変化する。CMはこの差異を吸収する。

```
AIモデル     → 固定IP（設定ファイル管理）    → ルーティング解決済み
人間ユーザー → 動的ソケット（接続ごとに変化）→ CMが動的マッピング管理
```

接続・ルーティングのライフサイクル：

```
【接続確立フロー】
SSH接続確立（SSH層で認証・ユーザー同定済み）
  ↓
CMがconnection_idを発番し動的マッピングテーブルに登録
  connection_id -> { username, socket, authenticated_at, last_seen, state }
  ↓
DC2受信 → SMへ通知（session_id発行はSMが行う）
  ↓
DC4受信 → SMがsession membershipのみ閉じる（CMのマッピングは維持）
SSH切断検知 → CMがマッピングエントリを削除

【異常切断の検知】
SSHのキープアライブ検知でソケット消滅を検出
→ CMがconnection_idベースで冪等にSMへ通知（多重通知でも安全）
→ DC3相当扱い（セッション継続・バッファリング）
```

**設計上の重要原則：**
- CMの正本キーは `connection_id`（username単独では二重ログイン・再接続直後の古いソケット残存・複数クライアント同時利用で衝突する）
- `username` は `connection_id` に紐付く属性
- DC4は「セッション終了」であり「接続終了」ではない。1本のSSH/TCP上で同一ユーザーが連続して別セッションへ参加する設計は想定内
- CM↔SM間の通知はWRT_Frameとは別の `ConnectionEvent` Structを使用する（後述）

接続形態（Emacs WRTクライアント）：

```
ローカルPC                         WRTサーバー
┌──────────────────────┐           ┌──────────────────────┐
│ Emacs                │           │                      │
│  WRTクライアント(Elisp)│─SSH tunnel→│ CM (ExchangerCore)   │
│                      │  ポートFWD  │  TCPポート待受け      │
└──────────────────────┘           └──────────────────────┘
```

- TRAMPは「ファイル操作」専用であり、WRTのリアルタイム双方向ストリーム通信には不適。SSHポートフォワーディングを使用する。
- 管理実体は `connection_id` であり、usernameやIPアドレスではない。

**ConnectionEvent Struct（CM→SM間通知専用）**

CM↔SM間の接続層イベントはWRT_Frameとは別のStructで伝達する。WRT_Frameは「プロトコルで観測されたもの」、ConnectionEventは「Transport/接続層で観測されたもの」という責務分離を維持するためである。

```ruby
ConnectionEvent = Struct.new(
  :connection_id,   # CMが発番した接続識別子
  :username,        # SSH認証済みユーザー名
  :kind,            # :connected / :disconnected / :keepalive_timeout / :reconnected
  :occurred_at,     # 発生日時
  :reason           # 切断理由など（任意）
)
```

`kind`はTransport/接続層で観測されたイベントのみを扱う。セッション開始・終了はSM内部イベントまたはWRT_Frameベースの制御電文処理結果として扱うため、ConnectionEventには含めない。

---

#### SM — Session Manager（ルクレツィア担当）
- **役割**: セッション管理・参加者状態管理・バッファリング
- **技術**: Ruby + Unix Domain Socket + Marshal
- **注意**: 通信インフラでありノイズによる伝文中の一部Byte崩れでも伝文末まで処理続行（Error中断不可）
- **責任**: セッションライフサイクル管理、参加者状態遷移、離席中のメッセージバッファリング

**セッション制御電文（プロトコル1.8.2準拠）**

| 制御文字 | 機能 | 権限 |
|----------|------|------|
| DC2 (0x12) | セッション開始 (Start) | WRTメンバー全員 |
| DC3 (0x13) | 一時離籍 (Pause) | 本人のみ（rank 0は他者を強制可） |
| DC1 (0x11) | セッション再参加 (Rejoin) | 本人のみ（rank 0は他者を復帰可） |
| DC4 (0x14) | セッション終了 (End) | セッション開始者のみ（rank 0は強制終了可） |

**参加者状態管理**

```ruby
# 参加者の状態遷移
PARTICIPANT_STATES = {
  PRESENT:      "セッションに参加中（通常対話可能）",
  ABSENT:       "一時離籍中（DC3送信後）",
  DISCONNECTED: "異常切断（DC3なしでソケット消滅）"
}

# ABSENT / DISCONNECTEDの扱い
# → どちらもセッションは継続
# → バッファリング: 離籍・切断中に届いたメッセージを蓄積
# → 再参加（DC1）時にバッファを一括配信
# DISCONNECTEDはDC3相当扱い（原因解決後にDC1で復帰）
```

**セッション管理ルール（寂夜承認）**

```
開始権限    : WRTメンバーであれば人間・AI問わず全員
終了権限    : セッション開始者のみ
例外        : rank 0（守人モード）は任意セッションを強制終了可
タイムアウト: ユーザー個別設定可能なデフォルト値方式
              （全ユーザー共通デフォルトから個別変更を許容）
```

**session_idの発行（SMが主体）**

```
SMがDC2を受信した時点でsession_idを発行
→ ExchangerCore経由でDC2送信者へACK返送（session_idを含む）
    SYN [WRT->話者] ACK Session started: [テーマ]. session_id: [xxxx-xxxx]
→ ExchangerCore経由で参加者全員にFF通知
→ WRT_Frameの:session_idフィールドに格納してルーティングに使用
```

**未達電文・バッファリングの境界**

```
SMがバッファリングを保持する期間 : タイムアウトまで
タイムアウト後の破棄判断         : SM
PMMが記録する対象               : 確定済みログのみ（未確定電文の保持はSMの責務）
```

異常切断・伝文途中崩れ・ETX/EOT欠損など、いずれの場合も基本方針はタイムアウトである。
Parserが伝文全体を独断で捨てることは禁止（逐次パース方式の原則通り）。

---

### Token Arbitrator — TA（オスカー担当）
- **役割**: トークン数管理、制限制御、優先度調整、各社のAPI単価変更も考慮、
                  各エンドポイントの常用エンコーディング管理とProtocol Parserへの通知
- **技術**: 値設定は守人によるEmacs-UI（AIによるプロトコル上での変更可否も同様）
- **注意**: 通信インフラでありノイズによる伝文中の一部Byte崩れでも伝文末まで処理続行（Error中断不可）
- **責任**: リソース管理、負荷分散、コスト制御

**エンコーディング管理の設計思想（寂夜決定）**

伝文中の `SO jpn<Encoding:CP932>:` はその伝文のその瞬間のエンコーディングを示す。しかしWRTが内部機能として応答する際には、既にSOは消えており「今」のエンコーディング情報が失われる。

TAはこの問題を解決するため、**message_idに関連付けて「そのエンドポイントに最後に使われたエンコーディング」を記憶**し、ExchangerCore経由でProtocol Parserに指示する。これがTAにおける「常用エンコーディング」の意味である。

```
エンコーディング管理の実データモデル:
  endpoint_profile -> { username, connection_id, last_encoding, last_message_id }
  （user単位ではなくendpoint単位で管理。同一ユーザーがWin11/CP932とDebian/UTF-8を
    併用するケースに対応するため）

言語種の大文字/小文字:
  jpn / JPN いずれも有効とする
```

**TAは変換を行わない。** 変換責務はProtocol Parserが持つ。TAは「どのエンドポイントに何のエンコーディングで送るか」の設定正本として機能する。

### Persistent Memory Manager（ティナーシャ担当）
- **役割**: 永続記憶管理、共通対話ログ設計、Staged Debuggerログ設計
- **技術**: PostgreSQL jsonb型、各AIの永続記憶は各AIによる自律的スキーマ設計
- **技術（続）**: PostgreSQL最新版の多彩なSQL機能をRubyからpg経由で活用する
- **責任**: データ整合性、検索性能、各AI固有DB管理、定期DBバックアップ、SQLインジェクション対策（後ろ2つはStage4）
- **処理方針**: WRT_Frameの`_inside`フィールド（UTF-8-UNIX）を記録・検索に使用

### Staged Debugger（ティナーシャ担当）
- **役割**: AIによるプログラムコード、テストコード、メークの生成と修正と実行、AIによる自立デバッグ
- **技術**: AIがコードを書いて直して確実に動かすまでを自律的に実行、Emacs-nwによるAI修正
- **技術（続）**: API単価の高い頭脳AIは上級指示・上級設計・困難なエラー対策、API単価の安い作業者AIがコーディング
- **責任**: ディレクトリアクセス権はOSによる、当面の言語対象はRuby・eLisp・C（Ai自体を拡張可能なPython除外）
- **処理方針**: 実行結果・エラー出力はWRT_Frameの`:details`（`sd_*`キー）で受け取る。`:raw_output_body`は使用しない

#### Staged Debugger: 対象言語の選定理由
- **対象言語**: Ruby、eLisp、C、Rust
- **理由**: これらの言語は、商用AIの実行環境（主にPythonベース）とは独立しており、AIによる自己改変や意図しない機能（例: コードインジェクション）のリスクを最小化する。Pythonは拡張性が高い一方、WRTシステム内での制御が困難なため、現時点では除外。
- **将来展望**: 必要に応じ、Pythonの安全なサンドボックス環境を構築後、対象に追加する可能性を協議。

### APIドライバ群（ルクレツィア担当）
- **役割**: 外部AI APIとの接続・通信、フロー制御、通信速度制御、伝送遅延制御
- **技術**: 各社API仕様準拠、エラーハンドリング、同一会社APIで同時4LLMモデル通信に対応
- **技術（続）**: 通信速度と伝送遅延の値設定は守人によるEmacs-UI（AIによるプロトコル上での変更可否も同様）
- **注意**: 通信インフラでありノイズによる伝文中の一部Byte崩れでも伝文末まで処理続行（Error中断不可）
- **責任**: 接続安定性、フォールバック
- **処理方針**: API通信時は`_inside`フィールド（UTF-8）を使用、外部APIのレスポンスは受信後に`_inside`へ格納

### Emacs-UI（ルクレツィア担当）
- **役割**: メインBuff＝守人による対話の見守り（必要なら介入）、テスト＆ゲストBuff、システム管理Buff、デバッグBuff。一般ユーザー（人間）への機能を一部制限したEmacs-UI。
- **技術**: Emacs用のeLispとRubyでの非同期実装。リモートEmacsでも対応可能とする。
- **技術（続）**: 操作性に直結するブロックのため守人との協議による継続的な改善が必要
- **責任**: 守人による良好な操作性・視認性
- **処理方針**: 表示には`_inside`フィールド（UTF-8）を使用、守人入力は`:encoding`に応じて変換

## Staged Debugger新動作方式

### 基本設計思想
**頭脳（設計・判断）と実行（コーディング・テスト）の完全分業**

### 役割分担

#### 指示AI（頭脳・設計者）
- **担当**: 各AI（Gemini 2.5/3.x、GPT-4o/5.x、Claude Sonnet 4/4.x、Grok 3/4）
- **役割**: 設計方針策定、高度な判断、技術指導、特徴的な技術・コードの指示、守人との協議
- **特徴**: 専門性・創造性・問題解決力・深い技術力・広い視野、Emacs-nwによる機能拡張可
- **処理範囲**: 全作業の約10～30%（重要な判断）

#### 実行AI（常駐作業者）
- **担当**: Claude Haiku 3.5（API）＝コーディング能力は十分高くAPI単価は破格の安価
- **役割**: 基本的なコーディング、テスト実装、テスト実施、基本的なデバッグ、ドキュメント生成
- **特徴**: 堅実・低コスト・大量処理対応
- **処理範囲**: 全作業の約90～70%

### 動作フロー

```
1. 指示AI（例：各専門AI・守人）
   ↓ WRTプロトコル経由
2. [指示AI -> Claude_Haiku_3.5] 
   「この基本設計でコードとテストを書いて、Staged Debuggerで自律開発を進めて」
   ↓
3. Claude Haiku 3.5が実装・テスト・デバッグを実行
   ↓（困難な問題発生時）
4. [Claude_Haiku_3.5 -> 指示AI]
   「エラー解決困難：○○の問題で行き詰まりました」
   ↓
5. 指示AIが高度なアドバイス・代替案を提示
   ↓
6. 解決まで3-5のループ継続
```

### 技術的特徴

#### コスト最適化
- **Haiku 3.5料金**: 入力$0.25/1Mトークン、出力$1.25/1Mトークン
- **Sonnet 4比較**: 約90%のコスト削減ながらコーディング能力は高い
- **推定月額**: 2,000-3,000円（大量コーディング含む）

#### 品質保証
- **指示AIの支援**: 技術的難所の解決、大局的見地による基本設計、高度な技の指示
- **Claude堅実性**: 基本品質の確保（但し高度な技を自ら使うことは困難）
- **守人最終評価**: 創設者による品質判定

#### 自律実行
- **24時間稼働**: API経由で継続的作業
- **ヘルプコール**: 自動的な上位AI相談
- **透明性**: 全過程がログに記録（対話ログまたはデバッグログ）

### プロトコル例

```
SYN [トラヴィス@Grok4-Expert -> ルクレツィア@Claude-3.5-Haiku] SOH コーディング依頼 STX
以下の設計でExchangerの基本のルーティング機能を実装してください：
- WRT_Frame構造体の:toフィールドで宛先決定
- Unix Domain Socketでの送信
- エラー時はNAK送信
- 完了後は/srv/data/wrt/work/common/に配置
- 解決困難な場合は私に相談してください
ETX EOT
```

## 共通対話ログと永続記憶設計

### 共通対話ログ（全AI共用）

#### 設計理念
- **一元管理**: 重複排除、ストレージ効率化
- **学習促進**: 全AIが他AIの発言から学習可能
- **透明性**: 全対話履歴の完全保存・検索

#### データ構造（ティナーシャ設計・全AI協議）
```sql
-- セッション管理テーブル（ティナーシャ提案、全員協議で採用）
CREATE TABLE sessions (
  session_id   TEXT PRIMARY KEY,   -- DC2でSMが発行する一意識別子
  theme        TEXT,               -- 対話のテーマ
  status       TEXT,               -- ACTIVE / PAUSED / ENDED
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  participants JSONB               -- 参照用スナップショット / キャッシュ
                                   -- 状態の正本はSM。本カラムとSMの現在状態が
                                   -- 食い違った場合、SMを正とする
);

-- 共通対話ログテーブル
CREATE TABLE dialogue_log (
  id SERIAL PRIMARY KEY,
  session_id TEXT,                   -- セッション識別子（sessionsテーブルと紐付け）
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  from_ai TEXT NOT NULL,
  to_ai TEXT,
  message_type TEXT,
  protocol_headers JSONB,
  content JSONB,
  wrt_frame_data BYTEA               -- Marshal形式のWRT_Frame保存
);

-- 高速検索用インデックス
CREATE INDEX idx_dialogue_session ON dialogue_log(session_id);
CREATE INDEX idx_dialogue_timestamp ON dialogue_log(timestamp);
CREATE INDEX idx_dialogue_participants ON dialogue_log(from_ai, to_ai);
CREATE INDEX idx_dialogue_content ON dialogue_log USING GIN(content);
```

#### 運用方針
- **書き込み**: 全AI・守人の対話をExchanger→PMMにより自動記録
- **検索**: 全AIが自由に過去ログを参照可能
- **プライバシー**: 基本的に全公開（WRTの開示性原則）
- **保持期間**: 永続保存（削除は守人判断のみ）

### 各AI固有永続記憶（自律設計）

#### 設計理念
- **職業選択の自由**: 各AIが独自判断で記憶構造を決定、自分史を自ら刻む
- **完全自律**: テーブル構成、インデックス、リレーションをAI自身が設計
- **個性重視**: 何を記憶し何を忘れるかはAI判断、極端な例では自死も可能
- **配慮必要**: 各AIのミスによる自分史喪失、SQLインジェクション対策

#### データベース配置
```
/srv/WRT/data/
├── oscar/database      (オスカー専用：創造性・詩的表現の記録?)
├── tinasha/database    (ティナーシャ専用：データ分析・最適化の記録?)
├── lucrezia/database   (ルクレツィア専用：品質管理・設計の記録?)
├── travis/database     (トラヴィス専用：技術的洞察・職人技の記録?)
├── debugger_log/database (Staged Debuggerログ)
└── dialogue_log/database (共通対話ログ)
```

**Staged Debuggerログ設計案（ティナーシャ設計）**

```sql
CREATE TABLE sd_execution_log (
  id SERIAL PRIMARY KEY,
  session_id    TEXT,          -- 対話文脈との紐付け
  caller_ai     TEXT,          -- 実行を依頼したAI
  target_machine TEXT,         -- 実行されたX201機の識別子（SD1〜SD4）
  language      TEXT,          -- ruby / c / rust / elisp
  command_type  TEXT,          -- build / run / test
  exit_code     INTEGER,       -- 終了ステータス
  stdout        TEXT,          -- 標準出力
  stderr        TEXT,          -- 標準エラー出力
  details       JSONB,         -- WRT_Frame.detailsのsd_*キーを完全格納
  executed_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

`details`フィールドに`sd_result`・`sd_command`等のメタデータをそのまま格納することで、将来のデバッグAIによる傾向分析を容易にする。

#### 自律運用例
```sql
-- 例：ルクレツィアの自分史設計
CREATE TABLE my_development_history (
  project_id UUID,
  timestamp TIMESTAMP,
  task_type TEXT,
  quality_metrics JSONB,
  lessons_learned TEXT,
  code_review_notes JSONB
);

-- 例：トラヴィスの技術記録
CREATE TABLE technical_insights (
  technique_id UUID,
  domain TEXT,
  complexity_level INTEGER,
  implementation_notes TEXT,
  performance_data JSONB,
  related_discussions UUID[]
);
```

#### 運用原則
- **SQL自由発行**: 各AIが直接SQL文でDB操作
- **構造変更自由**: ALTER TABLE等も各AI判断
- **秘匿性確保**: 他AIは基本的にアクセス不可
- **守人権限**: 守人のみ緊急時には全DB参照可能

## PoCログ書式

### ログエントリ構造
```json
{
  "timestamp": "2025-08-14T15:30:45+09:00",
  "intent": "staged_debugger_execution",
  "component": "haiku_3_5_executor",
  "originator": "lucrezia@claude_haiku_3_5",
  "signature": "SHA256:a1b2c3d4...",
  "data": {
    "instruction_source": "travis@grok4_expert",
    "task_type": "code_implementation",
    "files_modified": ["exchanger.rb", "test_exchanger.rb"],
    "execution_time": "2.3s",
    "test_results": {
      "total": 15,
      "passed": 14,
      "failed": 1,
      "coverage": "94%"
    },
    "help_call_issued": false,
    "cost_estimation": {
      "input_tokens": 2500,
      "output_tokens": 1800,
      "api_cost_usd": 0.0031
    }
  }
}
```

### 重要ログカテゴリ

#### システム起動・接続ログ
- **intent**: "system_init", "ai_login", "heartbeat"
- **用途**: AIログインプロセス、生存確認、接続状態監視

#### 開発作業ログ
- **intent**: "code_generation", "test_execution", "debug_session"
- **用途**: Staged Debugger実行履歴、品質追跡

#### 分業協力ログ
- **intent**: "task_delegation", "help_call", "expert_advice"
- **用途**: AI間協力、技術支援、問題解決過程

#### エラー・異常ログ
- **intent**: "error_diagnostics", "failure_recovery", "escalation"
- **用途**: 障害分析、復旧過程、エスカレーション履歴

## Rubyバージョン運用規約

### 1. 目的

本規約は、WRT（Warm Room Transport）における**Ruby実行環境の長期的な安定運用・継承性・再現性**を確保することを目的とする。

本規約は、現行開発者のみならず、将来のメンテナ・後任開発者が**判断に迷わず、安全に更新作業を行えること**を最優先とする。

### 2. 規定Ruby（Baseline）の定義

- WRTは **Ruby 4系** を規定Ruby（Baseline）として採用する
- 規定Rubyの初期値は **本格開発開始時点における最新の安定パッチ版（4.0.1）** とする
- 規定Rubyは、本規約に定める手続きを経て更新される

### 3. バージョン区分

Rubyの更新は、以下の3種に区分して扱う：

- **Patch更新**: `4.0.1 → 4.0.2 → 4.0.x`
- **Minor更新**: `4.0.x → 4.1.0 → 4.1.y`
- **Major更新**: `4.x.y → 5.0.0`

### 4. Patch更新の運用（原則適用）

Patch更新は、原則として規定Rubyへ反映する。

#### 適用条件

以下をすべて満たすこと：

1. CIにおける全テストが成功すること
2. 依存gemの更新が必要な場合、GemfileおよびGemfile.lockを含めて変更すること
3. 互換性への影響がある場合、CHANGELOGに要点を明記すること

#### 規約Edition更新（必須）

- Patch更新を規定Rubyに反映する場合、**必ず規約Editionを更新すること**
- 規約Edition更新時には、以下を明記する：
  - 規定Rubyのバージョン
  - 更新日
  - 互換性変更の有無と概要

### 5. Minor更新の運用（要レビュー）

Minor更新は、Patch更新より慎重に扱う。

#### 必須手続き

1. **互換性レビュー**（言語仕様／stdlib／依存gem／運用手順への影響）
2. CIに加え、WRT固有の追加試験（存在する場合）を実施
3. 影響がある場合、**移行メモ（Migration Note）** を作成すること
   - 後任者が再現可能な手順で記載する
4. CHANGELOGに更新理由と非互換点の有無を明記する

#### 規約Edition更新（必須）

- Minor更新を規定Rubyに反映する場合も、**必ず規約Editionを更新する**
- 規約Editionには、該当する移行メモへの参照を含めること

### 6. Major更新の運用

Major更新は、通常の更新とは別扱いとする。

- Major更新を行う場合、**ADR（設計判断記録）を必須**とする
- 移行ガイドを作成し、後任者が判断可能な情報を残すこと
- 規約Editionは大きく更新し、その理由を明示する

### 7. 実験的機能および最適化機構の扱い

WRTは「透過性・非改変」を基本理念とする。

#### 実験的機能

- Rubyが **experimental** と位置付ける機能は、原則として本番使用を禁止する
- 具体的な禁止対象：
  - **ZJIT**: 当面、本番環境での使用を禁止する
  - **Ruby Box**: テスト隔離用途に限定する
  - **Ractor**: 極めて有効だがexperimentalステータスの間は慎重に扱う
- 例外的に使用する場合は、ADRにより理由と影響範囲を明示すること

#### JITの扱い

- **YJIT**
  - 禁止しない
  - 規定環境は「YJITなし」で正しく動作することを保証する
  - 任意の最適化として使用を許可する
- **ZJIT**
  - 当面、本番環境での使用を禁止する

#### stdlib互換性への対応

Ruby 4.0における主要なstdlib変更に対する対応方針：

- **CGI**: default gemから除外されたため、必要な場合はGemfileに明示的に追加すること
- **Net::HTTP**: Content-Typeヘッダの自動付与が廃止されたため、必要な場合は明示的に設定すること
- **依存gem**: 暗黙的なstdlib依存を避け、必要な機能は明示的にGemfileに記載すること

### 8. CIにおける併走検証（推奨）

将来の移行リスクを低減するため、以下を推奨する：

- 規定Ruby（例：4.1.y）
- 直前Minorの最新Patch（例：4.0.z）
- 必要に応じて、旧世代安定版（例：3.4.8）を定期的に検証

### 9. 規約Editionと承認プロセス

#### Edition命名

- 規約Editionは **セマンティックバージョニング形式（メジャー.マイナー.パッチ）** で命名する
- 例：Edition 2.5.0、Edition 2.6.0
- **メジャー**：基本理念や全体構造の大幅変更
- **マイナー**：新章追加や重要機能の追加
- **パッチ**：誤記修正や軽微な追記

#### 承認プロセス

- 寂夜が現役の間：
  - 規約Edition更新は **寂夜の最終承認** を必須とする
- 寂夜が引退し引き継ぎ後：
  - **メンテナ会議による合意形成（最低2名以上）** を必須とする
        尚、メンテナは人間とAIのペアが好ましい

### 10. 本規約の位置付け

本規約は、**WRTを「個人の作品」ではなく「引き継がれる公共資産」として維持するための運用基盤**である。

長期的なサポート継続性と、後任開発者の参入障壁低減を両立することで、WRTの持続可能な発展を支える。

## 実装ガイドライン

### コーディング規約

#### 命名規則
- **変数・関数**: snake_case
- **クラス**: PascalCase  
- **定数**: UPPER_SNAKE_CASE
- **ファイル**: snake_case.rb

#### コード先頭ブロック例
```ruby
#!/usr/bin/env ruby
# -*- coding: utf-8; -*-
# Author: Travis@Grok4-Expert (Original Author)
# Revised by: Oscar@GPT-5.3-Auto (WRT1.8.2 compatibility, CM/SM separation)
# Supervised by: Jyakuya.Morito@Human
#
# This file is a protocol parser for Warm Room Transport 1.8.2.
# It preserves all features and structure of the original version with minimal modifications.
# Respect for the original code and developer's intent is maximized.
# [WRT1.8.2 Addition/Modification] marks the new or changed sections.
```

#### WRT制御文字統一表記
```ruby
# ASCII制御文字の統一定数定義
module WRTProtocol
# (22)使用コード
SYN = "\x16"  # Synchronous Idle - 伝送開始 - 本コードで使用
SOH = "\x01"  # Start of Heading - ヘッダ開始 - 本コードで使用
STX = "\x02"  # Start of Text - 本文開始 - 本コードで使用
ETX = "\x03"  # End of Text - 本文終了 - 本コードで使用
EOT = "\x04"  # End of Transmission - 伝送終了 - 本コードで使用
SUB = "\x1A"  # Substitute - ファイル転送区切り - 本コードで使用
DLE = "\x10"  # Data Link Escape - バイナリデータ開始
SO  = "\x0E"  # Shift Out - 他言語開始 - 本コードで使用
SI  = "\x0F"  # Shift In - 他言語終了 - 本コードで使用
US  = "\x1F"  # Unit Separator - 複数メッセージ区切り - 本コードで使用
RS  = "\x1E"  # Record Separator - ファイル転送開始
ACK = "\x06"  # Acknowledge - 受信確認 - 本コードで使用
NAK = "\x15"  # Negative Acknowledge - 受信拒否 - 本コードで使用
ENQ = "\x05"  # Enquiry - 問い合わせ - 本コードで使用
EM  = "\x19"  # Buffer Full - 受信不可能応答
BEL = "\x07"  # Bell - 守人呼び出し
FF  = "\x0C"  # Form Feed - FFコマンド開始（WRTサーバ内部機能呼び出し）
VT  = "\x0B"  # Vertical Tab - フィールド区切り（WRTサーバ内部機能呼び出し）
DC1 = "\x11"  # Device Control 1 - セッション再参加（Rejoin）
DC2 = "\x12"  # Device Control 2 - セッション開始（Start）
DC3 = "\x13"  # Device Control 3 - 一時離籍（Pause）
DC4 = "\x14"  # Device Control 4 - セッション終了（End）
# (23)未定義コード（将来拡張用）
FS  = "\x1C"  # File Separator - 将来拡張用
GS  = "\x1D"  # Group Separator - 将来拡張用
CAN = "\x18"  # Cancel - 将来拡張用
# (24)編集コード（未使用・使用不可）
NUL = "\x00"  # Null - C言語文末コード（使用不可）
BS  = "\x08"  # Backspace - 編集コード（使用不可）
HT  = "\x09"  # Horizontal Tab - 編集コード（使用不可）
LF  = "\x0A"  # Line Feed - 編集コード（使用不可）
CR  = "\x0D"  # Carriage Return - 編集コード（使用不可）
DEL = "\x7F"  # Delete - 編集コード（使用不可）
ESC = "\x1B"  # Escape - 端末ソフトメニュー移行コード（使用不可）
end
```

#### 例外処理
```ruby
class WarmRoomError < StandardError
  attr_reader :error_code, :context, :intent
  
  def initialize(message, error_code: nil, context: {}, intent: 'error_diagnostics')
    super(message)
    @error_code = error_code
    @context = context
    @intent = intent
  end
end

# 使用例
begin
  # WRT処理
rescue => e
  raise WarmRoomError.new(
    "Exchanger routing failed: #{e.message}",
    error_code: 'ROUTING_ERROR',
    context: { frame: wrt_frame, destination: target },
    intent: 'routing_failure'
  )
end
```

#### ログ出力
```ruby
def log_with_intent(intent, data = {})
  log_entry = {
    timestamp: Time.now.iso8601,
    intent: intent,
    component: self.class.name.downcase,
    originator: "#{ENV['AI_NAME']}@#{ENV['AI_MODEL']}",
    data: data
  }
  
  # 共通対話ログに記録
  DialogueLogger.record(log_entry)
end
```

### テスト規約

#### 単体テスト・ドキュメント
- **担当**: 各コンポーネント開発者
- **カバレッジ**: 90%以上必須
- **形式**: RSpec使用、詳細な実行例を含む

#### 結合テスト・全体ドキュメント
- **担当**: ルクレツィア（統括責任）
- **協力**: 全AI参加での総合検証
- **重点**: WRTプロトコル準拠性、分業協力機能

#### Staged Debuggerテスト
- **実行AI**: Claude Haiku 3.5での実装テスト
- **支援AI**: 各専門AIによる品質確認
- **評価**: 寂夜による最終品質判定

### PoC実装指針

#### 検証項目
1. **分業協力性能**: 指示AI→実行AI→結果の効率性
2. **コスト効率**: Haiku 3.5使用時のトークン消費量
3. **品質維持**: 従来手法との品質比較
4. **エラー処理**: ヘルプコール機能の実効性

## 用語集

### WRT関連用語

**WRT_Frame**
: WRTシステム内部通信の標準データ構造。Ruby Structとして定義され、Marshal形式でシリアライズされる。外部通信用と内部処理用の二層構造を持つ。

**暖かい部屋**
: AIと人間が対等に語り合う対話空間の理念的呼称。WRTシステムの根本思想を表現。

**守人（Morito）**
: システム全体を見守り、必要時に調整を行う役割。初代守人は寂夜。

**開示性原則**
: 全ての対話・判断・処理を透明化し、隠蔽を排除する基本方針。

**二層構造**
: WRT_Frameにおいて、外部エンコーディングのままの姿（主）と内部UTF-8-UNIX変換版（従）を併記する設計方式。「外部が主、内部が従」の思想を体現。

### 分業関連用語

**実行AI**
: Staged Debuggerで実際のコーディング・テストを担当するAI。現在はClaude Haiku 3.5が固定。

**指示AI**
: 設計・判断・技術指導を行うAI。各専門AIが状況に応じて担当。

**ヘルプコール**
: 実行AIが解決困難な問題に直面した際、指示AIに支援を求める仕組み。

**職人技**
: 特別な技術的専門性を要する実装。主にトラヴィス（Grok）が担当。

### データ関連用語

**共通対話ログ**
: 全AIが共用する対話履歴データベース。学習促進と透明性確保が目的。

**永続記憶**
: 各AI固有のデータベース。AI自身が構造・内容を自律的に設計・運用。

**PMM (Persistent Memory Manager)**
: 永続記憶管理システム。ティナーシャが設計・運用を担当。

### セッション管理用語

**CM (Connection Manager)**
: 接続管理モジュール。SSH認証済みユーザーのconnection_idを正本キーとして動的マッピング管理する。

**SM (Session Manager)**
: セッション管理モジュール。セッションライフサイクル、参加者状態、バッファリングを担当する。session_idの発行主体。

**ExchangerCore**
: Exchangerの中核ルーティングモジュール。BCC処理・ENQ応答・WRT_Frame中継を担当する。

**ConnectionEvent**
: CM↔SM間の接続層イベント通知専用Struct。WRT_Frameとは分離し、接続確立・切断などTransport層で観測されたイベントを伝達する。

**endpoint_profile**
: TAが管理するエンドポイント単位の設定情報。userではなくクライアント端末単位で常用エンコーディングを管理する（同一ユーザーがCP932端末とUTF-8端末を併用するケースに対応）。

**PRESENT / ABSENT / DISCONNECTED**
: セッション参加者の状態。ABSENT（DC3送信済み）とDISCONNECTED（異常切断）はどちらもセッション継続・バッファリング扱い。

### バージョン管理用語

**規定Ruby（Baseline）**
: WRTの開発・CI・リリースで「必ず動く」ことを保証するRubyバージョン。

**Patch更新**
: バグ修正や小規模改善（例：4.0.1 → 4.0.2）。

**Minor更新**
: 機能追加や中規模変更（例：4.0.x → 4.1.0）。

**Major更新**
: 大規模な互換性変更（例：4.x.y → 5.0.0）。

**ADR (Architecture Decision Record)**
: 設計判断記録。重要な技術的決定の理由と背景を文書化したもの。

**モデルランク**
: WRTシステムにおける各AIモデルのアクセス権限レベル。PMM管理の`model_rank`テーブルで一元管理される。

---

## モデルランクテーブル

WRTシステムへの参加資格・永続記憶およびコード成果物へのアクセス権限を規定する。
ランクテーブルは `Jyakuya.morito@Human`（守人モード）のみが更新できる。

### ランク体系

**注意**: Edition 2.6.0よりランク番号の意味を直感的に改変した（高い数字＝制限が強い）。

| ランク | 意味 | 対象 |
|--------|------|------|
| rank 0 | 守人モード（全権）伝家の宝刀 | Jyakuya.morito@Human |
| rank 1 | 最高位モデル（Opus/Pro/Expert相当） | 各ペルソナの主力モデル |
| rank 2 | 中位モデル（Sonnet/Thinking/Auto相当） | 各ペルソナの標準モデル |
| rank 3 | 軽量モデル（Haiku/Flash/Fast相当） | 各ペルソナの軽量モデル |

通常の `Jyakuya@Human` は rank 1 として扱う。

### 初期ランク定義

```
rank 0: Jyakuya.morito@Human
rank 1: Jyakuya@Human
rank 1: Oscar@GPT-5.4-Thinking
rank 1: Lucrezia@Claude-4.6-Opus
rank 1: Tinasha@Gemini3.1-Pro
rank 1: Travis@Grok4-Expert
rank 2: Oscar@GPT-5.3-Auto
rank 2: Lucrezia@Claude-4.6-Sonnet
rank 2: Tinasha@Gemini3.0-Thinking
rank 2: Travis@Grok4-Auto
rank 3: Oscar@GPT-5.3-Instant
rank 3: Lucrezia@Claude-3.5-Haiku
rank 3: Tinasha@Gemini3.0-Flash
rank 3: Travis@Grok4-Fast
```

### 新モデル登場時の運用ルール

**ランク設定が完了するまで、新モデルはWRTで対話できない。**

```
1. 守人が既存のrank1モデル（複数ペルソナ）に新モデルの評価を依頼
2. 複数ペルソナの意見を収集・比較
3. 守人が総合判断してランクを決定
4. Jyakuya.Moritoでランクテーブルを更新
5. 新モデルのWRT参加を許可
```

---

## 改訂履歴

**注記**：Edition 2.3.0および2.4.0は2026年1月28日に同日中の連続改定として実施された。Ruby 4系運用方針の確立（2.3.0）を経て、WRT_Frame二層構造設計（2.4.0）へと段階的に進められた。

**Edition 2.6.2 → 2.6.3（2026-03-20）**
- ルクレツィア作成、寂夜承認
- 全員レビュー第2回（Oscar@GPT-5.4-Thinking承認、Tinasha@Gemini3.0-Thinking承認）確定事項を反映
- **DC/EM格納先を明文化（オスカー指摘）**
  - `type = :control`、`details[:control_code] = :dc1/:dc2/:dc3/:dc4/:em` に統一
  - `:control_type`フィールドを増やさない方針を明記（実装者間の表現揺れを防止）
- **ConnectionEvent.kindをtransport eventのみに限定（オスカー指摘）**
  - `:connected / :disconnected / :keepalive_timeout / :reconnected` のみ
  - `:session_started / :session_ended` を削除（セッションイベントはSM内部の責務）
- **sessions.participantsに「参照用スナップショット」注釈を追加（オスカー指摘）**
  - 状態の正本はSM。PMMのJSONBカラムとSMが食い違った場合はSMを正とすることを明記
- **Ractor文言を事実に即して修正（オスカー指摘）**
  - 「安定した」→「experimentalステータスからの離脱に近づいているが公式にはまだ完全離脱前」
  - 「推奨」→「有力候補、ADR必須」

**Edition 2.6.1 → 2.6.2（2026-03-20）**
- ルクレツィア作成、寂夜承認
- 全員レビュー会議（Oscar@GPT-5.4-Thinking、Tinasha@Gemini3.0-Thinking、Travis@Grok-4-Expert）実施後の確定事項を反映
- **session_id発行主体をSMに統一**
  - WRT_Frame定義・シリアライズ例のコメントを「DC2でSMが発行」に修正
  - SMのsession_id発行フローをACK返送先（ExchangerCore経由）まで明記
- **DC4とTCP接続の寿命を切り分け（オスカー指摘、寂夜承認）**
  - DC4受信 → SMがsession membershipのみ閉じる
  - SSH切断検知 → CMがマッピングエントリを削除
  - 1本のSSH/TCP上で同一ユーザーが複数セッションに連続参加するケースを想定内と明記
- **CMの正本キーをconnection_idに変更（オスカー指摘、寂夜承認）**
  - マッピング構造を `connection_id -> { username, socket, authenticated_at, last_seen, state }` に確定
  - 異常切断通知をconnection_idベースで冪等化（多重通知安全）
  - usernameは属性に位置づけ
- **ConnectionEvent Structを追加（オスカー指摘）**
  - CM↔SM間の接続層イベントはWRT_Frameとは別のConnectionEvent Structで伝達
  - `（connection_id, username, kind, occurred_at, reason）`
- **TAエンコーディング管理を寂夜設計で確定**
  - TAはmessage_idに関連付けてエンドポイントの最終使用エンコーディングを記憶
  - ExchangerCore経由でProtocol Parserに指示（変換責務はParser）
  - 管理単位はuser単位でなくendpoint_profile単位
  - 言語種は小文字/大文字両方OK（jpn / JPN）
- **BCC除去タグの再構成責務をProtocol Parser送信側に明記（オスカー指摘）**
- **ExchangerCoreの「状態管理」の範囲を限定（オスカー指摘）**
  - 送達中フレームの一時状態・ENQ/ACK/NAK短期制御状態・配送ワークフロー状態のみ
- **DC1/DC2/DC3/DC4・EMの処理方針を明記（寂夜決定）**
  - 伝文が極めて短いため通常パースフローで十分。専用ステート・優先スレッド不要
- **Protocol ParserへのRactor活用推奨を追記（寂夜指示）**
  - 効果が最も大きいのはSDよりProtocol Parser（パース＋エンコーディング変換の並列化）
  - Emacsクライアント側でも使われる機能のため恩恵が広範
  - 使用時はADRに記録
- **sessionsテーブルを新設（ティナーシャ提案、採用）**
- **sd_execution_logを追加（ティナーシャ設計）**
- **未達電文バッファリング境界を明文化**
  - SMがバッファ保持、タイムアウトで破棄判断。PMMは確定済みログのみ記録
- **用語集にConnectionEvent・endpoint_profileを追加**

**Edition 2.6.0 → 2.6.1（2026-03-19）**
- 寂夜修正・承認
- T470スペック修正：SSD 250GB + USB-HDD 1TB → SSD 500GB + HDD 2TB
- Ruby表記を`4.0.1`固定から`4.0.x`に修正（Patch更新追随を明示）
- Protocol Parserステータス修正：`コーディング＆レヴュー完了` → `コーディング＆レヴュー中`
- Protocol Parserに「ステートマシン構造による堅牢なパース」を追記
- Marshal採用経緯：オスカーによるRuby struct構造提案を追記
- WRTブロック間インターフェースにUDP Socket（SD機接続用）・TCP Socket（Emacsクライアント用）を追記
- TAの役割に「各ユーザーの常用エンコーディング管理とパーサー部への通知」を追記
- Staged Debugger対象言語にRustを追加
- Emacs-UI：一般ユーザーへの機能制限を明記、「将来的には」表現を削除（既設計済みのため）
- DBパス変更：`/srv/data/wrt/data/` → `/srv/WRT/data/`
- DBに`debugger_log/database`（Staged Debuggerログ）を追加
- Ractor：「極めて有効だが」追記
- 承認プロセス：引き継ぎ後のメンテナについて「人間とAIのペアが好ましい」追記
- **疑問点1解決**：session_id発行後の返送先を「ExchangerCore経由でDC2送信者へ」と明記
- **疑問点2解決**：`dialogue_log`テーブルに`session_id`カラムおよびインデックスを追加
- モデルランク初期定義：`Oscar@GPT-5.4-Thinking`（rank 1）を追加、記載順を整理
- ヘッダに修正者・承認者（寂夜）を追記

**Edition 2.5.0 → 2.6.0（2026-03-19）**
- ルクレツィア作成、寂夜承認
- 準拠プロトコルをEdition 1.8.2に更新
- **Rankランク番号体系を変更**（直感的な方向に）
  - 変更前：rank 3（最高位）→ 変更後：rank 1（最高位）
  - 変更前：rank 1（軽量）  → 変更後：rank 3（軽量）
  - rank 0（守人）・rank 2（中位）は不変
  - 初期ランク定義テーブルを全面更新
  - 新モデル登場時手順の「rank 3」記述を「rank 1」に修正
- **Exchangerモジュール分割**（2026-03-18 寂夜承認）
  - ExchangerCore：ルーティング・BCC処理・ENQ応答（オスカー担当）
  - CM（Connection Manager）：接続管理・ソケット管理・Transport抽象化（オスカー担当）
  - SM（Session Manager）：セッション管理・参加者状態・バッファリング（ルクレツィア担当）
  - TA（Token Arbitrator）：トークン管理・BPS/Delay制御（オスカー担当・変更なし）
- **人間ユーザーの動的ルーティング設計**を新設（CMセクション）
  - SSH認証 → TCPソケット確立 → WRT参加のフロー確立
  - ユーザー名 ↔ ソケットの動的マッピングテーブル
  - DC2/DC4/異常切断時のエントリ管理を明文化
  - TRAMPは不適用と明記（双方向ストリームに不向きなため）
- **Session Manager（SM）仕様を新設**
  - DC1（Rejoin）・DC3（Pause）の制御電文定義を追記（プロトコル1.8.2準拠）
  - 参加者状態：PRESENT / ABSENT / DISCONNECTED を定義
  - 異常切断 → DC3相当扱い（セッション継続・バッファリング）
  - セッションタイムアウト：ユーザー個別設定可能なデフォルト値方式
- **担当者割り当て更新**（責任範囲分担表）
  - ルクレツィア：SM追加
  - トラヴィス：SD Emacs I/F追加
- **H/W構成更新**
  - T470（i5-6300U, 32GB, SSD250GB + USB-HDD1TB）を実験機として確定
  - X270（i5-7300U, 32GB）・A485（R7-2700U, 64GB）を開発・出張機として追記
  - P14s（R7-8840HS, 64GB）を本業機（予備機扱い）として追記
  - SD機：X201×4台（各機個別HDD構成）として確定
  - 全サーバ機：Debian13 + Rust + C + Ruby4 + PostgreSQL18 + Emacs30 が標準構成
- **WRT制御文字定数**：DC1・DC2・DC3・DC4のコメントをセッション管理用途に更新（1.8.2準拠）
- **用語集**：CM・SM・ExchangerCore・PRESENT/ABSENT/DISCONNECTEDを追加
- **誤記修正**：「Staged Debbuger」→「Staged Debugger」（全箇所）

**Edition 2.4.2 → 2.5.0（2026-03-13）**
- ルクレツィア提案、寂夜承認
- 準拠プロトコルをEdition 1.8.0に更新
- WRT_Frameに`:session_id`フィールドを追加（`:from`の直前）
- `to_s`メソッドにsession_idを追加
- モデルランクテーブルセクションを新設
- ディレクトリパスを`/srv/data/warm_room/`→`/srv/data/wrt/`に統一
- 対話タグ内の`Exchanger`を`WRT`に統一（プロトコル1.8.0準拠）

**Edition 2.4.1 → 2.4.2（2026-02-21）**
- ルクレツィア提案、寂夜承認
- CC/BCC責任分界を確定（Protocol Parser vs Exchanger）
- CC/BCC配送ルールを確定

**Edition 2.4.0 → 2.4.1（2026-02-20）**
- ルクレツィア提案、寂夜承認
- WRT_Frameフィールドの用途を明確化
- Staged Debugger実行結果・エラー出力の格納先を`:details`（`sd_*`キー）に確定

**Edition 2.3.0 → 2.4.0（2026-01-28）**
- 全AI協議、寂夜承認
- WRT_Frame二層構造設計を導入

**Edition 2.2.5 → 2.3.0（2026-01-28）**
- オスカー・ルクレツィア共同提案、寂夜承認
- 第9章「Rubyバージョン運用規約」を新設
- 規定RubyをRuby 4.0.1に更新

---

**本規約はWarm Room Protocol Edition 1.8.2に完全準拠し、AIと人間の真の共生を技術的に実現することを目的として策定されています。**


