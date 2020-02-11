require "readline"

# RPNCalculator is a calculator that uses the postfix notation.
# It also accepts expressions that uses the infix notation via the shunting yard algorithm
module RPNCalculator
  VERSION = "0.2.0"

  OPS_HASH = {
    '+' => {:precedence => 1, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a + b }},
    '-' => {:precedence => 1, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a - b }},
    '*' => {:precedence => 2, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a * b }},
    '/' => {:precedence => 2, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a / b }},
    '%' => {:precedence => 2, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a % b }},
  }

  # Contains the token for the symbol stack
  class Token
    property token

    # Creates a new object with the class 'Token'
    # ```
    # Token.new("start") => #<RPNCalculator::Token:??? @token="start">
    # ```
    def initialize(@token : Float64 | String)
    end

    # Gives the type of the token
    # ```
    # Token.type(1) = :number
    # Token.type("1") = :number
    # Token.type("+") = :operator
    # Token.type("ahhh") = :unknown
    # ```
    def type
      # NOTE: The last character is used to remove ambiguity between a negative number and the minus sign
      # It's possible to move the number statement to the top if one wants to read the first instead of the last character
      # But it could lead to some problems
      if OPS_HASH.fetch(token.to_s.char_at(-1), false)
        :operator
      elsif token == "start"
        :start
      elsif token.class == Float64 || token.to_s.to_f?
        :number
      else
        :unknown
      end
    end
  end

  # Calculates the result based on the *input* expression given
  # ```
  # calculate_rpn("1 2 +") # => 3
  # ```
  def calculate_rpn(input : String) : Float64
    stack = [] of Float64

    input.split.each do |token|
      op = token.char_at(0)
      raise DivisionByZeroError.new("Error: Attempted dividing by zero") if op == '/' && stack.last == 0
      raise ArgumentError.new("Error: Not enough arguments!") if (is_op = OPS_HASH.fetch(op, false)) && stack.size < 2
      stack << (is_op ? OPS_HASH[op][:proc].as(Proc(Float64, Float64, Float64)).call(stack.pop.to_f, stack.pop.to_f) : token.to_f)
    end
    raise ArgumentError.new("Error: Missing operator!") if stack.size > 1
    stack.pop # or stack[0]
  end

  # Calculates the result based on the *input* expression given using a DPDA-like stack machine.
  # ```
  # calculate_rpn_automata("1 2 +") # => 3
  # ```
  def calculate_rpn_automata(input : String | Array) : Float64
    input = input.split if input.class == String
    stack = [Token.new("start")]
    state = :no_op_yet
    input.as(Array).each do |token|
      continue = true
      should_be_true = false
      until continue && should_be_true
        should_be_true = true
        case state
        when :no_op_yet
          case (symbol = Token.new(token)).type
          when :number
            stack << symbol
          when :operator
            case stack.last.type
            when :start
              state = :only_an_operator
              continue = false
            when :number
              state = :op_captured
              state = :division_by_zero if stack.last.token.to_i == 0 && token == "/"
              continue = false
            else
              raise "Unknown Error!"
            end
          when :unknown # or else
            state = :unknown_token
            continue = false
          end
        when :op_captured
          second_arg = stack.pop
          first_arg = stack.pop
          if first_arg.type == :start
            state = :only_one_argument
          else
            stack << Token.new(OPS_HASH[token.char_at(0)][:proc].as(Proc(Float64, Float64, Float64)).call(second_arg.token.to_f, first_arg.token.to_f))
            state = :no_op_yet
          end
          continue = true
        when :unknown_token
          continue = true
          raise ArgumentError.new "Unknown Token: #{token}"
        when :division_by_zero
          continue = true
          raise ArgumentError.new "Attempted dividing by zero!"
        when :only_an_operator
          continue = true
          raise ArgumentError.new "Missing arguments for the operator #{stack}"
        when :only_one_argument
          continue = true
          raise ArgumentError.new "Missing one argument for the operator #{token}!"
        else
          raise "Unknown Error: #{stack}, #{token}"
        end
      end
    end

    raise "Unknown Error!: #{stack}" if stack.size != 2
    stack.pop.token.to_f # or stack[0]
  end

  #  def compare_precedence?(token, top)
  #  end

  class Number
    property numbers, is_negative

    def initialize
      @numbers = [] of Char
      @is_negative = false
    end

    def to_s : String
      p (is_negative ? "-" : "") + numbers.join.to_s
    end
  end

  # Converts the given *input* expression into a postfix notation expression
  # ```
  # do_shunting_yard("1+2") # => "1 2 +"
  # ```
  def do_shunting_yard(input : String)
    output_stack = [] of String
    op_stack = [] of Char
    number = Number.new
    dash_is_negative_sign = true

    input.chars.each_with_index do |token, index|
      next if token.whitespace?
      next number.numbers << token if token.to_i? || token == '.'

      unless number.numbers.empty?
        output_stack << number.to_s
        dash_is_negative_sign = false
        number = Number.new
      end

      if OPS_HASH.fetch(token, false)
        if dash_is_negative_sign
          number.is_negative ^= true
        else
          unless op_stack.empty?
            unless op_stack.last == '('
              top_precedence = OPS_HASH[op_stack.last][:precedence].as(Int32)
              tkn_precedence = OPS_HASH[token][:precedence].as(Int32)
              tkn_associativity = OPS_HASH[token][:associativity].as(Symbol)
              while !(op_stack.empty?) && (op_stack.last != '(') &&
                    ((top_precedence > tkn_precedence) ||
                    (top_precedence == tkn_precedence && tkn_associativity == :left))
                output_stack << op_stack.pop.to_s
              end
            end
          end
          op_stack << token
          dash_is_negative_sign = true
        end
      elsif token == '('
        op_stack << '('
        dash_is_negative_sign = true
      elsif token == ')'
        while op_stack.last != '('
          output_stack << op_stack.pop.to_s
        end
        raise "Parentheses Error: Missing '(' to match the ')' @ column #{index + 1}!" if op_stack.empty?
        op_stack.pop if op_stack.last == '('
        dash_is_negative_sign = false
      else
        return "Not supported yet #{token}"
      end
      p output_stack
    end
    output_stack << number.to_s unless number.numbers.empty?

    until op_stack.empty?
      raise "Parentheses Error: Missing ')' at the end!" if op_stack.last == '('
      output_stack << op_stack.pop.to_s
    end

    output_stack.join(' ')
  end

  def do_shunting_yard_old(input : String)
    output_stack = [] of String
    op_stack = [] of Char
    num_stack = [] of Char

    is_negative_sign = true
    input.chars.each_with_index do |token, index|
      next if token.whitespace?
      next num_stack << token if token.to_i? || token == '.'

      unless num_stack.empty?
        output_stack << num_stack.join
        is_negative_sign = false
        num_stack.clear
      end

      if OPS_HASH.fetch(token, false)
        if is_negative_sign
          num_stack.insert(0, '-')
          p "is_neg", is_negative_sign, num_stack, output_stack, op_stack
        else
          unless op_stack.empty?
            unless op_stack.last == '('
              top_precedence = OPS_HASH[op_stack.last][:precedence].as(Int32)
              tkn_precedence = OPS_HASH[token][:precedence].as(Int32)
              tkn_associativity = OPS_HASH[token][:associativity].as(Symbol)
              while !(op_stack.empty?) && (op_stack.last != '(') &&
                    ((top_precedence > tkn_precedence) ||
                    (top_precedence == tkn_precedence && tkn_associativity == :left))
                output_stack << op_stack.pop.to_s
              end
            end
          end
          op_stack << token
          is_negative_sign = true
        end
        p "is_op", is_negative_sign, num_stack, output_stack, op_stack
      elsif token == '('
        op_stack << '('
        is_negative_sign = true
      elsif token == ')'
        while op_stack.last != '('
          output_stack << op_stack.pop.to_s
        end
        raise "Parentheses Error: Missing '(' to match the ')' @ column #{index + 1}!" if op_stack.empty?
        op_stack.pop if op_stack.last == '('
        is_negative_sign = false
      else
        return "Not supported yet #{token}"
      end
      p output_stack
    end
    output_stack << num_stack.join unless num_stack.empty?

    until op_stack.empty?
      raise "Parentheses Error: Missing ')' at the end!" if op_stack.last == '('
      output_stack << op_stack.pop.to_s
    end

    output_stack.join(' ')
  end

  # Does the same thing as `RPNCalculator#do_shunting_yard`, but its input is a scanned symbol stack
  # ```
  # do_shunting_yard_after_scanning(scan("1+2")) # => "1 2 +"
  # ```
  def do_shunting_yard_after_scanning(symbol_stack : Array)
    output_stack = [] of String
    op_stack = [] of Char
    num_stack = [] of Char

    is_negative_sign = true
    input.chars.each_with_index do |token, index|
      next if token.whitespace?
      next num_stack << token if token.to_i? || token == '.'

      unless num_stack.empty?
        output_stack << num_stack.join
        is_negative_sign = false
        num_stack.clear
      end

      if OPS_HASH.fetch(token, false)
        if is_negative_sign
          num_stack.insert(0, '-')
          p "is_neg", is_negative_sign, num_stack, output_stack, op_stack
        else
          unless op_stack.empty?
            unless op_stack.last == '('
              top_precedence = OPS_HASH[op_stack.last][:precedence].as(Int32)
              tkn_precedence = OPS_HASH[token][:precedence].as(Int32)
              tkn_associativity = OPS_HASH[token][:associativity].as(Symbol)
              while !(op_stack.empty?) && (op_stack.last != '(') &&
                    ((top_precedence > tkn_precedence) ||
                    (top_precedence == tkn_precedence && tkn_associativity == :left))
                output_stack << op_stack.pop.to_s
              end
            end
          end
          op_stack << token
          is_negative_sign = true
        end
        p "is_op", is_negative_sign, num_stack, output_stack, op_stack
      elsif token == '('
        op_stack << '('
        is_negative_sign = true
      elsif token == ')'
        while op_stack.last != '('
          output_stack << op_stack.pop.to_s
        end
        raise "Parentheses Error: Missing '(' to match the ')' @ column #{index + 1}!" if op_stack.empty?
        op_stack.pop if op_stack.last == '('
        is_negative_sign = false
      else
        return "Not supported yet #{token}"
      end
      p output_stack
    end
    output_stack << num_stack.join unless num_stack.empty?

    until op_stack.empty?
      raise "Parentheses Error: Missing ')' at the end!" if op_stack.last == '('
      output_stack << op_stack.pop.to_s
    end

    output_stack.join(' ')
  end

  enum States
    Start
    PositiveSign
    NegativeSign
    Number
    Operator
    Whitespace
    Error
  end

  # Scans the expression and gives a symbol stack as its output
  # ```
  # scan("134+---2") => [Token(134), Token('+'), Token(-2)]
  # ```
  def get_next_state(state : States, token : Char) : States
    case state
    when States::Start
      state = case token
              when '+'
                States::PositiveSign
              when '-'
                States::NegativeSign
              else
                if token.whitespace?
                  States::Whitespace
                elsif token.to_i?
                  States::Number
                else
                  States::Error
                end
              end
    when States::PositiveSign
      state = case token
              when '+'
                States::PositiveSign
              else
                if token.whitespace?
                  States::Whitespace
                elsif token.to_i?
                  States::Number
                else
                  States::Error
                end
              end
    when States::NegativeSign
      state = case token
              when '-'
                States::NegativeSign
              else
                if token.whitespace?
                  States::Whitespace
                elsif token.to_i?
                  States::Number
                else
                  States::Error
                end
              end
    when States::Number
      state = if ['+', '-', '/', '*'].includes? token
                States::Operator
              elsif token.whitespace?
                States::Whitespace
              elsif token.to_i?
                States::Number
              else
                States::Error
              end
    when States::Operator
      state = case token
              when '+'
                States::PositiveSign
              when '-'
                States::NegativeSign
              else
                if token.whitespace?
                  States::Whitespace
                elsif token.to_i?
                  States::Number
                else
                  States::Error
                end
              end
    when States::Whitespace
      state = case token
              when '+'
                States::PositiveSign
              when '-'
                States::NegativeSign
              else
                if token.whitespace?
                  States::Whitespace
                elsif token.to_i?
                  States::Number
                else
                  States::Error
                end
              end
    when States::Error
      raise "*insert error here*"
    end
    state
  end

  # Scans the expression and gives a symbol stack as its output
  # ```
  # scan("134+---2") => [Token(134), Token('+'), Token(-2)]
  # ```
  def scan(input : String) : Array(Token)
    symbol_stack = [] of Token
    num_token = [] of Char
    is_negative = false
    prev_token = nil
    state = States::Start
    input.chars.each do |token|
      p ["Before", "token", token, "symbol_stack", symbol_stack, "num_token", num_token, "state", state]
      case state = get_next_state(state, token)
      when States::PositiveSign
      when States::Whitespace
      when States::NegativeSign
        is_negative ^= true # or is_negative != is_negative
      when States::Number
        num_token << token
      when States::Operator
        num_token.insert(0, '-') if is_negative
        symbol_stack << Token.new(num_token.join.to_f)
        num_token.clear
        symbol_stack << Token.new(token.to_s)
      end
      p ["After", "token", token, "symbol_stack", symbol_stack, "num_token", num_token, "state", state]
    end

    unless num_token.empty?
      num_token.insert(0, '-') if is_negative
      symbol_stack << Token.new(num_token.join.to_f)
    end

    raise "Not accepted" unless [States::Start, States::Number].includes? state
    symbol_stack
  end

  # Is an interactive prompt that allows users to get the results of any legal expresssion
  # ```
  # repl # => >
  # ```
  def repl
    until ["abort", "exit", "quit", "q"].includes?(input = Readline.readline(prompt: "> ", add_history: true) || "")
      begin
        if input.strip.empty?
          next
        elsif (['+', '-', '*', '/', '%'].includes? input[-1]) && input.strip.size != 1
          p calculate_rpn_automata(input || "")
        else
          # p scan input
          # p do_shunting_yard(input || "")
          p calculate_rpn_automata do_shunting_yard(input || "")
        end
      rescue e : Exception
        p e
      end
    end
  end
end

# TODO: Try to find a way to allow specs/tests without calling repl
include RPNCalculator
repl
