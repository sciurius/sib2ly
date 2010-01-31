class Text < BarObject
  EXPRESSION = {
    "f" => "\\f",
    "ff" => "\\ff",
    "fff" => "\\fff",
    "ffff" => "\\ffff",
    "p" => "\\p",
    "pp" => "\\pp",
    "ppp" => "\\ppp",
    "pppp" => "\\ppp",
    "mf" => "\\mf",
    "mp" => "\\mp",
    "sf" => "\\sf",
    "fz" => "\\fz"
  }
  attr_accessor :text, :style_id
  def initialize

  end

  def initialize_from_xml(xml)
    super(xml)
    @text = xml["Text"].split("~").first # get visible part of text
    @style_id = xml["StyleId"]
  end

  def Text.new_from_xml(xml)
    t = Text.new
	t.initialize_from_xml(xml)
    t
  end

  def to_ly
    s = ""
    if !@text or @hidden or @text.empty?
      return s
    end
    case @style_id
    when "text.staff.expression"
      exp = EXPRESSION[@text.downcase]
      s << exp if exp
    when "text.staff.technique"
      if dy < 0
        s << "_"
      else
        s << "^"
      end
      s << "\\markup \{\\italic \{" + @text + "\}\}"
    end
    return s
  end
end
