class BarObject
  attr_accessor  :position, :voice, :hidden, :dx, :dy
  def initialize
    @position = 0
  end

  def initialize_from_xml(xml)
    @position = xml["position"].to_i;
    @voice = xml["voicenumber"].to_i;
    @hidden = xml["hidden"].eql?("true");
    @dx = xml["dx"].to_i;
    @dy = xml["dy"].to_i;
  end
end