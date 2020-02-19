require "readline"
require "./parser"

# RPNCalculator is a calculator that uses the postfix notation.
# It also accepts expressions that uses the infix notation via the shunting yard algorithm
# Since this is pretty much identical to rpn-calculator-automata, I might merge them back together
# TODO: Add documentation
# TODO: Revamp specs
# TODO: Refactor and clean up code

module RPNCalculator
  VERSION = "0.2.4"

  class Calculator
    include Parser

    # Calculates the result based on the *input* expression given
    # ```
    # calculate("1 2 +") # => 3
    # ```
    private def calculate_rpn(input : String) : Float64
      stack = [] of Token

      input.split.each do |string|
        token = Token.new(string)
        raise DivisionByZeroError.new("Error: Attempted dividing by zero") if token == "/" && ["0", "0.0"].includes?(stack.last)
        stack << if token.operator?
          arity = OPS_HASH[token.to_s][:proc].as(Proc).arity.to_i

          raise ArgumentError.new("Error: Not enough arguments!") if stack.size < arity
          next assign(stack) if token == "="
          stack, popped_tokens = token_pop(stack, arity)
          token.operate(popped_tokens)
        else
          token
        end
      end
      raise ArgumentError.new("Error: Missing operator!") if stack.size > 1
      stack.pop.to_f
    end

    private def calculate_rpn(input : String) : Float64
      stack = [] of Token
      input.split.each do |string|
        token = Token.new(string)
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

    private def to_i128?(n : Float64) : Float64 | Int128
      Parser.int128?(n.to_f) ? n.to_i128 : n.to_f
    end

    def calculate(input : String) : Float64
      input = input.strip
      calculate_rpn to_postfix(input)
    end

    def format(input : String) : String
      to_i128?(calculate input).to_s
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
          puts error_msg, error_msg.backtrace
        end
      end
    end
  end
end

calc = RPNCalculator::Calculator.new
calc.repl
# p RPNCalculator::Calculator::Token.new("a").postfix?
