require "./error"

module Parser
  OPS_HASH = {
    "+" => {:precedence => 2, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a + b }},
    "-" => {:precedence => 2, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a - b }},
    "*" => {:precedence => 3, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a * b }},
    "×" => {:precedence => 3, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a * b }},
    "/" => {:precedence => 3, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a / b }},
    "÷" => {:precedence => 3, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a / b }},
    "%" => {:precedence => 3, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a % b }},
    "^" => {:precedence => 4, :associativity => :right, :proc => ->(b : Float64, a : Float64) { a ** b }},
    "=" => {:precedence => 1, :associativity => :left, :proc => ->(b : Float64, a : String) { Token.new(a).assign(b) }},
    "!" => {:precedence => 5, :associativity => :right, :proc => ->(n : Float64) { factorial n }},
  }

  private enum Notation
    Infix
    Prefix
    Postfix
  end

  private def self.prefix_to_postfix(input : String) : String
    stack = [] of Token
    input.split.reverse_each do |token_str|
      token = Token.new(token_str)
      stack << if token.operator?
        Token.new "#{1.upto(token.arity).map { stack.pop.to_s }.join(" ")} #{token.to_s}"
      else
        token
      end
    end
    stack.map { |token| token.to_s }.join(' ')
  end

  def self.to_postfix(input : String) : String
    handler = ShuntingYardHandler.new

    case Token.new(input).check_notation
    when Notation::Postfix
      input
    when Notation::Infix
      handler.do_shunting_yard input
    when Notation::Prefix
      prefix_to_postfix input
    else
      ""
    end
  end

  private class Number
    property symbols, is_negative

    def initialize
      @symbols = [] of String
      @is_negative = false
    end

    def clear : Number
      @symbols.clear
      @is_negative = false
      self
    end

    def to_s : String
      number = symbols.join.to_s
      (is_negative && number != "0" ? "-" : "") + number
    end

    def empty? : Bool
      symbols.empty?
    end

    def <<(token : String) : Number
      symbols << token
      self
    end
  end

  # The token is contained in this class to provide easy methods
  class Token
    include Parser

    getter token : String | Float64

    @@var_hash = {
      "e"   => Math::E,
      "PI"  => Math::PI,
      "π"   => Math::PI,
      "TAU" => 2 * Math::PI,
      "τ"   => 2 * Math::PI,
      "PHI" => 0.5 + Math.sqrt(5)/2,
      "φ"   => 0.5 + Math.sqrt(5)/2,
      "ϕ"   => 0.5 + Math.sqrt(5)/2,
    }
    @@factorial_memo = {} of Float64 => Float64

    def initialize(@token)
      # raise "Token is invalid!" if !valid?
    end

    def type : Class
      @token.class
    end

    def arity(tkn : String | Char = token) : Int32
      OPS_HASH[token.to_s][:proc].as(Proc).arity.to_i
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

    def check_notation : Notation
      token_str = token.to_s
      exp_array = token_str.split.map { |symbol| symbol[-1].alphanumeric? }

      if ((token_str[0].alphanumeric? ||
         ['-', '+'].includes? token_str[0]) &&
         (operator? token_str[-1]) &&
         token_str[-2].whitespace?)
        Notation::Postfix
      elsif (exp_array[0] && exp_array[-1]) || token_str.includes?(')') || exp_array.size == 1
        Notation::Infix
      elsif exp_array[-2..-1].select(nil).empty?
        Notation::Prefix
      else
        raise ArgumentError.new "This should not occur! Please raise an issue if it does!"
      end
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

    def token_pop(stack : Array(Token)) : Tuple(Array(Token), Tuple(Float64) | Tuple(Float64, Float64) | Tuple(Float64, Float64, Float64))
      popped_tokens = [] of Float64
      arity.times { popped_tokens << stack.pop.to_f }
      # Convert popped_tokens to numbers only -> var to numbers method
      arg_tuple = case arity
                  when 1
                    Tuple(Float64).from(popped_tokens)
                  when 2
                    Tuple(Float64, Float64).from(popped_tokens)
                  when 3
                    Tuple(Float64, Float64, Float64).from(popped_tokens)
                  else
                    raise "Something is wrong with the argument tuple for popping the tokens"
                  end

      {stack, arg_tuple}
    end

    def operate(stack : Array(Token)) : Array(Token)
      raise ArgumentError.new("Error: Not enough arguments!") if stack.size < arity

      if token == "="
        value = stack.pop.to_f
        return stack << Token.new(stack.pop.assign(value))
      end

      stack, popped_tokens = token_pop(stack)

      stack << Token.new(case arity
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
      stack
    end

    def assign(value : Float64) : Float64
      @@var_hash[token.to_s] = value
    end
  end

  def self.int128?(n : Float64) : Bool
    n.to_f == n.to_i128
  end

  private def self.factorial(n : Float64) : Float64
    if int128?(n)
      raise Error::FactorialOfNegativeIntegersError.new if n < 0
      (1..n.to_i).reduce(1.0) { |a, b| a*b*1.0 }
    else
      Math.gamma(n + 1)
    end
  end

  enum DashSignState
    Negative
    Subtract
  end

  private class ShuntingYardHandler
    property output_s, operator_s, number, prev_token, dash_sign_state, curr_token, index, goto_hash, id

    def initialize
      @hash = {} of String => Float64
      @output_s = [] of String
      @operator_s = [] of String
      @number = Number.new
      @id = Number.new
      @prev_token = " "
      @curr_token = " "
      @dash_sign_state = DashSignState::Negative
      @index = 0
      @goto_hash = {} of String => Proc(Bool)
      load_goto_hash
    end

    def load_goto_hash : Hash
      @goto_hash = {"(" => ->{ goto_open }, ")" => ->{ goto_closed }}
      OPS_HASH.each_key do |op|
        @goto_hash.merge!({op => ->{ goto_operator }})
      end
      @goto_hash
    end

    # or handle_number
    def goto_number : Bool
      @operator_s << "*" if @prev_token == ")"
      @prev_token = @curr_token
      @number.symbols << @curr_token
      true
    end

    # or handle_id
    def goto_id : Bool
      @operator_s << "*" if @prev_token == ")" || @prev_token.to_i?
      @prev_token = @curr_token
      @id << @curr_token
      true
    end

    # or handle_operator
    def goto_operator : Bool
      if dash_sign_state == DashSignState::Negative && ["-", "+"].includes? @curr_token
        @number.is_negative ^= true if @curr_token == "-"
      else
        handle_precedence unless @operator_s.empty?
        @operator_s << @curr_token
        @dash_sign_state = DashSignState::Negative
      end
      true
    end

    def goto_open : Bool
      if @prev_token == ")" || @prev_token[-1].alphanumeric?
        handle_precedence unless @operator_s.empty?
        @operator_s << "*"
      end
      @operator_s << "("
      @dash_sign_state = DashSignState::Negative
      true
    end

    def goto_closed : Bool
      while @operator_s.last != "("
        @output_s << @operator_s.pop.to_s
      end
      raise "Parentheses Error: Missing '(' to match the ')' @ column #{@index + 1}!" if @operator_s.empty?
      @operator_s.pop if @operator_s.last == "("
      @dash_sign_state = DashSignState::Subtract
      true
    end

    def handle_precedence : Tuple(Array(String), Array(String))
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

    def operator? : Bool
      OPS_HASH.fetch(@curr_token, false) != false
    end

    def separator? : Bool
      ["(", ")"].includes? @curr_token
    end

    def whitespace? : Bool
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
        next goto_number if (token.to_i? || token == ".") && @id.empty?
        next goto_id unless operator? || separator? # Originally token.alphanumeric? before changing token to String

        unless @number.empty?
          @output_s << @number.to_s
          @dash_sign_state = DashSignState::Subtract
          @number.clear
        end

        unless @id.empty?
          @output_s << @id.to_s
          @dash_sign_state = DashSignState::Subtract
          @id.clear
        end

        @goto_hash.fetch(token) { |tkn| raise "Error: Token #{tkn} is not supported yet!" }.call
        @prev_token = token
      end

      @output_s << @number.to_s unless @number.empty?
      @output_s << @id.to_s unless @id.empty?

      until @operator_s.empty?
        raise "Parentheses Error: Missing ')' at the end!" if @operator_s.last == "("
        @output_s << @operator_s.pop.to_s
      end

      @output_s.join(" ")
    end
  end
end
