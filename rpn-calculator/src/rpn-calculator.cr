require "readline"

# TODO: Write documentation for `RpnCalculator`
module RPNCalculator
  VERSION = "0.1.0"

  def calculate_rpn_automata(input : String) : Float64
    stack = [] of Float64
    ops_hash = {
      "+": ->(b : Float64, a : Float64) { a + b },
      "-": ->(b : Float64, a : Float64) { a - b },
      "*": ->(b : Float64, a : Float64) { a * b },
      "/": ->(b : Float64, a : Float64) { a / b },
      "%": ->(b : Float64, a : Float64) { a % b },
    }

    input.split.each do |i|
      stack << (ops_hash.fetch(i, false) ? ops_hash[i].call(stack.pop.to_f, stack.pop.to_f) : i.to_f)
    end
    stack.pop # or stack[0]
  end

  def compare_precedence?(token, top)
  end

  def do_shunting_yard(input : String)
    output_stack = [] of String
    op_stack = [] of Char
    num_stack = [] of Char
    ops_hash = {
      '+' => {:precedence => 1, :associativity => :left},
      '-' => {:precedence => 1, :associativity => :left},
      '*' => {:precedence => 2, :associativity => :left},
      '/' => {:precedence => 2, :associativity => :left},
      '%' => {:precedence => 2, :associativity => :left},
    }

    is_negative_sign = true
    input.chars.each_with_index do |token, index| # add support for negative numbers
      next if token.whitespace?
      next num_stack << token if token.to_i? || token == '.'

      unless num_stack.empty?
        output_stack << num_stack.join
        is_negative_sign = false
        num_stack.clear
      end

      if ops_hash.fetch(token, false)
        if is_negative_sign
          num_stack.insert(0, '-')
        else
          unless op_stack.empty?
            unless op_stack.last == '('
              top_precedence = ops_hash[op_stack.last][:precedence].to_i
              tkn_precedence = ops_hash[token][:precedence].to_i
              tkn_associativity = ops_hash[token][:associativity]
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
        # Add actual error if operator stack is empty
        raise "Parentheses Error: Missing '(' to match the ')' @ column #{index + 1}!" if op_stack.empty?
        op_stack.pop if op_stack.last == '('
        is_negative_sign = false
      else
        p token.to_f?
        p ops_hash.fetch(token, false)
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

  def do_shunting_yard_after_scanning(input : String)
  end

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
# include RPNCalculator
# repl
