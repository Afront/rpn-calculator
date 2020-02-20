require "colorize"
require "readline"
require "./rpn-calculator/*"

# RPNCalculator is a calculator that uses the postfix notation.
# It also accepts expressions that uses the infix notation via the shunting yard algorithm
# Since this is pretty much identical to rpn-calculator-automata, I might merge them back together
# TODO: Add documentation
# TODO: Refactor and clean up code
module RPNCalculator
  VERSION = "0.2.4"

  class Calculator
    # Calculates the result based on the *input* expression given
    # ```
    # calculate("1 2 +") # => 3
    # ```
    def calculate(input : String) : Float64
      input = Parser.to_postfix input.strip

      stack = [] of Parser::Token
      input.split.each do |string|
        token = Parser::Token.new(string)
        raise DivisionByZeroError.new("Error: Attempted dividing by zero") if token == "/" && ["0", "0.0"].includes? stack.last.to_s
        if token.operator?
          stack = token.operate(stack)
        else
          stack << token
        end
      end
      raise ArgumentError.new("Error: Missing operator!") if stack.size > 1
      stack.pop.to_f
    end

    def format(input : String) : String
      result = calculate input
      (Parser.int128?(result.to_f) ? result.to_i128 : result.to_f).to_s
    end

    # Is an interactive prompt that allows users to get the results of any legal expresssion
    # ```
    # repl # => >
    # ```
    def repl
      until ["abort", "exit", "quit", "q"].includes?(input = (Readline.readline(prompt: "> ", add_history: true) || "").to_s)
        begin
          next if input.strip.empty?
          puts format input
        rescue error_msg : Exception
          puts error_msg.colorize(:red) # , error_msg.backtrace
        end
      end
    end
  end
end

calc = RPNCalculator::Calculator.new
calc.repl
