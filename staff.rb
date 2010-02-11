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

require 'voice'
require 'voicechords'
require 'voicelyrics'
require 'bar'
require 'clef'
require 'spanners'
require 'text'

class Staff < Translatable
  attr_accessor :family, :is_system_staff, :instrument_name,
    :full_instrument_name, :short_instrument_name, :initial_clef,
    :initial_style_id, :voices, :num_staves_in_same_instrument, :num_stave_lines,
    :bars, :chords, :number, :lyrics


  def initialize(xml)
    @voices = []
    @bars = []
    @chords = []
    @is_system_staff = xml["IsSystemStaff"].eql?("true")
    @full_instrument_name = xml["FullInstrumentName"]
    @instrument_name = xml["InstrumentName"]
    @short_instrument_name = xml["ShortInstrumentName"]
    @initial_style_id = xml["InitialStyleId"]
    @num_staves_in_same_instrument = xml["NumStavesInSameInstrument"].to_i
    @num_stave_lines =  xml["NumStaveLines"].to_i
    @family = @initial_style_id.split(".")[1] if @initial_style_id
    @initial_clef = xml["InitialClefStyleId"];

		return if $opt.list # Do not proceed to read bars
    
		puts "\tProcessing staff " + full_instrument_name + "..." if full_instrument_name
    (xml/"Bar").each do |bar|
      @bars << Bar.new_from_xml(bar)
    end
  end

  # Return the i-th bar
  def [](i)
    @bars[i]
  end

	# Make a valid LilyPond identifier from the instrument name.
  def safe_instrument_name
    s = @instrument_name
    DIGITS.each{|key,value| s = s.gsub(key, value)}
    s = s.gsub(/[^A-Za-z]/, '')
    # If we are given a staff number, append it as a Roman numeral
    s = "staff" + roman(@number) + s if @number
    s
  end

  def split_into_voices
    verbose("Splitting staves into voices.")
		# Create a new voice for lyrics and populate it with LyricItems
    @lyrics = VoiceLyrics.filter_copy(1, @bars) {|obj| obj.is_a?(LyricItem)}
		@bars.each do |bar|
			li = bar.objects.select {|obj| obj.is_a?(LyricItem)}
			bar.remove(li)
		end

    @voices << Voice.filter_copy(1, @bars) {|obj| obj.voice == 1 or obj.voice == 0 or obj.is_a?(OctavaLine)}
    unless @is_system_staff
      @voices << Voice.filter_copy(2, @bars) {|obj| obj.voice == 2 or obj.is_a?(OctavaLine)}
    end
		ic = Clef.new(@initial_clef)
		ic.position = 0
		@voices.first[0].add(ic)
    # Create a new voice for chords and populate it with chord symbols
    @chords = VoiceChords.filter_copy(1, @bars) {|obj| (obj.is_a?(Text) and obj.style_id == "text.staff.space.chordsymbol")}

  end

  def determine_voice_mode
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

  def process
        
    split_into_voices
    
    verbose("Processing individual voices.")
    voices.each{|voice| voice.process}
    chords.process
    lyrics.process
    determine_voice_mode
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

	# Is there something to typeset in chord mode?
  def chords_present?
    if @chords and @chords.chord_count > 0
      return true
    end
    false
  end

	# Is there something to typeset in lyrics mode?
	def lyrics_present?
		return (@lyrics and (@lyrics.lyrics_count > 0))
	end

	VOICE_NAMES = {
		1 => 'one',
		2 => 'two',
		3 => 'three',
		4 => 'four'
	}
  def to_ly
    # s = clef2ly(@initial_clef)
		s = ""	
    if polyphonic or lyrics_present?
      v = brackets(" <<", "\n>>") do |ss|
        voices.each_with_index do |voice, index|
          ss << brackets("\n\\new Voice = \"#{VOICE_NAMES[index + 1]}\" {", "}") do |sss|
            sss << VOICE[index+1] if index > 0
            sss << voice.to_ly
          end
        end
				ss << "\n\\" + safe_instrument_name + "Lyrics" if lyrics_present?
        ss
      end
      s << v
    else
      s << voices.first.to_ly
    end
    s
  end
end
