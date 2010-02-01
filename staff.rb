# This file is part of SIB2LY    Copyright 2010 Kirill Sidorov
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class Staff
  attr_accessor :family, :is_system_staff, :instrument_name,
    :full_instrument_name, :short_instrument_name, :initial_clef,
    :initial_style_id, :voices, :num_staves_in_same_instrument, :num_stave_lines


  def initialize(xml)
    @voices = []
    bars = []
    @is_system_staff = xml["IsSystemStaff"].eql?("true")
    @full_instrument_name = xml["FullInstrumentName"]
    @instrument_name = xml["InstrumentName"]
    @short_instrument_name = xml["ShortInstrumentName"]
    @initial_style_id = xml["InitialStyleId"]

    @num_staves_in_same_instrument = xml["NumStavesInSameInstrument"].to_i
    @num_stave_lines =  xml["NumStaveLines"].to_i

    @family = @initial_style_id.split(".")[1] if @initial_style_id

    @initial_clef = xml["InitialClefStyleId"];
    puts "\tProcessing staff " + full_instrument_name + "..." if full_instrument_name
    #puts @family
    (xml/"Bar").each do |bar|
      #puts bar
      bars << Bar.new(bar)
      bars.last.determine_voice_mode
    end
    @voices << Voice.new(bars, 1)
    unless @is_system_staff
      @voices << Voice.new(bars, 2)
    end
    voices.each{|voice| voice.process}
  end

  def nr_count
    @voices.inject(0){|sum, v| sum += v.nr_count}
  end

  def polyphonic
    for i in 1..@voices.length
      if @voices[i] and @voices[i].nr_count > 0
        return true
      end
    end
    false
  end

  def to_ly

    ly clef2ly(@initial_clef)
    if polyphonic
      ly " <<"
      voices.each_with_index do |voice, index|
        ly "\\new Voice {"
        if index > 0
          ly VOICE[index+1]
        end
        ly voice.to_ly
        ly "}"
      end
      ly "\n>>"
    else
      ly voices.first.to_ly
    end
    # return s
  end
end