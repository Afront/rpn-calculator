module Parser
  OPS_HASH = {
    "+" => {:precedence => 2, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a + b }},
    "-" => {:precedence => 2, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a - b }},
    "*" => {:precedence => 3, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a * b }},
    "×" => {:precedence => 3, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a * b }},
    "/" => {:precedence => 3, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a / b }},
    "÷" => {:precedence => 3, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a / b }},
    "%" => {:precedence => 3, :associativity => :left, :proc => ->(b : Float64, a : Float64) { a % b }},
    "^" => {:precedence => 4, :associativity => :right, :proc => ->(b : Float64, a : Float64) { a ** b }},
    "=" => {:precedence => 1, :associativity => :left, :proc => ->(b : Float64, a : String) { b }},
    "!" => {:precedence => 5, :associativity => :right, :proc => ->(n : Float64) { raise "Cannot find the factorial of a negative integer" if n < 0
    (1..n.to_i).reduce(1.0) { |a, b| a*b*1.0 } }},
  }

  enum DashSignState
    Negative
    Subtract
  end

  class ShuntingYardHandler
    property output_s, operator_s, number_s, prev_token, dash_sign_state, curr_token, index, goto_hash, id_s

    def initialize
      @hash = {} of String => Float64
      @output_s = [] of String
      @operator_s = [] of String
      @number_s = Number.new
      @id_s = Identifier.new
      @prev_token = ""
      @curr_token = ""
      @dash_sign_state = DashSignState::Negative
      @index = 0
      @goto_hash = {} of String => Proc(Bool)
      load_goto_hash
    end

    def load_goto_hash : Hash
      @goto_hash = {"(" => ->{ goto_open }, ")" => ->{ goto_closed }}
      OPS_HASH.each_key do |op|
        @goto_hash.merge!({op => ->{ goto_operator }})
      end
      goto_hash
    end

    # or handle_number
    def goto_number : Bool
      @operator_s << "*" if @prev_token == ")"
      @prev_token = @curr_token
      @number_s.numbers << @curr_token
      true
    end

    # or handle_operator
    def goto_operator : Bool
      if dash_sign_state == DashSignState::Negative && ["-", "+"].includes? @curr_token
        @number_s.is_negative ^= true if @curr_token == "-"
      else
        handle_precedence unless @operator_s.empty?
        @operator_s << @curr_token
        @dash_sign_state = DashSignState::Negative
      end
      true
    end

    def goto_open : Bool
      p "hi"
      if @prev_token == ")" || @prev_token.to_i?
        handle_precedence unless @operator_s.empty?
        @operator_s << "*"
      end
      @operator_s << "("
      @dash_sign_state = DashSignState::Negative
      true
    end

    def goto_closed : Bool
      while @operator_s.last != "("
        @output_s << @operator_s.pop.to_s
      end
      raise "Parentheses Error: Missing '(' to match the ')' @ column #{@index + 1}!" if @operator_s.empty?
      @operator_s.pop if @operator_s.last == "("
      @dash_sign_state = DashSignState::Subtract
      true
    end

    def handle_precedence : Tuple(Array(String), Array(String))
      unless [@operator_s.last, @curr_token].includes? "("
        top_precedence = OPS_HASH[@operator_s.last][:precedence].as(Int32)
        tkn_precedence = OPS_HASH[@curr_token][:precedence].as(Int32)
        tkn_associativity = OPS_HASH[@curr_token][:associativity].as(Symbol)
        while !@operator_s.empty? && @operator_s.last != "(" &&
              ((top_precedence > tkn_precedence) ||
              (top_precedence == tkn_precedence && tkn_associativity == :left))
          @output_s << @operator_s.pop.to_s
        end
      end
      {@output_s, @operator_s}
    end

    def operator? : Bool
      OPS_HASH.fetch(@curr_token, false) != false
    end

    def separator? : Bool
      ["(", ")"].includes? @curr_token
    end

    def whitespace? : Bool
      @curr_token.strip.empty?
    end

    # Converts the given *input* expression into a postfix notation expression
    # ```
    # do_shunting_yard("1+2") # => "1 2 +"
    # ```
    def do_shunting_yard(input : String) : String
      input.split("").each do |token|
        @index += 1
        @curr_token = token
        next if whitespace?
        next goto_number if (token.to_i? || token == ".") && @id_s.empty?
        next @id_s << token unless operator? || separator? # Originally token.alphanumeric? before changing token to String
        unless @number_s.empty?
          @output_s << @number_s.to_s
          @dash_sign_state = DashSignState::Subtract
          @number_s.clear
        end

        unless @id_s.empty?
          @output_s << @id_s.to_s
          @dash_sign_state = DashSignState::Subtract
          @id_s.clear
        end

        @goto_hash.fetch(token) { |tkn| raise "Token #{tkn} is not supported yet" }.call
        @prev_token = token
      end

      @output_s << @number_s.to_s unless @number_s.empty?
      @output_s << @id_s.to_s unless @id_s.empty?

      until @operator_s.empty?
        raise "Parentheses Error: Missing ')' at the end!" if @operator_s.last == "("
        @output_s << @operator_s.pop.to_s
      end

      @output_s.join(" ")
    end
  end

  class Identifier
    property chars

    def initialize
      @chars = [] of String
      @is_negative = false
    end

    def clear : Identifier
      @chars.clear
      @is_negative = false
      self
    end

    def to_s : String
      (@is_negative ? "-" : "") + @chars.join.to_s
    end

    def empty? : Bool
      @chars.empty?
    end

    def <<(token : String) : Identifier
      @chars << token
      self
    end
  end

  class Number
    property numbers, is_negative

    def initialize
      @numbers = [] of String
      @is_negative = false
    end

    def clear : Number
      @numbers.clear
      @is_negative = false
      self
    end

    def to_s : String
      (@is_negative ? "-" : "") + numbers.join.to_s
    end

    def empty? : Bool
      @numbers.empty?
    end

    def <<(token : String) : Number
      @numbers << token
      self
    end
  end
end
