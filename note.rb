class Note
  attr_accessor :pitch, :diatonic_pitch, :written_pitch, :name, :written_name, :previous_note, :tied, :ottavation
  def initialize(xml)
    @pitch = xml["Pitch"].to_i;
    @diatonic_pitch = xml["DiatonicPitch"].to_i;
    @written_pitch = xml["WrittenPitch"].to_i;
    @written_name = xml["WrittenName"];
    @name = xml["Name"];
    @tied = xml["Tied"].eql?("true");
  end

  def to_ly
    s = written_name2ly(@name)
    if @previous_note
      s << get_octave(@previous_note.diatonic_pitch, @diatonic_pitch)
    end
    if @tied
      s << "~ "
    end
    return s
  end
end