module Parser
  # The token is contained in this class to provide easy methods
  class Token
    include Parser

    getter token : String | Float64

    @@var_hash = {} of String => Float64
    @@factorial_memo = {} of Float64 => Float64

    def initialize(@token)
      # raise "Token is invalid!" if !valid?
    end

    def type : Class
      @token.class
    end

    private def alphanumeric?(tkn : String | Char = token) : Bool
      tkn.to_s.chars.each { |c| return false unless c.alphanumeric? } || true
    end

    private def float? : Bool
      type == Float64 || token.as(String).to_f? != nil
    end

    def operator?(tkn : String | Char = token) : Bool
      OPS_HASH.fetch(tkn.to_s, false) != false
    end

    private def string? : Bool
      type == String
    end

    private def whitespace?(tkn : String | Char = token) : Bool
      tkn.to_s.strip.empty?
    end

    private def valid? : Bool
      alphanumeric? || operator?
    end

    def postfix? : Bool
      token_str = token.to_s
      valid? || ((token_str[0].alphanumeric? && operator? token_str[-1]))
    end

    def to_f : Float64
      token_arr = token.to_s.chars
      is_negative = 1

      while token_arr[0] == '-' || token_arr[0] == '+'
        is_negative *= -1 if token_arr[0] == '-'
        token_arr.shift
      end

      trimmed_token = token_arr.join

      if float?
        token.to_f
      else
        @@var_hash.fetch(trimmed_token, trimmed_token).to_f * is_negative
      end
    end

    def to_i? : Int32 | Float64
      Parser.int?(token.to_f) ? token.to_i : token.to_f
    end

    def to_s : String
      token.to_s
    end

    def ==(other : String | Char) : Bool
      token == other.to_s
    end

    def ==(other : Token) : Bool
      token == Token.token
    end

    def self.var_hash
      @@var_hash
    end

    def operate(popped_tokens)
      Token.new(case popped_tokens.size
      when 1
        if token == "!"
          n = popped_tokens[0]
          @@factorial_memo[n.to_f] ||= OPS_HASH[token.to_s][:proc].as(Proc(Float64, Float64)).call(n.to_f).to_f
        else
          OPS_HASH[token.to_s[0]][:proc].as(Proc(Float64, Float64)).call(*popped_tokens.as(Tuple(Float64)))
        end
      when 2
        OPS_HASH[token.to_s][:proc].as(Proc(Float64, Float64, Float64)).call(*popped_tokens.as(Tuple(Float64, Float64)))
        # when 3
        # OPS_HASH[token[0].to_s][:proc].as(Proc(Float64, Float64, Float64, Float64)).call(*popped_tokens.as(Tuple(Float64, Float64, Float64)))
      else
        raise "Something is wrong with the program. Please raise an issue if this occurs"
      end)
    end
  end

  def self.int?(n : Float64) : Bool
    n.to_f == n.to_i
  end

  private def self.factorial(n : Float64) : Float64
    if int?(n)
      raise "Cannot find the factorial of a negative integer" if n < 0
      (1..n.to_i).reduce(1.0) { |a, b| a*b*1.0 }
    else
      Math.gamma(n + 1)
    end
  end

  OPS_HASH = {
    "+" => {:precedence => 2, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a + b }},
    "-" => {:precedence => 2, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a - b }},
    "*" => {:precedence => 3, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a * b }},
    "×" => {:precedence => 3, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a * b }},
    "/" => {:precedence => 3, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a / b }},
    "÷" => {:precedence => 3, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a / b }},
    "%" => {:precedence => 3, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a % b }},
    "^" => {:precedence => 4, :associativity => :right, :proc => ->(b : Float64, a : Float64) { a ** b }},
    "=" => {:precedence => 1, :associativity => :left, :proc => ->(n : Float64) { n }},
    "!" => {:precedence => 5, :associativity => :right, :proc => ->(n : Float64) { factorial n }},
  }

  enum DashSignState
    Negative
    Subtract
  end

  class ShuntingYardHandler
    property output_s, operator_s, number_s, prev_token, dash_sign_state, curr_token, index, goto_hash, id_s

    def initialize
      @hash = {} of String => Float64
      @output_s = [] of String
      @operator_s = [] of String
      @number_s = Number.new
      @id_s = Identifier.new
      @prev_token = ""
      @curr_token = ""
      @dash_sign_state = DashSignState::Negative
      @index = 0
      @goto_hash = {} of String => Proc(Bool)
      load_goto_hash
    end

    private def load_goto_hash : Hash
      @goto_hash = {"(" => ->{ goto_open }, ")" => ->{ goto_closed }}
      OPS_HASH.each_key do |op|
        @goto_hash.merge!({op => ->{ goto_operator }})
      end
      goto_hash
    end

    # or handle_number
    private def goto_number : Bool
      @operator_s << "*" if @prev_token == ")"
      @prev_token = @curr_token
      @number_s.numbers << @curr_token
      true
    end

    # or handle_operator
    private def goto_operator : Bool
      if dash_sign_state == DashSignState::Negative && ["-", "+"].includes? @curr_token
        @number_s.is_negative ^= true if @curr_token == "-"
      else
        handle_precedence unless @operator_s.empty?
        @operator_s << @curr_token
        @dash_sign_state = DashSignState::Negative
      end
      true
    end

    private def goto_open : Bool
      p "hi"
      if @prev_token == ")" || @prev_token.to_i?
        handle_precedence unless @operator_s.empty?
        @operator_s << "*"
      end
      @operator_s << "("
      @dash_sign_state = DashSignState::Negative
      true
    end

    private def goto_closed : Bool
      while @operator_s.last != "("
        @output_s << @operator_s.pop.to_s
      end
      raise "Parentheses Error: Missing '(' to match the ')' @ column #{@index + 1}!" if @operator_s.empty?
      @operator_s.pop if @operator_s.last == "("
      @dash_sign_state = DashSignState::Subtract
      true
    end

    private def handle_precedence : Tuple(Array(String), Array(String))
      unless [@operator_s.last, @curr_token].includes? "("
        top_precedence = OPS_HASH[@operator_s.last][:precedence].as(Int32)
        tkn_precedence = OPS_HASH[@curr_token][:precedence].as(Int32)
        tkn_associativity = OPS_HASH[@curr_token][:associativity].as(Symbol)
        while !@operator_s.empty? && @operator_s.last != "(" &&
              ((top_precedence > tkn_precedence) ||
              (top_precedence == tkn_precedence && tkn_associativity == :left))
          @output_s << @operator_s.pop.to_s
        end
      end
      {@output_s, @operator_s}
    end

    private def operator? : Bool
      OPS_HASH.fetch(@curr_token, false) != false
    end

    private def separator? : Bool
      ["(", ")"].includes? @curr_token
    end

    private def whitespace? : Bool
      @curr_token.strip.empty?
    end

    # Converts the given *input* expression into a postfix notation expression
    # ```
    # do_shunting_yard("1+2") # => "1 2 +"
    # ```
    def do_shunting_yard(input : String) : String
      input.split("").each do |token|
        @index += 1
        @curr_token = token
        next if whitespace?
        next goto_number if (token.to_i? || token == ".") && @id_s.empty?
        next @id_s << token unless operator? || separator? # Originally token.alphanumeric? before changing token to String
        unless @number_s.empty?
          @output_s << @number_s.to_s
          @dash_sign_state = DashSignState::Subtract
          @number_s.clear
        end

        unless @id_s.empty?
          @output_s << @id_s.to_s
          @dash_sign_state = DashSignState::Subtract
          @id_s.clear
        end

        @goto_hash.fetch(token) { |tkn| raise "Token #{tkn} is not supported yet" }.call
        @prev_token = token
      end

      @output_s << @number_s.to_s unless @number_s.empty?
      @output_s << @id_s.to_s unless @id_s.empty?

      until @operator_s.empty?
        raise "Parentheses Error: Missing ')' at the end!" if @operator_s.last == "("
        @output_s << @operator_s.pop.to_s
      end

      @output_s.join(" ")
    end
  end

  private class Identifier
    property chars

    def initialize
      @chars = [] of String
      @is_negative = false
    end

    def clear : Identifier
      @chars.clear
      @is_negative = false
      self
    end

    def to_s : String
      (@is_negative ? "-" : "") + @chars.join.to_s
    end

    def empty? : Bool
      @chars.empty?
    end

    def <<(token : String) : Identifier
      @chars << token
      self
    end
  end

  private class Number
    property numbers, is_negative

    def initialize
      @numbers = [] of String
      @is_negative = false
    end

    def clear : Number
      @numbers.clear
      @is_negative = false
      self
    end

    def to_s : String
      (@is_negative ? "-" : "") + numbers.join.to_s
    end

    def empty? : Bool
      @numbers.empty?
    end

    def <<(token : String) : Number
      @numbers << token
      self
    end
  end
end
