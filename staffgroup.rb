class StaffGroup
  attr_accessor :instruments, :bracket
  def initialize
    @instruments = []
    @bracket = true
  end

  def <<(instrument)
    @instruments += instrument
  end

  def to_ly
    s = ""
    if @instruments.empty?
      return s
    end
    if @bracket
      s << "  \\new StaffGroup\n"
      s << "  {\n"
      s << "    <<\n"
    end
    for instrument in @instruments
      s << instrument.to_ly
    end
    if @bracket
      s << "\n    >>\n  } % StaffGroup\n"
    end
    return s
  end
end