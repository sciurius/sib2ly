class SpecialBarline < BarObject
  attr_accessor :barline_type
  def initialize
  end

  def initialize_from_xml(xml)
    initialize
    super(xml)
    @barline_type = xml["BarlineType"]
  end

  def SpecialBarline.new_from_xml(xml)
    sb = SpecialBarline.new
    sb.initialize_from_xml(xml)
    sb
  end

  def to_ly
    s = "\\bar \""
    case @barline_type
    when "Final"
      s << "|."
    when "Double"
      s << "||"
    end
    s << "\" "
    return s
  end
end