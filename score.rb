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

class Score < Translatable
  attr_accessor :staves, :system_staff, :instruments, :staff_groups, :spectra,
    :file_name,
    :lyricist, :arranger, :artist,
    :publisher, :other_information,
    :title, :subtitle, :composer,
    :score_duration, :copyright, :part_name, :score_width, :score_height,
    :staff_height

  def ms2hms(ms)
    ms /= 1000
    seconds = ms % 60
    minutes = (ms / 60 ) % 60
    hours = (ms / 3600)

    ret = ""
    ret = ret + hours.to_s + "h " if hours >= 1
    ret = ret + minutes.to_s + "m " if minutes >= 1
    ret = ret + seconds.to_s + "s " if seconds > 0
    return ret
  end

  def info
    s = ""
    s << "Title:               " + @title + "\n" if @title and !@title.empty?
    s << "Number of staves:    " + @staves.length.to_s + "\n"
    s << "Number of bars:      " + @system_staff.voices.first.bars.length.to_s + "\n"
    s << "Number of NoteRests: " + nr_count.to_s + "\n"
    s << "File name:           " + @file_name + "\n"
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
    (xml/"staff").each do |staff|
      @staves << Staff.new(staff)
    end
    
    @system_staff = Staff.new((xml/"SystemStaff").first)
    i = 0
    # create instruments from staves
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

    #process
  end

  def process
    #detect_title_etc
    sync_grace_notes
  end

  def sync_grace_notes
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
          first_nr.grace_notes = fill_with_rests(0, pad, 1) + first_nr.grace_notes
        end
      end
      bar = @system_staff.voices.first[index]
      if first_nr = bar.objects.find{|obj| obj.is_a?(NoteRest)}
        dur = first_nr.grace_notes.inject(0){|sum, g| sum += g.real_duration}
        pad = max_grace_length - dur
        first_nr.grace_notes = fill_with_rests(0, pad, 1) + first_nr.grace_notes
      end
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
    ly PREAMBLE
    ly "\\header"
    ly "{"
    ly '  title = "' + escape_quotes(title) + "\"" if title
    ly '  subtitle = "' + escape_quotes(subtitle) + "\"" if subtitle
    ly '} % Header'
    @staves.each do |staff|
      #puts staff.full_instrument_name
      ly  safe_instrument_name(staff.instrument_name) + " = {"
      staff.to_ly
      ly "}"
    end
    ly ""
    ly "global = {"
    @system_staff.to_ly
    ly "}"
    ly "\\new Score"
    ly "\\with"
    ly "{"
    ly "  \\override VerticalAlignment #'max-stretch = #ly:align-interface::calc-max-stretch"
    ly "}"
    ly "{  <<"
    @staff_groups.each do |group|
      ly group.to_ly
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
end


