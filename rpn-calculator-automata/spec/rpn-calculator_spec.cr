require "./spec_helper"

include RPNCalculator

describe RPNCalculator do
  # TODO: Write tests
  describe "#calculate_rpn_automata" do
    it "adds correctly" do
      calculate_rpn_automata("1 2 +").should eq(3.0)
      calculate_rpn_automata("21 2.1 +").should eq(23.1)
    end

    it "subtracts correctly" do
      calculate_rpn_automata("1 2 -").should eq(-1.0)
      calculate_rpn_automata("2 1 -").should eq(1.0)
      calculate_rpn_automata("20.1 1 -").should eq(19.1)
    end

    it "multiplies correctly" do
      calculate_rpn_automata("1 2 *").should eq(2.0)
      calculate_rpn_automata("2 -1 *").should eq(-2.0)
      calculate_rpn_automata("0.5 -2 *").should eq(-1.0)
    end

    it "divides correctly" do
      calculate_rpn_automata("1 -2 /").should eq(-0.5)
      calculate_rpn_automata("2 1 /").should eq(2.0)
      calculate_rpn_automata("100000000 5 /").should eq(20000000.0)
    end

    it "finds the remainder correctly" do
      calculate_rpn_automata("1 2 %").should eq(1.0)
      calculate_rpn_automata("1 -1 %").should eq(0.0)
      calculate_rpn_automata("100 8 %").should eq(4.0)
    end
  end

  it "accepts postfix" do
    calculate_rpn_automata(do_shunting_yard("1+2")).should eq(3)
  end

  describe "#repl" do
  end
end
