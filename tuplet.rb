class Tuplet < BarObject
  attr_accessor :left, :right, :played_duration, :parent_tuplet, :notes
  def initialize
    @notes = []
  end

  def initialize_from_xml(xml)
    initialize
    super(xml)
    @left = xml["Left"].to_i;
    @right = xml["Right"].to_i;
    @played_duration = xml["PlayedDuration"].to_i;
  end

  def Tuplet.new_from_xml(xml)
    tp = Tuplet.new
    tp.initialize_from_xml(xml)
    tp
  end

  def to_ly
    return "\\times " + @right.to_s + "/" + @left.to_s+ "{"
  end
end