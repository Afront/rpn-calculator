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
      elsif (exp_array[0] && exp_array[-1].class == Int32) || expression.includes?(')') || exp_array.size == 1
        Notation::Infix
      elsif exp_array[-2..-1].select(nil).empty?
        Notation::Prefix
      else
        Notation::Infix
        #        raise "This shouldn't happen!" \
        #             "The expression does not match any of the three notations!"
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
        stack << if is_op
          stack, popped_tokens = token_pop(stack, OPS_HASH[op][:proc].as(Proc).arity.to_i)
          evaluate_expression(op, popped_tokens)
        else
          token.to_f
        end
      end
      raise ArgumentError.new("Error: Missing operator!") if stack.size > 1
      stack.pop # or stack[0]
    end

    def token_pop(stack : Array(Float64), arity : Int32) : Tuple(Array(Float64), Tuple(Float64) | Tuple(Float64, Float64) | Tuple(Float64, Float64, Float64))
      popped_tokens = [] of Float64
      arity.times { |i| popped_tokens << stack.pop }

      arg_array = [Tuple(Float64).from(popped_tokens),
                   Tuple(Float64).from(popped_tokens),
                   Tuple(Float64, Float64).from(popped_tokens),
                   Tuple(Float64, Float64, Float64).from(popped_tokens)]
      {stack, arg_array[arity]}
    end

    def evaluate_expression(op, popped_tokens) : Float64
      case popped_tokens
      #      when 1
      #        OPS_HASH[op][:proc].as(Proc(Float64, Float64, Float64)).call(*popped_tokens.as(Tuple(Float64)))
      when 2
        OPS_HASH[op][:proc].as(Proc(Float64, Float64, Float64)).call(*popped_tokens.as(Tuple(Float64, Float64)))
        #     when 3
        #      OPS_HASH[op][:proc].as(Proc(Float64, Float64, Float64)).call(*popped_tokens.as(Tuple(Float64, Float64, Float64)))
      else
        -3.14
      end
    end

    # Is an interactive prompt that allows users to get the results of any legal expresssion
    # ```
    # repl # => >
    # ```
    def repl
      until ["abort", "exit", "quit", "q"].includes?(input = (Readline.readline(prompt: "> ", add_history: true) || "").to_s)
        handler = ShuntingYardHandler.new

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
          p error_msg.backtrace
        end
      end
    end
  end
end

calc = RPNCalculator::Calculator.new
calc.repl
