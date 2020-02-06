require "readline"

# TODO: Write documentation for `RpnCalculator`
module RPNCalculator
  VERSION = "0.1.0"

  def calculate_rpn_automata(input : String) : Float64
    stack = [] of Float64
    ops_hash = {
      "+": ->(a : Float64, b : Float64) { a + b },
      "-": ->(a : Float64, b : Float64) { a - b },
      "*": ->(a : Float64, b : Float64) { a * b },
      "/": ->(a : Float64, b : Float64) { a / b },
      "%": ->(a : Float64, b : Float64) { a % b },
    }

    input.split.each do |i|
      stack << (ops_hash.fetch(i, false) ? ops_hash[i].call(stack.pop.to_f, stack.pop.to_f) : i.to_f)
    end
    stack.pop # or stack[0]
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

    input.chars.each do |token| # add support for negative numbers
      next if token.whitespace?
      if token.to_i? || token == '.'
        num_stack << token
      elsif ops_hash.fetch(token, false)
        output_stack << num_stack.join
        num_stack.clear
        unless op_stack.empty?
          break if op_stack.last == '('
          top_precedence = ops_hash[op_stack.last][:precedence].to_i
          tkn_precedence = ops_hash[token][:precedence].to_i
          tkn_associativity = ops_hash[token][:associativity]
          while (op_stack.last != '(') ||
                (top_precedence > tkn_precedence) ||
                (top_precedence == tkn_precedence && tkn_associativity == :left) &&
                output_stack << op_stack.pop.to_s
          end
        end
        op_stack << token
      elsif token == '('
        op_stack << '('
      elsif token == ')'
        while op_stack.last != '('
          output_stack << op_stack.pop.to_s
        end
        # Add actual error if operator stack is empty
        raise "Parentheses Error: Missing ( @ column..." if op_stack.empty?
        op_stack.pop if op_stack.last == '('
      else
        p token.to_f?
        p ops_hash.fetch(token, false)
        return "Not supported yet #{token}"
      end
    end
    output_stack << num_stack.join unless num_stack.empty?
    until op_stack.empty?
      raise "Parentheses Error: Missing ) @ column..." if op_stack.last == '('
      output_stack << op_stack.pop.to_s
    end

    output_stack
  end

  def repl
    until ["abort", "exit", "quit", "q"].includes?(input = Readline.readline("> "))
      #      p calculate_rpn_automata(input || "")
      p do_shunting_yard(input || "")
    end
  end
end

include RPNCalculator

repl
