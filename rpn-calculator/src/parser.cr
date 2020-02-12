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
    property output_s, operator_s, number_s, prev_token, dash_sign_state, curr_token, index

    def initialize
      @output_s = [] of String
      @operator_s = [] of Char
      @number_s = Number.new
      @prev_token = ' '
      @curr_token = ' '
      @dash_sign_state = DashSignState::Negative
      @index = 0
    end

    # or handle_number
    def goto_number
      return if @curr_token.whitespace?
      @operator_s << '*' if @prev_token == ')'
      @prev_token = @curr_token
      @number_s.numbers << @curr_token
    end

    # or handle_operator
    def goto_operator
      if dash_sign_state == DashSignState::Negative
        @number_s.is_negative ^= true
      else
        check_precedence unless @operator_s.empty?
        @operator_s << @curr_token
        @dash_sign_state = DashSignState::Negative
      end
    end

    def goto_open
      if @prev_token == ')' || @prev_token.to_i?
        check_precedence unless @operator_s.empty?
        @operator_s << '*'
      end
      @operator_s << '('
      @dash_sign_state = DashSignState::Negative
    end

    def goto_closed
      while @operator_s.last != '('
        @output_s << @operator_s.pop.to_s
      end
      raise "Parentheses Error: Missing '(' to match the ')' @ column #{@index + 1}!" if @operator_s.empty?
      @operator_s.pop if @operator_s.last == '('
      @dash_sign_state = DashSignState::Subtract
    end

    def check_precedence
      unless @operator_s.last == '('
        top_precedence = OPS_HASH[@operator_s.last][:precedence].as(Int32)
        tkn_precedence = OPS_HASH[@curr_token][:precedence].as(Int32)
        tkn_associativity = OPS_HASH[@curr_token][:associativity].as(Symbol)
        while !@operator_s.empty? && @operator_s.last != '(' &&
              ((top_precedence > tkn_precedence) ||
              (top_precedence == tkn_precedence && tkn_associativity == :left))
          @output_s << @operator_s.pop.to_s
        end
      end
    end

    def is_operator : Bool
      OPS_HASH.fetch(@curr_token, false) != false
    end
  end

  class Number
    property numbers, is_negative

    def initialize
      @numbers = [] of Char
      @is_negative = false
    end

    def clear : Number
      @numbers.clear
      @is_negative = false
      self
    end

    def to_s : String
      p (is_negative ? "-" : "") + numbers.join.to_s
    end
  end

  # Converts the given *input* expression into a postfix notation expression
  # ```
  # do_shunting_yard("1+2") # => "1 2 +"
  # ```
  def do_shunting_yard(input : String)
    handler = ShuntingYardHandler.new

    input.chars.each do |token|
      handler.curr_token = token

      next handler.goto_number if token.to_i? || token == '.' || token.whitespace?

      unless handler.number_s.numbers.empty?
        handler.output_s << handler.number_s.to_s
        handler.dash_sign_state = DashSignState::Subtract
        handler.number_s.clear
      end

      if handler.is_operator
        handler.goto_operator
      elsif handler.curr_token == '('
        handler.goto_open
      elsif handler.curr_token == ')'
        handler.goto_closed
      else
        raise "Not supported yet #{token}"
      end
      handler.prev_token = token
      handler.index += 1
    end
    handler.output_s << handler.number_s.to_s unless handler.number_s.numbers.empty?

    until handler.operator_s.empty?
      raise "Parentheses Error: Missing ')' at the end!" if handler.operator_s.last == '('
      handler.output_s << handler.operator_s.pop.to_s
    end

    handler.output_s.join(' ')
  end
end
