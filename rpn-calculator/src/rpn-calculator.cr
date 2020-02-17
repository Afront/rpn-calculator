require "readline"
require "./parser"

# RPNCalculator is a calculator that uses the postfix notation.
# It also accepts expressions that uses the infix notation via the shunting yard algorithm
# Since this is pretty much identical to rpn-calculator-automata, I might merge them back together
module RPNCalculator
  VERSION = "0.2.4"

  # The token is contained in this class to provide easy methods
  class Token
    include Parser

    getter token : String | Float64

    @@var_hash = {} of String => Float64
    @@factorial_memo = {} of Float64 => Float64

    def initialize(@token)
      # raise "Token is invalid!" if !valid?
    end

    def type : Class
      @token.class
    end

    def alphanumeric?(c : String | Char = token) : Bool
      token.to_s.chars.each { |c| return false unless c.alphanumeric? } || true
    end

    def operator?(c : String | Char = token) : Bool
      OPS_HASH.fetch(c.to_s, false) != false
    end

    def whitespace?(c : String | Char = token) : Bool
      c.to_s.strip.empty?
    end

    def valid? : Bool
      alphanumeric? || operator?
    end

    def postfix? : Bool
      token_str = token.to_s
      valid? || ((token_str[0].alphanumeric? && operator? token_str[-1]))
    end

    def is_f? : Bool
      type == Float64 || token.as(String).to_f? != nil
    end

    def is_s? : Bool
      type == String
    end

    def to_f : Float64
      token_arr = token.to_s.chars
      is_negative = 1

      while token_arr[0] == '-' || token_arr[0] == '+'
        is_negative *= -1 if token_arr[0] == '-'
        token_arr.shift
      end

      trimmed_token = token_arr.join

      if is_f?
        token.to_f
      else
        @@var_hash.fetch(trimmed_token, trimmed_token).to_f * is_negative
      end
    end

    def to_s : String
      token.to_s
    end

    def ==(other : String | Char) : Bool
      token == other.to_s
    end

    def ==(other : Token) : Bool
      token = Token.token
    end

    def self.var_hash
      @@var_hash
    end

    def operate(popped_tokens)
      Token.new(case popped_tokens.size
      when 1
        if token == "!"
          n = popped_tokens[0]
          @@factorial_memo[n.to_f] ||= OPS_HASH[token.to_s][:proc].as(Proc(Float64, Float64)).call(n.to_f).to_f
        else
          result = OPS_HASH[token.to_s[0]][:proc].as(Proc(Float64, Float64)).call(*popped_tokens.as(Tuple(Float64)))
        end
      when 2
        OPS_HASH[token.to_s][:proc].as(Proc(Float64, Float64, Float64)).call(*popped_tokens.as(Tuple(Float64, Float64)))
      when 3
        -3.14
        #        OPS_HASH[token[0].to_s][:proc].as(Proc(Float64, Float64, Float64, Float64)).call(*popped_tokens.as(Tuple(Float64, Float64, Float64)))
      else
        -3.14
      end)
    end
  end

  class Calculator
    include Parser

    enum Notation
      Infix
      Prefix
      Postfix
      Error
    end

    def check_notation(expression : String) : Notation
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

    def assign(stack : Array(Token)) : Array(Token)
      arity = OPS_HASH['='][:proc].as(Proc).arity.to_i
      value = stack.pop
      Token.var_hash[stack.pop.to_s] = value.to_f
      stack << value
      stack
    end

    # Calculates the result based on the *input* expression given
    # ```
    # calculate("1 2 +") # => 3
    # ```
    def calculate(input : String) : String
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
      sprintf("%g", stack.pop.to_f) # or stack[0].to_f
    end

    # Calculates the result based on the *input* expression given
    # ```
    # calculate("1 2 +") # => 3
    # ```
    def token_pop(stack : Array(Token), arity : Int32) : Tuple(Array(Token), Tuple(Float64) | Tuple(Float64, Float64) | Tuple(Float64, Float64, Float64))
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

    # Is an interactive prompt that allows users to get the results of any legal expresssion
    # ```
    # repl # => >
    # ```
    def repl
      until ["abort", "exit", "quit", "q"].includes?(input = (Readline.readline(prompt: "> ", add_history: true) || "").to_s)
        handler = ShuntingYardHandler.new

        begin
          next if input.strip.empty?
          puts calculate case (p check_notation input)
          when Notation::Postfix
            input
          when Notation::Infix
            p handler.do_shunting_yard input
          when Notation::Prefix
            input.split.reverse.join(" ")
          else
            raise "Should not occur"
          end
        rescue error_msg : Exception
          puts error_msg, error_msg.backtrace
        end
      end
    end
  end
end

calc = RPNCalculator::Calculator.new
calc.repl
