class TimeSignature < BarObject
  attr_accessor :numerator, :denominator
  def initialize

  end

  def initialize_from_xml(xml)
    super(xml)
    @numerator = xml["Numerator"].to_i;
    @denominator = xml["Denominator"].to_i;
  end

  def TimeSignature.new_from_xml(xml)
    ts = TimeSignature.new
    ts.initialize_from_xml(xml)
    ts
  end

  def to_ly
    return "\\time " + @numerator.to_s + "/" + @denominator.to_s + " "
  end
end