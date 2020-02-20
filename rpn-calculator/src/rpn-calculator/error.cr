module Error
  class FactorialOfNegativeIntegersError < Exception
    def initialize(message = "Error: Cannot find the factorial of a negative integer")
      super message
    end
  end

  def raise(type : String)
  end
end
