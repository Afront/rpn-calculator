module Parser
  OPS_HASH = {
    '+' => {:precedence => 1, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a + b }},
    '-' => {:precedence => 1, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a - b }},
    '*' => {:precedence => 2, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a * b }},
    '/' => {:precedence => 2, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a / b }},
    '%' => {:precedence => 2, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a % b }},
  }

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
    output_stack = [] of String
    op_stack = [] of Char
    number = Number.new
    dash_is_negative_sign = true
    prev_token = '\n'
    input.chars.each_with_index do |token, index|
      next if token.whitespace?

      if token.to_i? || token == '.'
        op_stack << '*' if prev_token == ')'
        prev_token = token
        next number.numbers << token
      end

      unless number.numbers.empty?
        output_stack << number.to_s
        dash_is_negative_sign = false
        number = Number.new
      end

      if OPS_HASH.fetch(token, false)
        if dash_is_negative_sign
          number.is_negative ^= true
        else
          output_stack, op_stack = check_precedence(output_stack, op_stack, token) unless op_stack.empty?
          op_stack << token
          dash_is_negative_sign = true
        end
      elsif token == '('
        if prev_token == ')' || prev_token.to_i?
          output_stack, op_stack = check_precedence(output_stack, op_stack, '*') unless op_stack.empty?
          op_stack << '*'
        end
        op_stack << '('
        dash_is_negative_sign = true
      elsif token == ')'
        while op_stack.last != '('
          output_stack << op_stack.pop.to_s
        end
        raise "Parentheses Error: Missing '(' to match the ')' @ column #{index + 1}!" if op_stack.empty?
        op_stack.pop if op_stack.last == '('
        dash_is_negative_sign = false
      else
        raise "Not supported yet #{token}"
      end
      prev_token = token
    end
    output_stack << number.to_s unless number.numbers.empty?

    until op_stack.empty?
      raise "Parentheses Error: Missing ')' at the end!" if op_stack.last == '('
      output_stack << op_stack.pop.to_s
    end

    output_stack.join(' ')
  end
end
