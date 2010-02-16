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

class VoiceLyrics < Voice
  def process
#    @bars.each{|bar| bar.assign_lyrics}
    @bars.each{|bar| bar.process}
    @bars.each do |bar|
      bar.fix_empty_bar(@voice)
      # Remove everything that is not a NoteRest
      objects = bar.objects.select do |obj|
        (obj.is_a?(NoteRest))
      end
      bar.clear
      bar.add(objects)

      # Replace every NoteRest with a corresponding LyrcItem
      lyric_items = bar.objects.map do |obj|
        li = LyricItem.new
        li.position = obj.position
        li.duration = obj.duration
        li.num_notes = obj.lyrics ? obj.lyrics.num_notes : nil
        li.text = obj.lyrics ? obj.lyrics.text : nil
        li.syllable_type = obj.lyrics ? obj.lyrics.syllable_type : nil
        if obj.is_rest? or !obj.lyrics
          li.hidden = true
        end
        li
      end
      bar.clear
      bar.add(lyric_items) if lyric_items
    end    
  end

	def lyrics_count
    @bars.inject(0) do |sum, bar|
      sum += bar.objects.select{|obj| (obj.is_a?(NoteRest) or obj.is_a?(LyricItem))}.length
    end
	end


  def to_ly(voice)
    s = []
    v = brackets("{\n", "}") do |ss|
      ss << "\\set associatedVoice = #\"#{voice}\"\n"
      @bars.each do |bar|
        ss << bar.to_ly
      end
      ss
    end
    s << v
    s
  end

end
