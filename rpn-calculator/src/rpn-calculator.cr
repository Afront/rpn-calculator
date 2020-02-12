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
    end

    def check_notation(expression : String) : Notation
      functions = ['+', '-', '*', '/', '%']
      length_not_one = expression.strip.size != 1
      if (functions.includes? expression[-1]) && length_not_one
        Notation::Postfix
      elsif (functions.includes? expression[0]) && length_not_one
        Notation::Prefix
      else
        Notation::Infix
      end
    end

    # Is an interactive prompt that allows users to get the results of any legal expresssion
    # ```
    # repl # => >
    # ```
    def repl
      until ["abort", "exit", "quit", "q"].includes?(input = (Readline.readline(prompt: "> ", add_history: true) || "").to_s)
        begin
          p check_notation input
          p calculate_rpn case check_notation input
          when Notation::Postfix
            input
          when Notation::Infix
            do_shunting_yard input
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
