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
      elsif exp_array[0] && exp_array[-1].class == Int32
        Notation::Infix
      elsif exp_array[-2..-1].select(nil).empty?
        Notation::Prefix
      else
        raise "This shouldn't happen!" \
              "The expression does not match any of the three notations!"
        Notation::Error
      end
    end

    # Is an interactive prompt that allows users to get the results of any legal expresssion
    # ```
    # repl # => >
    # ```
    def repl
      until ["abort", "exit", "quit", "q"].includes?(input = (Readline.readline(prompt: "> ", add_history: true) || "").to_s)
        begin
          next if input.strip.empty?
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
