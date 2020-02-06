# TODO: Write documentation for `RpnCalculator`
module RPNCalculator
  VERSION = "0.1.0"

  def calculate_rpn_automata(input : String)
    stack = [] of Float64
    ops = ['+', '-', '/', '*', '%']

    input.split.each do |i|
      stack << ((ops.includes? i) ? stack.pop.send(i, stack.pop.to_f) : i.to_f)
    end
    stack.pop # or stack[0]
  end
end
