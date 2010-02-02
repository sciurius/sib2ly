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

require 'chord'

class VoiceChords < Voice
  def process
    @bars.each do |bar|
      create_grid(bar)
    end
  end

  # TODO Make this into a module, since it is used in Voice also
  def VoiceChords.copy(voice, bars, &fun)
    v = VoiceChords.new(voice)
    v.voice = voice
    bars.each do |bar|
      v.bars << Bar.copy(bar, fun)
    end
    v
  end

  def create_grid(bar)
    processed = []
#    return if bar.objects.empty?
    if bar.objects.empty?
      processed << Chord.new("s", "", 0, bar.length)
    else
      if bar.objects.first.position > 0
        processed += fill(0, bar.objects.first.position, nil)
      end
      bar.objects.each_with_index do |obj, i|
        if i == bar.objects.length - 1
          # This is the last object in the bar
          len = bar.length - obj.position
        else
          len = bar.objects[i + 1].position - obj.position
        end
        prefix, postfix = translate_chord_to_ly(obj.text)
        processed << Chord.new(prefix, postfix, obj.position, len)
      end
    end
    bar.objects = processed
  end
end