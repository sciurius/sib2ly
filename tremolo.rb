class Tremolo < BarObject
  attr_accessor :note_rests
  def initialize(nr)
    if nr.is_a?(Array)
      @note_rests = nr
    else
      @note_rests = [nr]
    end
  end
  def to_ly
    s = ""
    @note_rests.each do |nr|
      td = get_tremolo_duration(nr.duration, nr.single_tremolos)
      s << '\repeat tremolo ' << (nr.duration / td).to_s << ' '
      nr.duration = td
      s << nr.to_ly
      #  s << '^\markup {' << @note_rests.first.single_tremolos.to_s << '}'
    end
    return s
  end
end