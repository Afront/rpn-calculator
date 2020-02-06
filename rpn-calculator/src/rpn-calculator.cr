# TODO: Write documentation for `RpnCalculator`
module RPNCalculator
  VERSION = "0.1.0"

  def calculate_rpn_automata(input : String)
    stack = [] of Float64
    ops_hash = {
      "+": ->(a : Float64, b : Float64) { a + b },
      "-": ->(a : Float64, b : Float64) { a - b },
      "*": ->(a : Float64, b : Float64) { a * b },
      "/": ->(a : Float64, b : Float64) { a / b },
      "%": ->(a : Float64, b : Float64) { a % b },
    }

    input.split.each do |i|
      stack << ((ops_hash.fetch(i, false)) ? ops_hash[i].call(stack.pop.to_f, stack.pop.to_f) : i.to_f)
    end
    stack.pop # or stack[0]
  end
end

include RPNCalculator

require "readline"
p calculate_rpn_automata(Readline.readline("> ") || "")
