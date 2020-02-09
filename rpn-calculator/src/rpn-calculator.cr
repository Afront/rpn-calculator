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
    # Token.type("ahhh") = :unkown
    # ```
    def type
      if OPS_HASH.fetch(token.to_s.chars.last, false)
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
      op = token.chars.last
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
            stack << Token.new(OPS_HASH[token.chars.last][:proc].as(Proc(Float64, Float64, Float64)).call(second_arg.token.to_f, first_arg.token.to_f))
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

  # Converts the given *input* expression into a postfix notation expression
  # ```
  # do_shunting_yard("1+2") # => "1 2 +"
  # ```
  def do_shunting_yard(input : String)
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
  enum States
    Start
    PositiveSign
    NegativeSign
    Number
    Operator
    Error
  end

  # Scans the expression and gives a symbol stack as its output
  # ```
  # scan("134+---2") => [Token(134), Token('+'), Token(-2)]
  # ```
  def scan(input : String) : Array(Token)
    symbol_stack = [] of Token
    state = States::Start # states: Start,
    input.chars.each do |token|
      case state
      when States::Start
        state = States::Error
        state = States::PositiveSign if token == '+'
        state = States::NegativeSign if token == '-'
        state = States::Number if token.to_i?
      when States::PositiveSign
        state = States::Error
        state = States::PositiveSign if token == '+'
        state = States::Number if token.to_i?
      when States::NegativeSign
        state = States::Error
        state = States::NegativeSign if token == '-'
        state = States::Number if token.to_i?
      when States::Number
        state = States::Error
        state = States::Operator if ['+', '-', '/', '*'].includes? token
        state = States::Number if token.to_i?
      when States::Operator
        state = States::Error
        state = States::PositiveSign if token == '+'
        state = States::NegativeSign if token == '-'
        state = States::Number if token.to_i?
      when States::Error
        raise "*insert error here*"
      end
    end

    raise "Not accepted" unless [States::Start, States::Number].includes? state
    [Token.new(1)]
  end

  # Is an interactive prompt that allows users to get the results of any legal expresssion
  # ```
  # repl # => >
  # ```
  def repl
    until ["abort", "exit", "quit", "q"].includes?(input = Readline.readline(prompt: "> ", add_history: true) || "")
      if input.strip.empty?
        next
      elsif (['+', '-', '*', '/', '%'].includes? input[-1]) && input.strip.size != 1
        p calculate_rpn_automata(input || "")
      else
        p calculate_rpn_automata do_shunting_yard(input || "")
      end
    end
  end
end

# TODO: Try to find a way to allow specs/tests without calling repl
include RPNCalculator
repl
