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

class BarRest < NoteRest
  attr_accessor :length, :real_duration, :texts
  def initialize
    super
    @position = 0
    @texts = []
    @real_duration = @length
  end

  def initialize_from_xml(xml)
    super(xml)
    parent_bar = xml.parent
    @length = parent_bar["Length"].to_i
    @position = 0
    @real_duration = @length
  end

  def BarRest.new_from_xml(xml)
    br = BarRest.new
    br.initialize_from_xml(xml)
    br
  end

  def is_rest?
    true
  end

  def to_ly
    s = ""
    s << voice_mode_to_ly

    s << " " if !@texts.empty?
    f = gcd(@length, 1024);
    s << grace_to_ly
    if 1 == voice
      s << "R1*"
    else
      s << "s1*"
    end
    s << (@length/f).to_s + "/" + (1024/f).to_s;
    @texts.each{|text| s << text.to_ly}
    return s
  end
end