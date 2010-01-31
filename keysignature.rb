class KeySignature < BarObject
  attr_accessor :as_text, :major
  def initialize

  end

  def initialize_from_xml(xml)
    super(xml)
    @as_text = xml["AsText"].downcase;
    @major = xml["Major"].eql?("true");
  end

  def KeySignature.new_from_xml(xml)
    ks = KeySignature.new
    ks.initialize_from_xml(xml)
    ks
  end

  def to_ly
    if @as_text == "atonal"
      s = "\\key c "
    else
      s = "\\key " + written_name2ly(@as_text) + " "
    end
    if @major
      s << "\\major "
    else
      s << "\\minor "
    end
    return s
  end
end