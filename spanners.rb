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

require 'barobject'

class Spanner < BarObject
  attr_accessor :start_bar_number, :end_bar_number,
    :end_position, :style_id, :nr_begin, :nr_end, :text_begin, :text_end

  def initialize
    @text_begin = ""
    @text_end = ""
  end

  def initialize_from_xml(xml)
    super(xml)
    @start_bar_number = xml.parent["BarNumber"].to_i - ($first_bar - 1)
    @end_bar_number = xml["EndBarNumber"].to_i - ($first_bar - 1)
    @end_position = xml["EndPosition"].to_i
    @style_id = xml["StyleId"]
  end
  def text_begin_before
    return ''
  end
  def Spanner.new_from_xml(xml)
    s = Spanner.new
    s.initialize_from_xml(xml)
    s
  end

  def to_ly
    return ""
  end
end

class Slur < Spanner
  attr_accessor :is_phrasing
 
  def initialize
    @text_begin = @is_phrasing ? "\(" : "("
    @text_end = @is_phrasing ? "\)" : ")"
  end

  def text_begin
    @is_phrasing ? "\\(" : "("
  end

  def text_end
    @is_phrasing ? "\\)" : ")"
  end

  def Slur.new_from_xml(xml)
    sl = Slur.new
    sl.initialize_from_xml(xml)
    sl
  end
end

class Trill < Spanner
  def initialize
    @text_begin = "\\startTrillSpan "
    @text_end = "\\stopTrillSpan "
  end

  def Trill.new_from_xml(xml)
    sl = Trill.new
    sl.initialize_from_xml(xml)
    sl
  end
end

class CrescendoLine < Spanner
  def initialize
    @text_begin = "\\<"
    @text_end = "\\!"
  end
  def CrescendoLine.new_from_xml(xml)
    cl = CrescendoLine.new
    cl.initialize_from_xml(xml)
    cl
  end
end

class DiminuendoLine < Spanner
  def initialize
    @text_begin = "\\>"
    @text_end = "\\!"
  end
  def DiminuendoLine.new_from_xml(xml)
    cl = DiminuendoLine.new
    cl.initialize_from_xml(xml)
    cl
  end
end

class ArpeggioLine < Spanner
  def initialize
    @text_begin = ""
    @text_end = "\\arpeggio "
  end
  def ArpeggioLine.new_from_xml(xml)
    al = ArpeggioLine.new
    al.initialize_from_xml(xml)
    al
  end
end



OTTAVA = {
  "line.staff.octava.minus15" => -2,
  "line.staff.octava.minus8" => -1,
  "line.staff.octava.plus8" => 1,
  "line.staff.octava.plus15" => 2
}

class OctavaLine < Spanner
  def initialize

  end
  def text_begin_before
    ot = OTTAVA[@style_id]
    if ot
      return '\\ottava #' + ot.to_s + ' '
    else
      return ''
    end
  end
  def ottavation
    return OTTAVA[@style_id]
  end
  def text_begin
    return ''
  end
  def text_end
    return '\\ottava #0 '
  end
  def OctavaLine.new_from_xml(xml)
    ol = OctavaLine.new
    ol.initialize_from_xml(xml)
    ol
  end
end