require "./error"

# Contains the methods for parsing the three types of expressions: prefix, infix, and postfix.
module Parser
  alias Token = String | BigDecimal
  alias Stack = Array(Token)

  OPS_HASH = {
    "+" => {:precedence => 2, :associativity => :left, :proc => ->(stack : Array(Token)) { stack << stack.pop + stack.pop }},
    "-" => {:precedence => 2, :associativity => :left, :proc => ->(stack : Array(Token)) { stack << -stack.pop + stack.pop }},
    "*" => {:precedence => 3, :associativity => :left, :proc => ->(stack : Array(Token)) { stack << stack.pop * stack.pop }},
    "×" => {:precedence => 3, :associativity => :left, :proc => ->(stack : Array(Token)) { stack << stack.pop * stack.pop }},
    "/" => {:precedence => 3, :associativity => :left, :proc => ->(stack : Array(Token)) { stack << 1/stack.pop * stack.pop }},
    "÷" => {:precedence => 3, :associativity => :left, :proc => ->(stack : Array(Token)) { stack << 1/stack.pop * stack.pop }},
    "%" => {:precedence => 3, :associativity => :left, :proc => ->(stack : Array(Token)) { stack << stack.pop % stack.pop }},
    "^" => {:precedence => 4, :associativity => :right, :proc => ->(stack : Array(Token)) { stack << stack.pop ** stack.pop }},
    "=" => {:precedence => 1, :associativity => :left, :proc => ->(stack : Array(Token)) { stack << stack.pop.assign(stack.pop) }},
    "!" => {:precedence => 5, :associativity => :right, :proc => ->(stack : Array(Token)) { stack << factorial stack.pop }},
  }

  private struct NotationStruct
    def initialize(@expression : String)
      @exp_array = @expression.split.map { |symbol| symbol[-1].alphanumeric? }
    end

    getter? infix : Bool { (exp_array[0].to_i? && exp_array[-1].to_i?) || exp_array.includes?(')') || exp_array.size.one? }
    getter? prefix : Bool { exp_array[-2..-1].select(nil).empty? }
    getter? postfix : Bool { ((exp_array[0] || ['-', '+'].includes? exp_array[0]) && (operator? token_str[-1]) && token_str[-2].whitespace?) }
  end

  # Converts the infix expression into a postfix expression using the shunting yard algorithm
  private def infix_to_postfix_stack(string : String)
    stack = Stack.new
    string.each_char do |c|
    end
  end

  # Converts the prefix expression into a postfix expression
  private def prefix_to_postfix_stack(string : String)
    stack = [] of Token
    input.split.reverse_each do |token_str|
      token = Token.new(token_str)
      stack << if token.operator?
        Token.new "#{1.upto(token.arity).map { stack.pop.to_s }.join(" ")} #{token.to_s}"
      else
        token
      end
    end
    stack
  end

  private def is_operator?(token : Token)
  end

  def self.to_postfix(string : String)
    case Notation.new(string = string.strip)
    when .infix?
      infix_to_postfix_stack string
    when .prefix?
      prefix_to_postfix_stack string
    when .postfix?
      postfix_to_postfix_stack string
    end
  end
end
