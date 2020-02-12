require "readline"
require "./parser"

# RPNCalculator is a calculator that uses the postfix notation.
# It also accepts expressions that uses the infix notation via the shunting yard algorithm
module RPNCalculator
  VERSION = "0.2.0"

  class Calculator
    include Parser

  # Calculates the result based on the *input* expression given
  # ```
  # calculate_rpn("1 2 +") # => 3
  # ```
    end

  #  def compare_precedence?(token, top)
  #  end

  class Number
    property numbers, is_negative

      else
        return "Not supported yet #{token}"
      end
    end

    # Is an interactive prompt that allows users to get the results of any legal expresssion
    # ```
    # repl # => >
    # ```
    def repl
      functions = ['+', '-', '*', '/', '%']
      until ["abort", "exit", "quit", "q"].includes?(input = Readline.readline(prompt: "> ", add_history: true) || "")
        begin
          if input.strip.empty?
            next
          elsif (functions.includes? input[-1]) && input.strip.size != 1
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
end

calc = RPNCalculator::Calculator.new
calc.repl
