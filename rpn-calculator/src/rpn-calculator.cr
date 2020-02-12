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

  # Calculates the result based on the *input* expression given
  # ```
  # calculate_rpn("1 2 +") # => 3
  # ```
  def calculate_rpn(input : String) : Float64
    stack = [] of Float64

    input.split.each do |token|
      op = token.char_at(-1)
      raise DivisionByZeroError.new("Error: Attempted dividing by zero") if op == '/' && stack.last == 0
      raise ArgumentError.new("Error: Not enough arguments!") if (is_op = OPS_HASH.fetch(op, false)) && stack.size < 2
      stack << (is_op ? OPS_HASH[op][:proc].as(Proc(Float64, Float64, Float64)).call(stack.pop.to_f, stack.pop.to_f) : token.to_f)
    end
    raise ArgumentError.new("Error: Missing operator!") if stack.size > 1
    stack.pop # or stack[0]
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

  def check_precedence(output_stack, op_stack, token)
    unless op_stack.last == '('
      top_precedence = OPS_HASH[op_stack.last][:precedence].as(Int32)
      tkn_precedence = OPS_HASH[token][:precedence].as(Int32)
      tkn_associativity = OPS_HASH[token][:associativity].as(Symbol)
      while !op_stack.empty? && op_stack.last != '(' &&
            ((top_precedence > tkn_precedence) ||
            (top_precedence == tkn_precedence && tkn_associativity == :left))
        output_stack << op_stack.pop.to_s
      end
    end
    {output_stack, op_stack}
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
    prev_token = '\n'
    input.chars.each_with_index do |token, index|
      next if token.whitespace?

      if token.to_i? || token == '.'
        op_stack << '*' if prev_token == ')'
        prev_token = token
        next number.numbers << token
      end

      unless number.numbers.empty?
        output_stack << number.to_s
        dash_is_negative_sign = false
        number = Number.new
      end

      if OPS_HASH.fetch(token, false)
        if dash_is_negative_sign
          number.is_negative ^= true
        else
          output_stack, op_stack = check_precedence(output_stack, op_stack, token) unless op_stack.empty?
          op_stack << token
          dash_is_negative_sign = true
        end
      elsif token == '('
        if prev_token == ')' || prev_token.to_i?
          output_stack, op_stack = check_precedence(output_stack, op_stack, '*') unless op_stack.empty?
          op_stack << '*'
        end
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
      prev_token = token
    end
    output_stack << number.to_s unless number.numbers.empty?

    until op_stack.empty?
      raise "Parentheses Error: Missing ')' at the end!" if op_stack.last == '('
      output_stack << op_stack.pop.to_s
    end

    output_stack.join(' ')
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
          p calculate_rpn(input || "")
        else
          p do_shunting_yard(input || "")
          p calculate_rpn do_shunting_yard(input || "")
        end
      rescue error_msg : Exception
        p error_msg
      end
    end
  end
end

include RPNCalculator
repl
