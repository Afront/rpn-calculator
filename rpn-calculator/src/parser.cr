module Parser
  OPS_HASH = {
    '+' => {:precedence => 1, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a + b }},
    '-' => {:precedence => 1, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a - b }},
    '*' => {:precedence => 2, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a * b }},
    '/' => {:precedence => 2, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a / b }},
    '%' => {:precedence => 2, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a % b }},
  }

  enum DashSignState
    Negative
    Subtract
  end

  class ShuntingYardHandler
    property output_s, operator_s, number_s, prev_token, dash_sign_state

    def initialize
      @output_s = [] of String
      @operator_s = [] of Char
      @number_s = Number.new
      @prev_token = ' '
      @dash_sign_state = DashSignState::Negative
    end
  end

  class Number
    property numbers, is_negative

    def initialize
      @numbers = [] of Char
      @is_negative = false
    end

    def to_s : String
      p (is_negative ? "-" : "") + numbers.join.to_s
    end
  end

  def check_precedence(output_stack, op_stack, token)
    unless op_stack.last == '('
      top_precedence = OPS_HASH[op_stack.last][:precedence].as(Int32)
      tkn_precedence = OPS_HASH[token][:precedence].as(Int32)
      tkn_associativity = OPS_HASH[token][:associativity].as(Symbol)
      while !op_stack.empty? && op_stack.last != '(' &&
            ((top_precedence > tkn_precedence) ||
            (top_precedence == tkn_precedence && tkn_associativity == :left))
        output_stack << op_stack.pop.to_s
      end
    end
    {output_stack, op_stack}
  end

  # Converts the given *input* expression into a postfix notation expression
  # ```
  # do_shunting_yard("1+2") # => "1 2 +"
  # ```
  def do_shunting_yard(input : String)
    handler = ShuntingYardHandler.new

    input.chars.each_with_index do |token, index|
      next if token.whitespace?

      if token.to_i? || token == '.'
        handler.operator_s << '*' if handler.prev_token == ')'
        handler.prev_token = token
        next handler.number_s.numbers << token
      end

      unless handler.number_s.numbers.empty?
        handler.output_s << handler.number_s.to_s
        handler.dash_sign_state = DashSignState::Subtract
        handler.number_s = Number.new
      end

      if OPS_HASH.fetch(token, false)
        if handler.dash_sign_state == DashSignState::Negative
          handler.number_s.is_negative ^= true
        else
          handler.output_s, handler.operator_s = check_precedence(handler.output_s, handler.operator_s, token) unless handler.operator_s.empty?
          handler.operator_s << token
          handler.dash_sign_state = DashSignState::Negative
        end
      elsif token == '('
        if handler.prev_token == ')' || handler.prev_token.to_i?
          handler.output_s, handler.operator_s = check_precedence(handler.output_s, handler.operator_s, '*') unless handler.operator_s.empty?
          handler.operator_s << '*'
        end
        handler.operator_s << '('
        handler.dash_sign_state = DashSignState::Negative
      elsif token == ')'
        while handler.operator_s.last != '('
          handler.output_s << handler.operator_s.pop.to_s
        end
        raise "Parentheses Error: Missing '(' to match the ')' @ column #{index + 1}!" if handler.operator_s.empty?
        handler.operator_s.pop if handler.operator_s.last == '('
        handler.dash_sign_state = DashSignState::Subtract
      else
        raise "Not supported yet #{token}"
      end
      handler.prev_token = token
    end
    handler.output_s << handler.number_s.to_s unless handler.number_s.numbers.empty?

    until handler.operator_s.empty?
      raise "Parentheses Error: Missing ')' at the end!" if handler.operator_s.last == '('
      handler.output_s << handler.operator_s.pop.to_s
    end

    handler.output_s.join(' ')
  end
end
