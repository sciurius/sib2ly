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

def safe_instrument_name(name)

  s = name.gsub(" ", "")
  s = s.gsub("/", "")
  s = s.gsub("(", "")
  s = s.gsub(")", "")
  s = s.gsub(",", "")
  s = s.gsub("-", "")
  s = s.gsub("+", "")
  s = s.gsub(".", "")
  DIGITS.each{|key,value| s = s.gsub(key, value)}

  return s
  # todo: strip numbers
end

def written_name2ly(wn)
  # TODO: quarter-tones
  wn = wn.downcase
  case wn.length
  when 1
    return wn;
  when 2
    if wn[1..1] == '#'
      return wn[0..0] + 'is'
    else
      return wn[0..0] + 'es'
    end
  when 3
    if wn[1..2] == '##'
      return wn[0..0] + 'isis'
    else
      return wn[0..0] + 'eses'
    end
    return wn;
  else
    return "";
  end
end

def gcd(a, b)
  a.gcd(b)
end

def get_octave (old, new)
  str = ''
  if old == nil
    return ""
  end
  pitch_margin = 3
  note = new
  while (old - note > pitch_margin )
    str << ',';
    note += 7;
  end
  if (str.length>0)
    return str
  end
  while  (old - note < -pitch_margin )
    str << '\'';
    note -= 7;
  end
  return str
end

def clef2ly(clef)
  if clef
    ly_clef = CLEFS[clef]
    if ly_clef
      return "\\clef " + ly_clef
    else
      return ""
    end
  else return ""
  end
end

def is_in?(nr, tuplet)
  if (nr.position < tuplet.position) or (nr.position >= tuplet.position + tuplet.played_duration)
    return false
  end
  return true
end

def get_tremolo_duration(d, trem)
  if d <= 128
    return d/(2**trem)
  else
    return 1024/(2**(trem+2))
  end
end

def fill_with_rests(pos, duration, voice)
  nrs = []
  # creates an array of NoteRests to fill a duration
  (0..10).each do |i|
    pow = 2**i
    if duration & pow != 0
      nr = NoteRest.new
      nr.position = pos
      pos += pow
      nr.duration = pow
      nr.hidden = true
      nr.voice = voice
      nr.process
      nrs << nr
    end
  end
  nrs
end

def duration2ly(dur)
  return '0' if 0 == dur
  l = 1;
  while dur * l < 1024
    l *= 2;
  end
  remains = dur - (1024 / l);
  dots = 0
  dotd = 512 / l;
  while (remains > 0 and dotd > 0)
    remains -= dotd
    dotd /= 2
    dots += 1
  end
  result = l.to_s;
  (dots).times {result << '.'}
  return result
end

def make_out_filename(in_file)
  in_file.chomp(File.extname(in_file)) + ".ly"
end

def escape_quotes(str)
  str.gsub('"', '\"')
end