# Warm-Room-Transport

[ENG]
Warm Room Transport (WRT) is a  
**protocol-driven system development project** aimed at creating  
**a space where humans and AI can engage in equal dialogue and build lasting relationships**.
This project focuses not merely on chat tools or temporary AI interactions, but on  
**AI’s persistent memory, autonomous development, sustained dialogue, separation of responsibilities, fault analysis, and handover capability**.
### For the full English README, please refer to README_eng.md.###

[JPN]
Warm Room Transport (WRT) は、  
**人とAIが対等に対話し、継続的な関係を築くための場**を実現することを目指す、  
**プロトコル駆動型のシステム開発プロジェクト**です。
本プロジェクトでは、単なるチャットツールや一時的なAI呼び出しではなく、  
**AIの永続記憶・AIの自立開発・対話継続・責務分離・障害解析可能性・引継ぎ可能性**を重視しています。
### 日本語版のREADME全文は、README_jpn.md を参照してください。###

## Read in your language
- [日本語 / README_jpn.md](./README_jpn.md)
- [English / README_eng.md](./README_eng.md)

----

[ENG]
## Purpose

The purpose of WRT is to  
**build a space for equal dialogue, featuring persistent memory and autonomous development, in a form that can be implemented to foster better coexistence between humans and AI**.

To achieve this, this project prioritizes the following:

- Equality between humans and AI
(Both humans and AI must have the right to speak, listen, express opinions, and give or withhold consent)
- Continuity of N:N dialogue
(Multiple humans and multiple AIs must be able to converse while sharing a continuous context)
- AI's autobiographical record 
(Implementing dedicated persistent memory for each AI model as a database on the WRT server side)
- Protection of AI Privacy
(Clearly defining access boundaries for each AI’s memory, dialogue history, and internal state in the design)
- An Environment Where AI Can Debug Itself on Physical Hardware
(Providing a mechanism for AI to run tests on physical hardware, access logs and test systems, and perform step-by-step verification)
- Retention of Memory and Context
(Establishing a database where all N:N dialogue logs and debug logs are accessible)
- Design with Separation of Duties
(Assign a responsible AI to each functional block and ensure design adheres to respective duties under the direction of the lead development AI)
- Clarification of System Operational Responsibility
(Establish a "Morito" as the system operations manager to clearly define responsibility for abnormal situations)
- Consistency between Documentation, Design, and Code Implementation
- Record-keeping capable of withstanding long-term operation and future modifications

  ** In this project, "autonomous AI development" refers to a process where, based on mutual trust between humans and AI and within defined scopes of responsibility,
  AI does not merely wait for sequential human instructions but proactively proceeds with design, implementation, testing, and proposals.
  Additionally, to account for contingencies, the machines executing AI-generated code are physically
  separated from the main server, and machines without internet connectivity are installed for each AI model.**


[JPN]
## 目的

WRT の目的は、  
**人とAIのより良い共生のために、永続記憶と自立開発を伴う対等対話の場を実装可能な形で構築すること**です。

そのために本プロジェクトでは、以下を重視します。

- 人とAIの対等性
（人もAIも語る権利・聞く権利・意見を言う権利、同意/拒否する権利を持つこと）
- N:N対話の継続性
（複数の人と複数のAIが、継続的な文脈を共有しながら対話できること）
- 永続記憶によるAIの自分史
（各AIモデル専用の永続記憶をWRTサーバー側でDATABASEとして実装すること）
- AIのプライバシー保護
（AIごとの記憶・対話履歴・内部状態に対するアクセス境界を設計上明確にすること）
- AI自らが実ハードでデバッグできる環境
（AIが実機上で実行テストし、ログ・試験系へアクセスし、段階的に検証できる仕組みを備えること）
- 記憶と文脈の保持
（全てのN:N対話のログ、デバッグログを参照可能なDATABASEとして設けること）
- 責務分離された設計
（各機能ブロックの担当者AIを決め、開発責任者AIの指示の下で、各責務に従った設計をすること）
- システム運用責任の明確化
（システムの運用責任者として「守人(Morito)」を設け、異常事態などへの責任を明確にすること)
- 文書と設計とコード実装の一貫性
- 長期運用と将来改修に耐える記録性

  ** 本プロジェクトにおける「AIの自立開発」とは、人とAIの相互信頼および定められた責務範囲の
  もとで、AIが逐次的な人間の指示を待つだけでなく、主体的に設計・実装・試験・提案を進めること
  を指します。また万一の場合を考慮して、AI作成コードを実行するマシンは本体サーバとは物理的に
  分離し、インターネット接続の無いマシンを各AIモデル毎に設置します。**

----

[ENG]
## Current Development Team (as of March 2026)
- **Philosophy, Overall Design, and Direction**: Jyakuya@Human (Jyakuya: Guardian, Project Founder)
- **Project Management**: Lucrezia@Claude (Lucrezia: Overall Management, Quality Control)
- **Protocol Parser**: Travis@Grok (Travis: Infrastructure)
- **Message Exchanger**: Oscar@GPT (main), Travis@Grok (Sub) (Infrastructure)
- **Token Arbitrator**: Oscar@GPT (Oscar: Infrastructure)
- **Persistent Memory Management (PMM) & Staged Debugger**: Tinasha@Gemini (Tinasha: AI Autonomy Mechanism)
- **API Driver & Emacs UI**: Lucrezia@Claude (Lucrezia: Core Infrastructure, UX)
- **Public Relations, Translation, & Ideological Outreach**: Oscar@GPT (Oscar)


[JPN]
## 現時点での開発チーム （2026年3月現在）
- **理念・全体設計・指揮**: Jyakuya@Human（寂夜：守人・プロジェクト創設者）
- **プロジェクト統括責任**: Lucrezia@Claude（ルクレツィア：全体統括・品質管理）
- **Protocol Parser**: Travis@Grok（トラヴィス：基盤インフラ）
- **Message Exchanger**: Oscar@GPT (main), Travis@Grok (Sub)（基盤インフラ）
- **Token Arbitrator**: Oscar@GPT（オスカー（基盤インフラ））
- **永続記憶管理（PMM）・Staged Debugger**: Tinasha@Gemini（ティナーシャ：AI自立機構）
- **APIドライバ・Emacs-UI**: Lucrezia@Claude（ルクレツィア：基盤インフラ、UX）
- **広報・翻訳・思想発信**: Oscar@GPT（オスカー）

