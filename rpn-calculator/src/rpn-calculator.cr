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

    enum Notation
      Infix
      Prefix
      Postfix
      Error
    end

    private def check_notation(expression : String) : Notation
      exp_token = Token.new(expression)
      exp_array = expression.split.map { |c| c.to_i? }
      if exp_token.postfix?
        Notation::Postfix
      elsif (exp_array[0] && exp_array[-1].is_a? Int32) || expression.includes?(')') || exp_array.size == 1
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

    private def assign(stack : Array(Token)) : Array(Token)
      value = stack.pop
      Token.var_hash[stack.pop.to_s] = value.to_f
      stack << value
      stack
    end

    # Calculates the result based on the *input* expression given
    # ```
    # calculate("1 2 +") # => 3
    # ```
    private def calculate_rpn(input : String) : String
      stack = [] of Token

      input.split.each do |string|
        token = Token.new(string)
        raise DivisionByZeroError.new("Error: Attempted dividing by zero") if token == "/" && stack.last == 0
        stack << if token.operator?
          arity = OPS_HASH[token.to_s][:proc].as(Proc).arity.to_i

          raise ArgumentError.new("Error: Not enough arguments!") if token.operator? && stack.size < arity
          next assign(stack) if token == "="
          stack, popped_tokens = token_pop(stack, arity)
          token.operate(popped_tokens)
        else
          token
        end
      end
      raise ArgumentError.new("Error: Missing operator!") if stack.size > 1
      stack.pop.to_i?.to_s
    end

    # Calculates the result based on the *input* expression given
    # ```
    # calculate("1 2 +") # => 3
    # ```
    private def token_pop(stack : Array(Token), arity : Int32) : Tuple(Array(Token), Tuple(Float64) | Tuple(Float64, Float64) | Tuple(Float64, Float64, Float64))
      popped_tokens = [] of Float64
      arity.times { popped_tokens << stack.pop.to_f }
      # Convert popped_tokens to numbers only -> var to numbers method
      arg_tuple = case arity
                  when 1
                    Tuple(Float64).from(popped_tokens)
                  when 2
                    Tuple(Float64, Float64).from(popped_tokens)
                  when 3
                    Tuple(Float64, Float64, Float64).from(popped_tokens)
                  else
                    raise "Something is wrong with the argument tuple for popping the tokens"
                  end

      {stack, arg_tuple}
    end

    def calculate(input : String) : String
      handler = ShuntingYardHandler.new

      calculate_rpn case check_notation input
      when Notation::Postfix
        input
      when Notation::Infix
        p handler.do_shunting_yard input
      when Notation::Prefix
        input.split.reverse.join(" ")
      else
        raise "Should not occur"
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
          puts calculate input
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
