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

require 'verbose'
require 'translatable'
require 'staff'
require 'systemtextitem'
require 'instrument'
require 'staffgroup'
require 'constants'

class Score < Translatable
  attr_accessor :staves, :system_staff, :instruments, :staff_groups, :spectra,
    :file_name,
    :lyricist, :arranger, :artist,
    :publisher, :other_information,
    :title, :subtitle, :composer,
    :score_duration, :copyright, :part_name, :score_width, :score_height,
    :staff_height


  # Return a string containing formatted score information.
  def info
    s = ""
    s << "Title:               " + @title + "\n" if @title and !@title.empty?
    s << "Number of staves:    " + @staves.length.to_s + "\n"
    s << "Number of bars:      " + @system_staff.voices.first.bars.length.to_s + "\n"
    s << "Number of NoteRests: " + nr_count.to_s + "\n"
    s << "File name:           " + @file_name +  "\n"
    s << "Score duration:      " + ms2hms(@score_duration) + "\n"
    s << "Composer:            " + @composer + "\n" if @composer and !@composer.empty?
    s << "Lyricist:            " + @lyricist + "\n" if @lyricist and !@lyricist.empty?
    s << "Arranger:            " + @arranger + "\n" if @arranger and !@arranger.empty?
    s << "Artist:              " + @artist + "\n" if @artist and !@artist.empty?
    s << "Copyright:           " + @copyright + "\n" if @copyright and !@copyright.empty?
    s << "Publisher:           " + @publisher + "\n" if @publisher and !@publisher.empty?
    s << "Other information:   " + @other_information + "\n" if @other_information and !@other_information.empty?
    s << "Part name:           " + @part_name + "\n" if @part_name and !@part_name.empty?
  end

  def initialize

  end

  def from_xml(xml)
    @file_name = xml["FileName"]
    @score_duration = xml["ScoreDuration"].to_i
    @title = xml["Title"]
    @composer = xml["Composer"]
    @lyricist = xml["Lyricist"]
    @arranger = xml["Arranger"]
    @artist = xml["Artist"]
    @copyright = xml["Copyright"]
    @publisher = xml["Publisher"]
    @other_information = xml["OtherInformation"]
    @part_name = xml["PartName"]
    @score_width = xml["ScoreWidth"].to_i
    @staff_height = xml["ScoreHeight"].to_i
    @staff_height = xml["StaffHeight"].to_i
    @staves = []
    @staff_groups =[]
    @instruments=[]
    verbose("Creating staves from XML.")
    (xml/"Staff").each_with_index do |staff, number|
      @staves << Staff.new(staff)
      @staves.last.number = number + 1
    end

    verbose("Creating SystemStaff from XML.")
    @system_staff = Staff.new((xml/"SystemStaff").first)

    verbose "Detecting score parameters."
    detect_info
  end

  # Do substitution of Sibelius variables, e.g. $Composer
  def substitute_vars(text, variable, value)
    value = "" unless value
    text.gsub!(/\\\$#{variable}\\/i, value)
    text.gsub!(/\\\$[a-zA-Z]*\\/i, "")
    text
  end

	# Output the list of staves and corresponding instrument names.
	def list_staves
		@staves.each_with_index do |staff, idx|
			puts "Staff #{idx + 1}: #{staff.full_instrument_name}"
		end
	end

  # Detect score information: title, composer etc. from page-aligned
  # SystemTextItems in the SystemStaff
  def detect_info
    @system_staff.bars.each do |bar|
      sti = bar.objects.select {|obj| obj.is_a?(SystemTextItem)}
      sti.each do |pa|
        match = /^text.system.page_aligned.(title|composer|subtitle|lyricist)$/.match(pa.style_id)
        if match
          case match[1]
          when "title"
            @title = substitute_vars(pa.text, "TITLE", @title)
          when "subtitle"
            @subtitle = substitute_vars(pa.text, "SUBTITLE", @subtitle)
          when "composer"
            @composer = substitute_vars(pa.text, "COMPOSER", @composer)
          when "lyricist"
            @lyricist = substitute_vars(pa.text, "LYRICIST", @lyricist)
          end
        end
      end
    end
  end

  def process
    key_signatures_to_staves
    verbose("Applying magic to staves.")
    @staves.each do |staff|
      staff.process
    end
    @system_staff.process
    
    verbose("Grouping staves into instruments.")
    i = 0
    # Create instruments from staves
    while i < @staves.length
      ns = @staves[i].num_staves_in_same_instrument
      @instruments << Instrument.new(@staves[i, ns])
      i += ns
    end

    @staff_groups << StaffGroup.new
    @staff_groups.last << @instruments.select{|instrument| instrument.family == "wind"}
    @staff_groups << StaffGroup.new
    @staff_groups.last << @instruments.select{|instrument| instrument.family == "brass"}
    @staff_groups << StaffGroup.new
    @staff_groups.last << @instruments.select{|instrument| instrument.family != "strings" and instrument.family != "brass" and instrument.family != "wind"}
    @staff_groups.last.bracket = false
    @staff_groups << StaffGroup.new
    @staff_groups.last << @instruments.select{|instrument| instrument.family == "strings"}

    sync_grace_notes
  end

  def sync_grace_notes
    verbose("Casting spells on grace notes.")
    @system_staff.voices.first.bars.each_with_index do |b, index|
      max_grace_length = 0
      @staves.each do |staff|
        staff.voices.each do |voice|
          bar = voice[index]

          if first_nr = bar.objects.find{|obj| obj.is_a?(NoteRest)} and !first_nr.grace_notes.empty?
            dur = first_nr.grace_notes.inject(0){|sum, g| sum += g.duration}
          else dur = 0
          end
          max_grace_length = dur if dur > max_grace_length
        end
      end
      #puts index.to_s + " " + max_grace_length.to_s + "\n"
      @staves.each do |staff|
        bar = staff.voices.first[index]
        if first_nr = bar.objects.find{|obj| obj.is_a?(NoteRest)}
          dur = first_nr.grace_notes.inject(0){|sum, g| sum += g.duration}
          pad = max_grace_length - dur
          first_nr.grace_notes = fill(0, pad, 1) + first_nr.grace_notes
        end
      end
      bar = @system_staff.voices.first[index]
      if first_nr = bar.objects.find{|obj| obj.is_a?(NoteRest)}
        dur = first_nr.grace_notes.inject(0){|sum, g| sum += g.real_duration}
        pad = max_grace_length - dur
        first_nr.grace_notes = fill(0, pad, 1) + first_nr.grace_notes
      end
    end
  end

  # Move key signatures from the SystemStaff to Staves
  def key_signatures_to_staves
    @system_staff.bars.each_with_index do |ssbar, idx|
      key_signatures = ssbar.objects.select{|obj| obj.is_a?(KeySignature)}
      key_signatures.each do |ks|
        @staves.each do |staff|
          bar = staff.bars[idx]
          #bar.insert(ks, ks.position)
          bar.add(ks)
        end
      end
      ssbar.remove(key_signatures)
    end
  end

  def detect_title_etc
    st = @system_staff.voices.first.bars.first.objects.find{|obj| obj.is_a?(SystemTextItem) and obj.style_id == 'text.system.page_aligned.title'}
    @title = st.text if st
    #puts title
    st = @system_staff.voices.first.bars.first.objects.find{|obj| obj.is_a?(SystemTextItem) and obj.style_id == 'text.system.page_aligned.subtitle'}
    @subtitle = st.text if st
    #puts subtitle
  end

  def nr_count
    @staves.inject(0){|sum, st| sum += st.nr_count}
  end



  def to_ly
    verbose("Translating Score to LilyPond.")
    ly PREAMBLE

    header = "\\header " + brackets("{\n", "\n} % header") do |s|
      s << '  title    = "' + escape_quotes(@title) + "\"\n"    if @title
      s << '  subtitle = "' + escape_quotes(@subtitle) + "\"\n" if @subtitle
      s << '  composer = "' + escape_quotes(@composer) + "\"\n" if @composer
      s << '  poet     = "' + escape_quotes(@lyricist) + "\""   if @lyricist
    end
    ly header
		ly

    verbose("Translating staves.")
    @staves.each do |staff|
      #puts staff.full_instrument_name
      sin = staff.safe_instrument_name

      #      ly sin + " = {"
      #      staff.to_ly
      #      ly "} % " + sin + "\n"

      #	if staff.lyrics_present?
      staff.lyrics.each_with_index do |l, index|
        if l.contains_music?
          ly sin + VOICE_NAMES[index + 1] + "Lyrics = {"
          ly "\\new Lyrics \\lyricmode "
          ly l.to_ly(sin + VOICE_NAMES[index + 1])
          ly "} % " + sin + "Lyrics\n"
        end
      end
      #	end

			st = sin + " = " + brackets("{\n", "\n} % #{sin}\n") do |s|
        s << staff.to_ly
      end
      ly st

      if staff.chords_present?
        ly sin + "Chords = {"
        ly "\\chords "
        ly staff.chords.to_ly
        ly "} % " + sin + "Chords\n"
      end

    end

    verbose("Translating SystemStaff to LilyPond.")
    ly "global = {"
    global = @system_staff.to_ly
    ly global
    ly "}"
    ly "\\new Score"
    ly "\\with"
    ly "{"
    ly "  \\override VerticalAlignment #'max-stretch = #ly:align-interface::calc-max-stretch"
    ly "}"

    verbose("Writing groups of staves.")
    ly "{\n<<"
    @staff_groups.each do |group|
      ly group.to_ly unless group.empty?
    end
    ly ">>"
    ly "} % Score"
  end

  def get_notes(bar_start, bar_end = bar_start)
    # returns all notes contained in the bars bar_start..bar_end
    n = []
    @staves.each do |staff|
      if staff.num_stave_lines == 5
        staff.voices.each do |voice|
          (bar_start..bar_end).each do |i|
            bar = voice[i]
            bar.objects.each do |obj|
              n += obj.notes if obj.is_a?(NoteRest)
            end
          end
        end
      end
    end
    return n
  end

  def num_bars
    @system_staff.voices.first.bars.length
  end

  def pitch_classes
    s = ""
    system_staff.voices.first.bars.each_with_index do |_, index|
      classes = Array.new(12, 0)
      staves.each do |staff|
        staff.voices.each do |voice|
          bar = voice[index]
          noterests = bar.objects.select {|obj| obj.is_a?(NoteRest) and !obj.hidden}
          noterests.each do |nr|
            nr.notes.each do |n|
              classes[n.pitch % 12] += 1
            end
          end
        end
      end
      s << classes.join(' ') << "\n"
    end
    s
  end
end


