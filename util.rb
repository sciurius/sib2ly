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

require 'roman'

def unescape_xml(text)
  text.gsub!('&quot;', "\"")
  text.gsub!('&apos;', "'")
  text.gsub!('&amp;', "&")
  text.gsub!('&gt;', ">")
  text.gsub!('&lt;', "<")
  text
end

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


def written_name2ly(wn)
  wn.downcase!
  match = /^([a-g])(-|b|b-|bb|\+|#|#\+|x|)$/.match(wn)
  match[1] + ACCIDENTALS[match[2]]
end

def pitch2diatonic(pitch, wn)
  wn.downcase!
  match = /^([a-g])(-|b|b-|bb|\+|#|#\+|x|)$/.match(wn)
  note = match[1]
  accidental = ACCIDENTALS_SEMITONES[match[2]]
  (pitch - accidental).div(12) * 7 + DIATONIC[note]
end
  
def get_octave (old, new)
  str = ''
	return "" unless old
  pitch_margin = 3
  note = new
  while (old - note > pitch_margin)
    str << ',';
    note += 7;
  end
  return str if (str.length>0)
  while  (old - note < -pitch_margin)
    str << '\'';
    note -= 7;
  end
  str
end

#def get_octave(old_pitch, old_name, new_pitch, new_name)
#
#end


def is_in?(nr, tuplet)
  if (nr.position < tuplet.position) or (nr.position >= tuplet.position + tuplet.played_duration)
    return false
  end
  return true
end

def get_tremolo_duration(d, trem)
  if d <= 128
    return d / (2**trem)
  else
    return 1024 / (2**(trem + 2))
  end
end

# def fill(pos, duration, voice, noterest = nil)
#  nrs = []
#  # creates an array of NoteRests to fill a duration
#  (0..10).each do |i|
#    pow = 2**i
#    if duration & pow != 0
#      if not noterest
#        nr = NoteRest.new
#        nr.hidden = true
#      else
#        nr = NoteRest.copy(noterest)
#      end
#      nr.position = pos
#      pos += pow
#      nr.duration = pow
#      nr.voice = voice
#      nr.process
#      nrs << nr
#    end
#  end
#  nrs
# end

# Returns an array of NoteRests that are needed to fill a "duration" long
# segment starting at "pos"
def fill(pos, duration, voice, noterest = nil)
  nrs = []
  note = 1024
  remaining = duration
  while note > 1
    if remaining >= note
      # Insert a NoteRest of length "note"
      if not noterest
        nr = NoteRest.new
        nr.hidden = true
      else
        nr = NoteRest.copy(noterest)
      end
      nr.position = pos
      nr.duration = note
      nr.voice = voice
      nr.process
      nrs << nr

      pos += note
      remaining -= note
    else
      note /= 2
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
  result
end

def make_out_filename(in_file)
  in_file.chomp(File.extname(in_file)) + ".ly"
end

def escape_quotes(str)
  str.gsub('"', '\"')
end


  def brackets(open, close)
    s = []
    s << open
    s << yield([]) if block_given?
    s << close
    s.join
  end
