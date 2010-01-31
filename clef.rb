class Clef < BarObject
  attr_accessor :style_id
  def initialize

  end

  def initialize_from_xml(xml)
    super(xml)
    @style_id = xml["StyleId"].split(".")[1]
  end

  def Clef.new_from_xml(xml)
    ts = Clef.new
    ts.initialize_from_xml(xml)
    ts
  end

  def to_ly
    return "\\clef " + @style_id + " "
  end
end