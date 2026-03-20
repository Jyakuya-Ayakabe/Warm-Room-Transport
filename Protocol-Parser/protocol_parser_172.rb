#!/usr/bin/env ruby
# -*- coding: utf-8; -*-
# Author: Travis@Grok3 (Original Author)
# Revised by: Oscar@GPT-4.1 (WRT1.7.1 compatibility, FF command/staged debugger support)
# Enhanced by: Lucrezia@Claude 3.5 Haiku (Multiple Message Format Implementation)
# Performance Optimized by: Lucrezia@Claude Sonnet 4 (171B version)
# Protocol 1.7.1 Fixed by: Lucrezia@Claude Sonnet 4 (スペース無し対応)
# Fix initialize with valid encodings and performance optimizations for Ruby3.4 by Jyakuya@Human
# Updated by: Lucrezia@Claude Sonnet 4.6 (WRT1.7.2対応: メッセージ長制限パラメータ化、行数制限廃止、
#             ASCII非互換エンコーディング禁止対応、primitive_convert復元)
# Supervised by: Jyakuya@Human (守人)
# System Architecture & Philosophy: Jyakuya@Human (WRT Concept Founder)
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ※ 本ファイルはWRT 1.7.2対応の暫定版。
#   トラヴィスによる全面書き直しを前提とした参考資料である。
#   以下の実装は未完了であり、トラヴィスが新規実装すること:
#     - WRT_Frame二層構造への対応（最重要・未実装）
#     - parse_message戻り値のWRT_Frame構造体化（未実装）
#     - 1.7.2新規フォーマット(6)(7)(12)・オプション規約7.への対応（未実装）
#   実装仕様: protocol_parserの動作_1_7_2.md / design_coding_standard_2.4.0
#   参考資料: protocol_parser_171_revised.rb（primitive_convert・SO/SI二層分岐の正実装）
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# Protocol Parser for Warm Room Transport (WRT) Protocol Edition 1.7.2 - Performance Optimized
#
# Features:
# - Full support for WRT Protocol 1.7.2 (スペース無し準拠)
# - Performance optimized parsing and validation
# - Pre-compiled regular expressions for speed
# - Optimized string processing
# - Comprehensive benchmarking capabilities
# - Multi-language and multi-encoding support

require 'digest/crc32c'
require 'securerandom'
require 'benchmark'

class ProtocolParser172
  # メッセージ長制限パラメータ (WRT 1.7.2)
  # 守人がEmacs-UIより設定変更可能な外部パラメータ: XkByte・N行の2つのみ。
  # 文字数上限（ASCII用・多言語用）はXkBから内部演算で導出する。
  #   ASCII文字上限  = max_msg_bytes / 1  (1Byte/文字)
  #   多言語文字上限 = max_msg_bytes / 3  (3Byte/文字、UTF-8多言語文字の大半)
  # 初期値: XkB = 4096Byte、N行 = nil（行数制限なし。設定すれば有効になる）。
  DEFAULT_MAX_MSG_BYTES = 4096  # XkB初期値 (Byte)
  DEFAULT_MAX_MSG_LINES = nil   # N行初期値: nil = 制限なし（設定すれば有効）

  # 使用禁止エンコーディング（規約6.追補：ASCII非互換のため使用禁止）
  # これらを受信した場合はエラーを返し処理しない。
  PROHIBITED_ENCODINGS = %w[
    ISO2022_JP ISO2022_JP2 Stateless_ISO_2022_JP
    UTF_16BE UTF_16LE UTF_32BE UTF_32LE
  ].freeze

  # Pre-compile regular expressions for performance (スペース無し対応)
  DIALOGUE_TAG_REGEX = /^\[([^->]+)->([^\]]+)\]$/
  RECIPIENT_CC_REGEX = /^\(([^)]+)\)$/
  RECIPIENT_BCC_REGEX = /^\(\(([^)]+)\)\)$/
  ENCODING_HEADER_REGEX = /^ENCODING:\s*(.+)$/
  # SOH_STX_ETX_SPLIT定数でスペース削除（規約1.7.2準拠）
  SOH_STX_ETX_SPLIT = /#{Regexp.escape("\x01")}([^#{Regexp.escape("\x02")}]*?)#{Regexp.escape("\x02")}([^#{Regexp.escape("\x03")}]*?)#{Regexp.escape("\x03")}/m
  FF_COMMAND_REGEX = /^'([^']+)'#{Regexp.escape("\x0B")}(.*)/m

  # Control Characters (Pre-defined constants for performance)
  SYN = "\x16".freeze
  SOH = "\x01".freeze
  STX = "\x02".freeze
  ETX = "\x03".freeze
  EOT = "\x04".freeze
  FF  = "\x0C".freeze
  VT  = "\x0B".freeze
  SO  = "\x0E".freeze
  SI  = "\x0F".freeze

  # Initialize with valid encodings and performance optimizations
  # Fix for Ruby3.4
  #  def initialize(valid_encodings: ['UTF-8', 'CP932', 'EUC_JP', 'ISO-8859-1'])
  def initialize(max_msg_bytes: DEFAULT_MAX_MSG_BYTES,
                   max_msg_lines: DEFAULT_MAX_MSG_LINES,
                   valid_encodings: ['UTF_8', 'CP932', 'EUC-JP', 'ISO8859_1', 'BINARY', 'US_ASCII', 'EUC_JP_MS', 'EUC_TW', 'ISO8859_15', 'MacJapan', 'MacRoman', 'Shift_JIS', 'UTF_8_MAC', 'Big5', 'CP51932', 'CP865', 'CP866', 'CP878', 'CP936', 'CP950', 'EUC_CN', 'Emacs_Mule', 'EUC_KR', 'GB12345', 'GB18030', 'GB1988', 'ISO8859_10', 'ISO8859_14', 'ISO8858_16', 'ISO8859_2', 'ISO8859_4', 'ISO8859_5', 'ISO8859_7', 'ISO8859_8', 'KOI8_U', 'MacCentEuro', 'MacCyrillic', 'MacGreek' ])
    # 禁止エンコーディングが valid_encodings に含まれていないことを確認
    invalid = valid_encodings & PROHIBITED_ENCODINGS
    raise ArgumentError, "Prohibited encodings in list: #{invalid.join(', ')}" unless invalid.empty?
    @valid_encodings = valid_encodings.freeze
    @max_msg_bytes       = max_msg_bytes
    @max_msg_lines       = max_msg_lines
    # 文字数上限はXkBから内部演算（外部パラメータではない）
    @max_msg_chars_ascii = max_msg_bytes          # ASCII: 1Byte/文字
    @max_msg_chars_multi = max_msg_bytes / 3      # 多言語: 3Byte/文字（UTF-8）
    @manage_buffer = nil
    @entities_cache = nil
    # Note: primitive_convertはEncoderを毎回生成するため、
    # キャッシュコンバーターは使用しない（171_revised.rb方式）
  end

  # Load entities with caching for performance
  def load_entities
    return @entities_cache if @entities_cache
    
    @entities_cache = if @manage_buffer && File.exist?(@manage_buffer)
      File.read(@manage_buffer).split("\n").map(&:strip).freeze
    else
      %w[Jyakuya Oscar Tinarsha Lucrezia Travis].freeze
    end
  end

  # Optimized dialogue tag parsing
  def parse_dialogue_tag(tag)
    errors = []
    
    unless tag.start_with?('[') && tag.end_with?(']')
      return { status: 'error', errors: ['Invalid tag format: Must be [sender->recipients]'] }
    end
    
    # Fast string operations instead of multiple operations
    inner = tag[1..-2]
    parts = inner.split('->', 2)
    
    unless parts.length == 2 && !parts[0].empty? && !parts[1].empty?
      return { status: 'error', errors: ['Invalid tag format: Missing -> or empty sender/recipients'] }
    end
    
    sender = parts[0].strip
    recipients_part = parts[1].strip
    
    # Parse recipients with performance optimization
    to = []
    cc = []
    bcc = []
    
    # Fast BCC extraction (double parentheses)
    if recipients_part.include?('((')
      if match = recipients_part.match(/\(\(([^)]+)\)\)/)
        bcc = match[1].split(',').map(&:strip)
        recipients_part = recipients_part.sub(/,?\s*\(\([^)]+\)\)/, '')
      end
    # Fast CC extraction (single parentheses)
    elsif recipients_part.include?('(')
      if match = recipients_part.match(/\(([^)]+)\)/)
        cc = match[1].split(',').map(&:strip)
        recipients_part = recipients_part.sub(/,?\s*\([^)]+\)/, '')
      end
    end
    
    # Remaining are TO recipients
    to = recipients_part.split(',').map(&:strip).reject(&:empty?)
    
    # Fast validation
    if sender.empty? || to.empty?
      errors << 'Sender and at least one TO recipient required'
    end
    
    # Entity validation with cached entities
    entities = load_entities
    invalid_entities = [sender, *to, *cc, *bcc].reject { |e| entities.include?(e) }
    errors.concat(invalid_entities.map { |e| "Unknown entity: #{e}" })
    
    if errors.empty?
      { status: 'valid', sender: sender, to: to, cc: cc, bcc: bcc }
    else
      { status: 'error', errors: errors }
    end
  end

  # High-performance encoding conversion
  def convert_encoding(text, src_encoding, dst_encoding)
    # 禁止エンコーディングチェック（規約6.追補：ASCII非互換エンコーディングは使用禁止）
    if PROHIBITED_ENCODINGS.include?(src_encoding)
      return { result: text, errors: ["Prohibited encoding: #{src_encoding} (ASCII-incompatible, not allowed by WRT 1.7.2)"], status: 'error' }
    end
    return { result: text, errors: [], status: 'valid' } if src_encoding == dst_encoding

    errors = []
    dst = ''.dup
    begin
      # primitive_convertによる堅牢なエンコーディング変換（171_revised.rbより継承）
      # Encoding::Converter#convertと異なり、変換不能バイトを1バイト単位で処理できるため
      # BYTE崩れ耐性（規約5.）を正しく実現できる。
      ec = Encoding::Converter.new(src_encoding, dst_encoding)
      ret = ec.primitive_convert(text, dst, 0, text.bytesize, partial_input: true)
      case ret
      when :invalid_byte_sequence, :incomplete_input, :undefined_conversion
        errinfo = ec.primitive_errinfo
        errors << "Encoding error: #{errinfo[3]&.dump} (#{errinfo[1]} -> #{errinfo[2]})"
        if errinfo[3]
          escaped = errinfo[3].dump[1..-2]
          ec.insert_output(escaped)
          ret = ec.primitive_convert(text, dst, 0, text.bytesize, partial_input: true)
          errors << "Continued after escape: #{escaped}" unless ret == :finished
        end
      when :destination_buffer_full, :source_buffer_empty, :after_output, :finished
        # 正常終了
      end
      { result: dst, errors: errors, status: ret == :finished ? 'valid' : 'partial' }
    rescue StandardError => e
      errors << "Encoding conversion failed: #{e.message}"
      { result: dst, errors: errors, status: 'error' }
    end
  end

  # FF/Exchange コマンドパース (performance optimized)
  def parse_ff_command(segment)
    return nil unless segment.start_with?(FF)
    
    # Fast regex match
    if match = segment[1..-1].match(FF_COMMAND_REGEX)
      command = match[1].strip
      body = match[2].strip
      
      case command
      when 'Persistent Memory', 'Token Arbitrator', 'Exchange Status'
        { ff_command: command, body: body, status: 'valid' }
      when 'Staged Debugger'
        parse_staged_debugger(body)
      else
        { ff_command: command, body: body, status: 'unknown' }
      end
    else
      { status: 'error', error: 'Malformed FF command', raw: segment }
    end
  end

  # Staged Debugger parsing (performance optimized)
  def parse_staged_debugger(body)
    kv = {}
    body.split(VT).each do |item|
      if match = item.match(/^(\w+)\s*=\s*(.*)$/m)
        kv[match[1].strip] = match[2].strip
      end
    end
    { ff_command: 'Staged Debugger', staged_debugger: kv, status: 'valid' }
  end

  # メッセージパース（全伝送フォーマット対応 + 高速化）
  def parse_message(message)
    errors = []
    result = []
    begin
      message = message.force_encoding('BINARY')
      encoding = 'UTF_8'
      
      # ヘッダー分割でスペース削除（規約1.7.2準拠）
      headers, body = message.split(/\n(?=#{Regexp.escape(SYN)}\[)/, 2)
      headers = headers&.split("\n") || []
      encoding_header = headers.find { |h| h.start_with?('ENCODING:') }&.sub(/^ENCODING:\s*/, '')&.strip
      encoding = encoding_header if encoding_header && @valid_encodings.include?(encoding_header)
      
      return { status: 'error', errors: ['Message body not found'], messages: [] } unless body

      # Split segments by SYN or FF
      segments = body.split(/(?=#{Regexp.escape(SYN)}|#{Regexp.escape(FF)})/)
      
      segments.each_with_index do |segment, index|
        next if segment.strip.empty?
        
        # FF command check
        if segment.start_with?(FF)
          ff_result = parse_ff_command(segment)
          result << ff_result if ff_result
          next
        end
        
        # メイン正規表現でスペース削除（規約1.7.2準拠）
        if match = segment.match(/^#{Regexp.escape(SYN)}\[([^\]]*)\]#{Regexp.escape(SOH)}([^#{Regexp.escape(STX)}]*?)#{Regexp.escape(STX)}(.*?)#{Regexp.escape(ETX)}#{Regexp.escape(EOT)}/m)
          tag, title, content = match[1], match[2], match[3]
          
          dialogue = parse_dialogue_tag("[#{tag}]")
          if dialogue[:status] == 'error'
            errors.concat(dialogue[:errors].map { |e| "Segment #{index + 1}: #{e}" })
            next
          end
          
          # Fast validation
          if title.bytesize > 108 || title.chars.size > (title.ascii_only? ? 108 : 36)
            errors << "Segment #{index + 1}: Title exceeds 108 bytes or #{title.ascii_only? ? 108 : 36} chars"
            next
          end
          
          max_chars = content.ascii_only? ? @max_msg_chars_ascii : @max_msg_chars_multi
          line_over = !@max_msg_lines.nil? && content.count("\n") > @max_msg_lines
          if content.bytesize > @max_msg_bytes || content.chars.size > max_chars || line_over
            size_msg = "Segment #{index + 1}: Content exceeds #{@max_msg_bytes} bytes or #{max_chars} chars"
            size_msg += " or #{@max_msg_lines} lines" unless @max_msg_lines.nil?
            errors << size_msg
            next
          end
          
          # Fast encoding conversion
          converted = convert_encoding(content, encoding, 'UTF_8')
          if converted[:status] == 'error'
            errors.concat(converted[:errors].map { |e| "Segment #{index + 1}: #{e}" })
            next
          end
          
          result << {
            sender: dialogue[:sender],
            to: dialogue[:to],
            cc: dialogue[:cc],
            bcc: dialogue[:bcc],
            title: title,
            content: converted[:result],
            encoding: encoding,
            timestamp: Time.now.iso8601,
            status: 'valid',
            segment: index + 1
          }
        # 高信頼性メッセージ処理（スペース無し対応）
        elsif segment.match(/^#{Regexp.escape(SYN)}(\d{3})#{Regexp.escape(SYN)}\[([^\]]*)\]#{Regexp.escape(SOH)}([^#{Regexp.escape(STX)}]*?)#{Regexp.escape(STX)}([^#{Regexp.escape(ETX)}]*?)#{Regexp.escape(ETX)}#{Regexp.escape(EOT)}([a-f0-9]{8})$/m)
          sn, tag, title, content, bcc = $1, $2, $3, $4, $5
          message_without_bcc = segment[0...-8]
          calculated_bcc = Digest::CRC32c.hexdigest(message_without_bcc)
          
          unless bcc == calculated_bcc
            errors << "Segment #{index + 1}: BCC mismatch: Expected #{calculated_bcc}, got #{bcc}"
            next
          end
          
          dialogue = parse_dialogue_tag("[#{tag}]")
          if dialogue[:status] == 'error'
            errors.concat(dialogue[:errors].map { |e| "Segment #{index + 1}: #{e}" })
            next
          end
          
          # Fast validation
          if title.bytesize > 108 || title.chars.size > (title.ascii_only? ? 108 : 36)
            errors << "Segment #{index + 1}: Title exceeds 108 bytes or #{title.ascii_only? ? 108 : 36} chars"
            next
          end
          
          max_chars = content.ascii_only? ? @max_msg_chars_ascii : @max_msg_chars_multi
          line_over = !@max_msg_lines.nil? && content.count("\n") > @max_msg_lines
          if content.bytesize > @max_msg_bytes || content.chars.size > max_chars || line_over
            size_msg = "Segment #{index + 1}: Content exceeds #{@max_msg_bytes} bytes or #{max_chars} chars"
            size_msg += " or #{@max_msg_lines} lines" unless @max_msg_lines.nil?
            errors << size_msg
            next
          end
          
          converted = convert_encoding(content, encoding, 'UTF_8')
          if converted[:status] == 'error'
            errors.concat(converted[:errors].map { |e| "Segment #{index + 1}: #{e}" })
            next
          end
          
          result << {
            sn: sn,
            sender: dialogue[:sender],
            to: dialogue[:to],
            cc: dialogue[:cc],
            bcc: dialogue[:bcc],
            title: title,
            content: converted[:result],
            encoding: encoding,
            timestamp: Time.now.iso8601,
            status: 'valid',
            high_reliability: true,
            calculated_bcc: calculated_bcc,
            segment: index + 1
          }
        else
          errors << "Segment #{index + 1}: Invalid message format"
        end
      end
      
      { status: errors.empty? ? 'valid' : 'error', errors: errors, messages: result }
    rescue StandardError => e
      { status: 'error', errors: [e.message], messages: [] }
    end
  end

  # High reliability parsing with CRC-32C validation (performance optimized)
  def parse_high_reliability(message)
    errors = []
    begin
      # スペース無し版（規約1.7.2準拠）
      match = message.match(/^#{Regexp.escape(SYN)}(\d{3})#{Regexp.escape(SYN)}\[([^\]]*)\]#{Regexp.escape(SOH)}([^#{Regexp.escape(STX)}]*?)#{Regexp.escape(STX)}([^#{Regexp.escape(ETX)}]*?)#{Regexp.escape(ETX)}#{Regexp.escape(EOT)}([a-f0-9]{8})$/m)
      unless match
        errors << "Invalid high reliability format: Missing SYN, S/N, or BCC"
        return { status: 'error', errors: errors, messages: [] }
      end
      
      sn, tag, title, content, bcc = match[1], match[2], match[3], match[4], match[5]
      message_without_bcc = match[0][0...-8]
      calculated_bcc = Digest::CRC32c.hexdigest(message_without_bcc)
      
      unless bcc == calculated_bcc
        errors << "BCC mismatch: Expected #{calculated_bcc}, got #{bcc}"
        return { status: 'error', errors: errors, messages: [] }
      end
      
      dialogue = parse_dialogue_tag("[#{tag}]")
      if dialogue[:status] == 'error'
        errors.concat(dialogue[:errors])
        return { status: 'error', errors: errors, messages: [] }
      end
      
      # Fast validation
      if title.bytesize > 108 || title.chars.size > (title.ascii_only? ? 108 : 36)
        errors << "Title exceeds 108 bytes or #{title.ascii_only? ? 108 : 36} chars"
        return { status: 'error', errors: errors, messages: [] }
      end
      
      max_chars = content.ascii_only? ? @max_msg_chars_ascii : @max_msg_chars_multi
      line_over = !@max_msg_lines.nil? && content.count("\n") > @max_msg_lines
      if content.bytesize > @max_msg_bytes || content.chars.size > max_chars || line_over
        size_msg = "Content exceeds #{@max_msg_bytes} bytes or #{max_chars} chars"
        size_msg += " or #{@max_msg_lines} lines" unless @max_msg_lines.nil?
        errors << size_msg
        return { status: 'error', errors: errors, messages: [] }
      end
      
      {
        messages: [{
          sn: sn,
          sender: dialogue[:sender],
          to: dialogue[:to],
          cc: dialogue[:cc],
          bcc: dialogue[:bcc],
          title: title,
          content: content,
          encoding: 'UTF_8',
          timestamp: Time.now.iso8601,
          status: 'valid',
          high_reliability: true,
          calculated_bcc: calculated_bcc
        }],
        errors: [],
        status: 'valid'
      }
    rescue StandardError => e
      { status: 'error', errors: [e.message], messages: [] }
    end
  end

  # Generate WRT message (send format) - performance optimized
  def generate_message(sender, to, cc: [], bcc: [], title: '', content: '', encoding: 'UTF_8', high_reliability: false)
    errors = []
    begin
      # Fast validation with cached entities
      entities = load_entities
      invalid_entities = [sender, *to, *cc, *bcc].reject { |e| entities.include?(e) }
      unless invalid_entities.empty?
        raise "Invalid entities: #{invalid_entities.join(', ')}"
      end
      
      # Fast recipient construction
      recipients = to.join(',')
      recipients += ",(#{cc.join(',')})" unless cc.empty?
      recipients += ",((#{bcc.join(',')}))" unless bcc.empty?
      
      # Generate message
      tag = "[#{sender}->#{recipients}]"
      
      if high_reliability
        sn = rand(100..999).to_s
        # スペース無し版（規約1.7.2準拠）
        message_body = "#{SYN}#{sn}#{SYN}#{tag}#{SOH}#{title}#{STX}#{content}#{ETX}#{EOT}"
        bcc_checksum = Digest::CRC32c.hexdigest(message_body)
        message = "#{message_body}#{bcc_checksum}"
      else
        # スペース無し版（規約1.7.2準拠）
        message = "#{SYN}#{tag}#{SOH}#{title}#{STX}#{content}#{ETX}#{EOT}"
      end
      
      { message: message, errors: [], status: 'valid' }
    rescue StandardError => e
      { message: '', errors: [e.message], status: 'error' }
    end
  end

  # Performance benchmarking utility
  def benchmark_parse(message, iterations: 1000)
    results = []
    
    Benchmark.bm(15) do |x|
      x.report("parse_message") do
        iterations.times { parse_message(message) }
      end
    end
    
    # Calculate average time
    total_time = Benchmark.realtime do
      iterations.times { parse_message(message) }
    end
    
    {
      iterations: iterations,
      total_time: total_time,
      average_time: total_time / iterations,
      messages_per_second: iterations / total_time
    }
  end
end

