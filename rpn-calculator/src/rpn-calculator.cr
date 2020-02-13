require "readline"
require "./parser"

# RPNCalculator is a calculator that uses the postfix notation.
# It also accepts expressions that uses the infix notation via the shunting yard algorithm
module RPNCalculator
  VERSION = "0.2.0"

  class Calculator
    include Parser

    enum Notation
      Infix
      Prefix
      Postfix
      Error
    end

    def is_alphanumeric(string : String) : Bool
      string.chars.each { |c| return false unless c.alphanumeric? } || true
    end

    def check_notation(expression : String) : Notation
      exp_array = expression.split.map { |c| c.to_i? }
      functions = ['+', '-', '*', '/', '%']
      if expression.to_i? || is_alphanumeric(expression) || functions.includes? expression[-1]
        Notation::Postfix
      elsif (exp_array[0] && exp_array[-1].class == Int32) || expression.includes?(')')
        Notation::Infix
      elsif exp_array[-2..-1].select(nil).empty?
        Notation::Prefix
      else
        raise "This shouldn't happen!" \
              "The expression does not match any of the three notations!"
        #        Notation::Error
      end
    end

    # Calculates the result based on the *input* expression given
    # ```
    # calculate("1 2 +") # => 3
    # ```
    def calculate(input : String) : Float64
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

    # Is an interactive prompt that allows users to get the results of any legal expresssion
    # ```
    # repl # => >
    # ```
    def repl
      handler = ShuntingYardHandler.new
      until ["abort", "exit", "quit", "q"].includes?(input = (Readline.readline(prompt: "> ", add_history: true) || "").to_s)
        begin
          next if input.strip.empty?
          p calculate case check_notation input
          when Notation::Postfix
            input
          when Notation::Infix
            handler.do_shunting_yard input
          when Notation::Prefix
            raise "Prefix to Postfix transpiler not implemented yet!"
          else
            raise "Should not occur"
          end
        rescue error_msg : Exception
          p error_msg
        end
      end
    end
  end
end

calc = RPNCalculator::Calculator.new
calc.repl
