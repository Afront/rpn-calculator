require "./error"

# Contains the methods for parsing the three types of expressions: prefix, infix, and postfix.
module Parser
  struct NotationStruct
    def initialize(expression : String)
      expression.strip
    end

    getter? infix : Bool { (expression[0].to_i? && expression[-1]).to_i? || expression.includes?(')') || expression.size == 1 }
    getter? prefix : Bool { expression[-2..-1].select(nil).empty? }
    getter? postfix : Bool { }
  end

  private enum NotationEnum
    Infix
    Prefix
    Postfix

    def self.new(expression : String)
    end

    def to_s
      case self
      when Infix
      when Prefix
      when Postfix
      end
    end
  end

  def self.parse_enum(string : String)
    Notation.new(string.strip).to_s
  end

  def self.parse_struct(string : String)
    case Notation.new(string.strip)
    when .infix?
    when .prefix?
    when .postfix?
    end
  end
end
