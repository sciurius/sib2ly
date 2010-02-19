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
    @lyrics = []
    @is_system_staff = xml["IsSystemStaff"].eql?("true")
    @full_instrument_name = xml["FullInstrumentName"]
    @instrument_name = xml["InstrumentName"]
    @short_instrument_name = xml["ShortInstrumentName"]
    @initial_style_id = xml["InitialStyleId"]
    @num_staves_in_same_instrument = xml["NumStavesInSameInstrument"].to_i
    @num_stave_lines =  xml["NumStaveLines"].to_i
    @family = @initial_style_id.split(".")[1] if @initial_style_id
    @initial_clef = xml["InitialClefStyleId"];

		return if $opts[:list] # Do not proceed to read bars
    
		puts "\tProcessing staff " + full_instrument_name + "..." if full_instrument_name
    (xml/"Bar").each_with_index do |bar, idx|
      bars << Bar.new_from_xml(bar, self)
      bars.last.prev = (idx > 0 ? bars[idx - 1] : nil)
    end
  end

  # Return the i-th bar
  def [](i)
    @bars[i]
  end

  def prev_bar(bar)
    idx = bars.index(bar)
    return nil if idx.nil? or idx.zero?
    return bars[idx - 1]
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
    unless @is_system_staff
      @lyrics << VoiceLyrics.filter_copy(1, @bars) {|obj| obj.voice == 1}
      @lyrics << VoiceLyrics.filter_copy(2, @bars) {|obj| obj.voice == 2}
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
          # Select non-hidden, non-grace NotRests and DoubleTremolos
          # from i-th Bar in this voice
          objects += voice.bars[i].objects.select do |obj|
            #            (obj.is_a?(DoubleTremolo) or (obj.is_a?(NoteRest) and \
            #                  (not obj.grace) and (not obj.hidden)))
            ((obj.is_a?(NoteRest) and !obj.grace and !obj.hidden))
          end
        end

        voices.each do |voice|
          voice.bars[i].objects.each do |this|
            if this.is_a?(NoteRest) and !this.grace and !this.hidden
              overlapping = objects.select{|obj| obj.voice != this.voice}.find do |other|
                ov = this.overlaps?(other)
                if this.begins_tremolo?
                  ov = ov || this.next.overlaps?(other)
                end
                if this.ends_tremolo?
                  ov = ov || this.prev.overlaps?(other)
                end
                ov
              end
              this.one_voice = overlapping ? false : true
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
    lyrics.each{|ly| ly.process}
    determine_voice_mode
  end

  def nr_count
    @voices.inject(0){|sum, v| sum += v.nr_count}
  end

  def polyphonic?
    for i in 1..@voices.length
      if @voices[i] and @voices[i].contains_music?
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
    return false unless (@lyrics and !@lyrics.empty?)
    return @lyrics.find do |ly|
      ly.contains_music?
    end ? true : false
  end
  
  def to_ly
    # s = clef2ly(@initial_clef)

    s = ""
    if !@is_system_staff and (polyphonic? or lyrics_present?)
      sin = safe_instrument_name
      v = brackets("<<", "\n>>") do |ss|
        voices.each_with_index do |voice, index|
          ss << brackets("\n\\new Voice = \"#{sin + VOICE_NAMES[index + 1]}\" {", "}") do |sss|
            sss << VOICE[index+1] if index > 0
            sss << voice.to_ly
          end
        end
        unless @is_system_staff
          lyrics.each_with_index do |ly, index|
            ss << "\n\\" + sin + VOICE_NAMES[index + 1] + "Lyrics" if lyrics_present?
          end
        end
        ss
      end
      s << v
    else
      s << voices.first.to_ly
    end
    s
  end
end
