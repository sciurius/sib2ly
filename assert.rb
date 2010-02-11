class AssertionFailure < StandardError
end

class Object
  def assert(bool, message = 'assertion failure')
    #if $DEBUG
      raise AssertionFailure.new(message) unless bool
    #end
  end
end

