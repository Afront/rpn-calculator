require "readline"

# RPNCalculator is a calculator that uses the postfix notation.
# It also accepts expressions that uses the infix notation via the shunting yard algorithm
module RPNCalculator
  VERSION = "0.1.0"

  OPS_HASH = {
    '+' => {:precedence => 1, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a + b }},
    '-' => {:precedence => 1, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a - b }},
    '*' => {:precedence => 2, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a * b }},
    '/' => {:precedence => 2, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a / b }},
    '%' => {:precedence => 2, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a % b }},
  }

  # Calculates the result based on the *input* expression given
  # ```
  # calculate_rpn_automata("1 2 +") # => 3
  # ```
  def calculate_rpn_automata(input : String) : Float64
    stack = [] of Float64

    input.split.each do |token|
      op = token.chars.last
      stack << (OPS_HASH.fetch(op, false) ? OPS_HASH[op][:proc].as(Proc(Float64, Float64, Float64)).call(stack.pop.to_f, stack.pop.to_f) : token.to_f)
    end
    stack.pop # or stack[0]
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
    input.chars.each_with_index do |token, index| # add support for negative numbers
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
              while (op_stack.last != '(') ||
                    (top_precedence > tkn_precedence) ||
                    (top_precedence == tkn_precedence && tkn_associativity == :left) &&
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
  end

  # Scans the expression and gives a symbol stack as its output
  # ```
  # scan("134+---2") => ["134", "+", "-2"]
  # ```
  def scan(input : String)
  end

  # Is an interactive prompt that allows users to get the results of any legal expresssion
  # ```
  # repl # => >
  # ```
  def repl
    until ["abort", "exit", "quit", "q"].includes?(input = Readline.readline("> ") || "")
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
