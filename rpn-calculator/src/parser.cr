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
    property output_s, operator_s, number_s, prev_token, dash_sign_state, curr_token, index, goto_hash

    def initialize
      @output_s = [] of String
      @operator_s = [] of Char
      @number_s = Number.new
      @prev_token = ' '
      @curr_token = ' '
      @dash_sign_state = DashSignState::Negative
      @index = 0
      @goto_hash = {} of Char => Proc(Bool)
      load_goto_hash
    end

    def load_goto_hash : Hash
      @goto_hash = {'(' => ->{ goto_open }, ')' => ->{ goto_closed }}
      OPS_HASH.each_key do |op|
        @goto_hash.merge!({op.as(Char) => ->{ goto_operator }})
      end
      goto_hash
    end

    # or handle_number
    def goto_number : Bool
      @operator_s << '*' if @prev_token == ')'
      @prev_token = @curr_token
      @number_s.numbers << @curr_token
      true
    end

    # or handle_operator
    def goto_operator : Bool
      if dash_sign_state == DashSignState::Negative
        @number_s.is_negative ^= true
      else
        handle_precedence unless @operator_s.empty?
        @operator_s << @curr_token
        @dash_sign_state = DashSignState::Negative
      end
      true
    end

    def goto_open : Bool
      if @prev_token == ')' || @prev_token.to_i?
        handle_precedence unless @operator_s.empty?
        @operator_s << '*'
      end
      @operator_s << '('
      @dash_sign_state = DashSignState::Negative
      true
    end

    def goto_closed : Bool
      while @operator_s.last != '('
        @output_s << @operator_s.pop.to_s
      end
      raise "Parentheses Error: Missing '(' to match the ')' @ column #{@index + 1}!" if @operator_s.empty?
      @operator_s.pop if @operator_s.last == '('
      @dash_sign_state = DashSignState::Subtract
      true
    end

    def handle_precedence : Tuple(Array(String), Array(Char))
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
      {@output_s, @operator_s}
    end

    def is_operator : Bool
      OPS_HASH.fetch(@curr_token, false) != false
    end

    # Converts the given *input* expression into a postfix notation expression
    # ```
    # do_shunting_yard("1+2") # => "1 2 +"
    # ```
    def do_shunting_yard(input : String) : String
      input.chars.each do |token|
        next if token.whitespace?
        @curr_token = token
        next goto_number if token.to_i? || token == '.'

        unless @number_s.numbers.empty?
          @output_s << @number_s.to_s
          @dash_sign_state = DashSignState::Subtract
          @number_s.clear
        end

        @goto_hash.fetch(token) { |tkn| raise "Token #{tkn} is not supported yet" }.call
        @prev_token = token
        @index += 1
      end
      @output_s << @number_s.to_s unless @number_s.numbers.empty?

      until @operator_s.empty?
        raise "Parentheses Error: Missing ')' at the end!" if @operator_s.last == '('
        @output_s << @operator_s.pop.to_s
      end

      @output_s.join(' ')
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
      (is_negative ? "-" : "") + numbers.join.to_s
    end
  end
end
