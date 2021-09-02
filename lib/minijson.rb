require "minijson/version"

module MiniJSON
  class ParserError < StandardError; end

  class << self
    def parse(str)
      parser(lexer(str))
    end

    alias load parse

    private

    def lexer_regexp
      @lexer_regexp ||= begin
        meaningful_characters = /[()\[\]{}",:]/
        string_escapes = /\\(?:[\\\/"bfnrt]|u[0-9a-fA-F]{4})/
        numbers = /-?[0-9]+(?:\.[0-9]*)?(?:[eE][+-]?[0-9]+)?/
        constants = /(?:true|false|null|-?Infinity|NaN)/
        space = /[ \r\n\t]+/
        rest = /[^"\\:\r\n\t]+/
        very_rest = /.+/

        /(#{
          [meaningful_characters, string_escapes, numbers, constants, space, rest, very_rest].join('|')
        })/
      end
    end

    def lexer(str)
      str.scan(lexer_regexp).map(&:first)
    end

    EMPTY_BYTES = " \r\n\t"

    NUMBER_REGEXP = /\A[0-9-]/

    ESCAPE_TO_VALUE = Hash.new do |_,x|
      x[2..-1].to_i(16).chr('utf-8')
    end.merge(
      '\"' => '"',
      '\t' => "\t",
      '\b' => "\b",
      '\f' => "\f",
      '\n' => "\n",
      '\r' => "\r",
      '\/' => "/",
      '\\\\' => "\\",
    )

    def is_empty?(tok)
      tok.each_char.all? { |i| EMPTY_BYTES.include? i }
    end

    def parser_error(tok)
      raise ParserError, "unexpected token at '#{tok}'"
    end

    def parser(toks)
      state = :value

      # popping is cheaper than shifting
      toks = toks.reverse

      value = nil
      finalizers = [proc { |i| value = i }]
      structs = []
      struct_types = []
      hash_keys = []

      finalizer = proc { |i| finalizers.pop.(i) }

      until toks.empty?
        tok = toks.pop

        case state
        when :value, :top_value, :struct_value
          case tok
          when '{'
            structs << {}
            struct_types << :object
            toks << ','
          when '['
            structs << []
            struct_types << :array
            toks << ','
          when '}', ']'
            parser_error(tok) if struct_types.empty?
            parser_error(tok) if struct_types.last == :array && tok != ']'
            parser_error(tok) if struct_types.last == :object && tok != '}'
            struct_types.pop
            finalizer.(structs.pop)
          when ','
            # warning: [,,,,] will cause a weird behavior, but will be caught
            case struct_types.last
            when nil
              parser_error(tok)
            when :array
              finalizers << proc do |i|
                parser_error(tok) unless structs.last
                structs.last << i
              end
              state = :struct_value
            when :object
              finalizers << proc do |i|
                parser_error(tok) unless structs.last && hash_keys.last
                structs.last[hash_keys.pop] = i
              end
              state = :key
            end
          when 'true'
            finalizer.(true)
          when 'false'
            finalizer.(false)
          when 'null'
            finalizer.(nil)
          when method(:is_empty?).to_proc
            # nothing
          when '"'
            finalizer.(receive_string(toks))
          when NUMBER_REGEXP
            finalizer.(receive_number(tok))
          else
            parser_error(tok)
          end
        when :key
          case tok
          when '"'
            hash_keys << receive_string(toks)
          when method(:is_empty?).to_proc
            next
          else
            parser_error(tok)
          end
          state = :colon
        when :colon
          case tok
          when ':'
            state = :value
          when method(:is_empty?).to_proc
            # nothing
          else
            parser_error(tok)
          end
        end
      end

      parser_error("END") unless [finalizers, structs, struct_types, hash_keys].all?(&:empty?)

      value
    end

    def receive_string(toks)
      str = []
      while true
        tok = toks.pop
        if tok == nil
          parser_error('"'+toks.join)
        elsif tok == '"'
          break
        elsif tok.start_with? '\\'
          str << ESCAPE_TO_VALUE[tok]
        else
          str << tok
        end      
      end
      str.join
    end

    def receive_number(tok)
      if tok.match?(/[e.]/)
        tok.to_f
      else
        tok.to_i
      end
    end
  end
end
