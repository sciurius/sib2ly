class BarRest < NoteRest
  attr_accessor :length, :real_duration, :texts
  def initialize
    super
    @position = 0
    @texts = []
    @real_duration = @length
  end

  def initialize_from_xml(xml)
    super(xml)
    parent_bar = xml.parent
    @length = parent_bar["Length"].to_i
    @position = 0
    @real_duration = @length
  end

  def BarRest.new_from_xml(xml)
    br = BarRest.new
    br.initialize_from_xml(xml)
    br
  end

  def is_rest?
    true
  end

  def to_ly
    s = ""
    s << voice_mode_to_ly

    s << " " if !@texts.empty?
    f = gcd(@length, 1024);
    s << grace_to_ly
    if 1 == voice
      s << "R1*"
    else
      s << "s1*"
    end
    s << (@length/f).to_s + "/" + (1024/f).to_s;
    @texts.each{|text| s << text.to_ly}
    return s
  end
end