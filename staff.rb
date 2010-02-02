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

class Staff < Translatable
  attr_accessor :family, :is_system_staff, :instrument_name,
    :full_instrument_name, :short_instrument_name, :initial_clef,
    :initial_style_id, :voices, :num_staves_in_same_instrument, :num_stave_lines,
    :bars


  def initialize(xml)
    @voices = []
    @bars = []
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
    (xml/"Bar").each do |bar|
      @bars << Bar.new(bar)
    end

  end

  def process
    verbose("Splitting staves into voices.")
    @voices << Voice.new(@bars, 1)
    unless @is_system_staff
      @voices << Voice.new(@bars, 2)
    end

    verbose("Processing individual voices.")
    voices.each{|voice| voice.process}

    verbose("Determining voice mode for NoteRests.")
    if @is_system_staff
      # In the SystemStaff all NoteRests are always in \oneVoice mode
      voices.each do |voice|
        # Select non-hidden, non-grace noterests from i-th Bar in voice
        voice.bars.each do |bar|
          bar.objects.each do |obj|
            if obj.is_a?(NoteRest) and
                not obj.grace and not obj.hidden
              obj.one_voice = true
            end
          end
        end
      end
    else
      for i in 0...@bars.length
        objects = []
        voices.each do |voice|
          # Select non-hidden, non-grace NotRests and DoubleTremolos from i-th Bar in this voice
          objects += voice.bars[i].objects.select do |obj|
            obj.is_a?(DoubleTremolo) or (obj.is_a?(NoteRest) and
              (not obj.grace) and (not obj.hidden))
          end
        end

        voices.each do |voice|
          voice.bars[i].objects.each do |this|
            if this.is_a?(NoteRest) and not this.grace and not this.hidden
              this.one_voice = !objects.find do |other|
                other.voice != this.voice and not
                (other.position >= this.position + this.duration or
                    this.position >= other.position + other.duration) and
                  !other.hidden
              end
            end
          end
        end
      end
    end
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