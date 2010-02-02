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

class Text < BarObject
  EXPRESSION = {
    "f" => "\\f",
    "ff" => "\\ff",
    "fff" => "\\fff",
    "ffff" => "\\ffff",
    "p" => "\\p",
    "pp" => "\\pp",
    "ppp" => "\\ppp",
    "pppp" => "\\ppp",
    "mf" => "\\mf",
    "mp" => "\\mp",
    "sf" => "\\sf",
    "fz" => "\\fz"
  }
  attr_accessor :text, :style_id
  def initialize

  end

  def initialize_from_xml(xml)
    super(xml)
    @text = xml["Text"].split("~").first # get visible part of text
    @text = "" unless @text
    @style_id = xml["StyleId"]
  end

  def Text.new_from_xml(xml)
    t = Text.new
	t.initialize_from_xml(xml)
    t
  end

  def to_ly
    s = ""
    if !@text or @hidden or @text.empty?
      return s
    end
    case @style_id
    when "text.staff.expression"
      exp = EXPRESSION[@text.downcase]
      s << exp if exp
    when "text.staff.technique"
      if dy < 0
        s << "_"
      else
        s << "^"
      end
      s << "\\markup \{\\italic \{" + @text + "\}\}"
    when "text.staff.space.chordsymbol"
      s << "^\\markup \{\"" + @text + "\"\}"
    end
    return s
  end
end
