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

class Bar
  attr_accessor :objects, :length, :number, :system_staff, :time_signature,
    :nr_count, :bar_voice
  def initialize(length, bar_voice, number, system_staff)
    @length, @bar_voice, @number, @system_staff = length, bar_voice, number, system_staff
    @objects = []
  end

  # Create a bar populated with object of a specific objects
  # taken from another bar.
  def Bar.copy(other, fun)
    bar = Bar.new(other.length, nil, other.number, other.system_staff)
    bar.objects += other.objects.select do |obj|
      # obj.voice == voice or (voice == 1 and obj.voice == 0) or (obj.is_a?(OctavaLine))
      fun.call(obj)
    end
    bar
  end

  def Bar.new_from_xml(xml)
    bar = Bar.new(xml["Length"].to_i,
      1,
      xml["BarNumber"].to_i,
      xml.parent.name.eql?("SystemStaff"))
    xml.children.each do |object|
      if eval("defined? " + object.name) && Class === eval(object.name)
        bar.objects << Object::const_get(object.name).new_from_xml(object)
      end
    end
    bar
  end

  # If the bar is musically empty (e.g. bar rest)
  def is_empty?
    @objects.length == 1 and @objects.first.is_a?(BarRest)
  end

  def to_ly
    s = "";
    # handle pickup bar
    if @time_signature
      time = 1024 * @time_signature.numerator / @time_signature.denominator;
      if time != @length
        f = gcd(@length, 1024);
        s << "\\partial "+ (1024/f).to_s + "*" + (@length/f).to_s + " "  ;
      end
    end
    # write objects
    @objects.select{|obj| not (obj.is_a?(Text) or obj.is_a?(Tuplet) or obj.is_a?(SpecialBarline))}.each do |obj|
      s << obj.to_ly
    end
    # barlines go at the end of the bar
    @objects.select{|obj| obj.is_a?(SpecialBarline)}.each do |obj|
      s << obj.to_ly
    end
    # bar bumber
    return s + " |%" + number.to_s + "\n"
  end

  def fix_missing_nr
    last_end = 0
    fixed = []
    voice = nil
    for obj in @objects
      if obj.is_a?(NoteRest)
        voice = obj.voice
        if last_end and obj.position > last_end + 1 # extra 1 for rounding errors when in tuplet
          fixed += fill(last_end, obj.position - last_end, voice)
        end
        last_end = obj.position + obj.real_duration
      end
      fixed << obj
    end
    if last_end > 0 and last_end + 1 < @length
      fixed += fill(last_end, @length  - last_end, voice)
    end
    @objects = fixed
  end

  def fix_empty_bar(voice)
    nr = @objects.select{|obj| obj.is_a?(NoteRest)}
    if nr.empty? # there are no NoteRests
      unless @objects.find{|obj| obj.is_a?(BarRest)} # and no BarRests
        index = 0
        ts = @objects.find{|obj| obj.is_a?(TimeSignature)}
        index = @objects.index(ts) + 1 if ts
        items = @objects.select{|obj| obj.is_a?(SystemTextItem)}
        if !items or items.empty?
          @objects.insert(index, BarRest.new)
          @objects[index].duration = @length
          @objects[index].real_duration = @length
          @objects[index].voice = voice# @bar_voice
          @objects[index].hidden = true
        else
          last_nr = nil
          items.each_with_index do |i, index|
            i.position /= 32
            i.position *= 32
            pos = i.position
            len = if index + 1 < items.length
              items[index + 1].position - pos
            else
              @length - pos
            end
            len = 32 * (len / 32)
            if len > 0
              nr = NoteRest.new
              nr.position = pos
              nr.duration = len
              nr.hidden = true
              nr.voice = nil
              nr.process
              @objects << nr
              last_nr = nr
            end
          end
        end
      end
    end
  end

  def fix_overfull_bar
    nr = @objects.select{|obj| obj.is_a?(NoteRest) and !obj.is_a?(BarRest) and !obj.grace}
    return if nr.empty?
    last = nil
    nr.each do |n|
      if last and last.position + last.real_duration > n.position + 1
        ratio = last.duration / last.real_duration
        last.real_duration = n.position - last.position
        last.duration = last.real_duration * ratio
        puts "WARNING: Overfull bar \#" + @number.to_s
      end
      last = n
    end
  end

  #  def determine_voice_mode
  #    # Determine, for each NoteRest, if it's in \oneVoice mode.
  #    # A NoteRest is in \oneVoice mode if there are no NoteRests in
  #    # other voices coinciding with it.
  #
  #    # Select non-hidden, non-grace noterests
  #    nr_ngnh = @objects.select{|obj|obj.is_a?(NoteRest) and not obj.grace and not obj.hidden}
  #    nr_ngnh.each do |this|
  #      this.one_voice = !nr_ngnh.find do |other|
  #        other.voice != this.voice and not
  #        (other.position >= this.position + this.duration or
  #            this.position >= other.position + other.duration) and
  #          !other.hidden
  #      end
  #    end
  #  end

  def assign_texts
    texts = @objects.select{|objt| objt.is_a?(Text)}
    texts.select{|text| not text.is_a?(SystemTextItem)}.each do |text|
      #texts.each do |text|
      owner = get_noterest_at(text.position)
      owner.texts << text if owner
    end
    texts.select{|text| text.is_a?(SystemTextItem)}.each do |text|
      #texts.each do |text|
      owner = get_noterest_at(text.position)
      owner.texts_before << text if owner
    end
  end

  def process
    # Very rarely there would be more than one BarRest in the same voice per bar
    br = @objects.select{|obj| obj.is_a?(BarRest)}
    if br.length > 1
      puts "WARNING! There is a bug in the original Sibelius score: more than"
       puts "two BarRests in bar " + @number.to_s + "! Ignoring the extra."
       for i in 1..br.length - 1
         @objects.delete(br[i])
       end
    end


    # remove KeySigature from global except in the first bar
    if @system_staff and @number != 1
      @objects -= @objects.select{|obj| obj.is_a?(KeySignature)}
    end

    

    # move KeySignature to the beginning of the bar
    ks = @objects.select{|obj| obj.is_a?(KeySignature)}
    @objects -= ks
    @objects = ks + @objects

    tuplets = @objects.select{|objt| objt.is_a?(Tuplet)}
    nr = @objects.select{|obj| obj.is_a?(NoteRest) and !obj.grace}
    @nr_count = nr.select{|obj| !obj.hidden and !obj.is_a?(BarRest)}.length
    nr.each { |obj| obj.tuplets += tuplets.select { |objt| is_in?(obj, objt) } }
    nr.each { |obj| obj.tuplets.each { |objt| objt.notes << obj } }
    tuplets.each{|objt| objt.notes.last.ends_tuplet += 1}
    nr.each{|obj| obj.process}

    fix_overfull_bar
    assign_grace_notes
    fix_missing_nr
    assign_texts     # assign text to NoteRests
    compute_double_tremolo_starts_ends
    sort_objects
    # determine_voice_mode
  end

  # Sort BarObjects by position
  def sort_objects
    @objects.sort! do |x, y|
      x.position <=> y.position
    end
  end

  def assign_grace_notes
    # assign graces to NoteRests
    nr = @objects.select{|obj| obj.is_a?(NoteRest)}
    graces = nr.select{|obj| obj.grace}
    graces.each  do |grace|
      owner = get_noterest_at(grace.position)
      owner.grace_notes << grace      if owner
    end
    @objects -= graces
  end

  # Determine which NoteRests start a double-tremolo
  def compute_double_tremolo_starts_ends
    nr = @objects.select{|obj| obj.is_a?(NoteRest)}

    num_starts = 0
    num_ends   = 0
    starts = false
    # For each NoteRest in the bar
    tremolos = []
    nr.each do |n|
      # A NoteRest starts a double tremolo if double_tremolos is set and
      # the previous NoteRest does not start a double tremolo.
      if n.double_tremolos > 0 and !starts
        n.starts_tremolo = starts = true
        num_starts = num_starts + 1
      else
        starts = n.starts_tremolo = false
      end
    end

    nr.each do |n|
      # A NoteRest ends a tremolo if the previous NoteRest
      # starts a double tremolo.
      if n.prev and n.prev.starts_tremolo
        n.ends_tremolo  = true
        num_ends = num_ends + 1
        tremolos << DoubleTremolo.new(n.prev, n)
      end
    end

    # Check if the number of tremolo starts equals the number of ends
    unless num_starts == num_ends
      puts "WARNING! I have found a double tremolo that does not have ``the second part'' to it, in bar " + @number.to_s
      puts "Check, in the original Sibelius score, if some notes or rests in this bar have an incomlete tremolo."
      # This bug occurs in e.g. /Example Scores/Hebrides.sib
    end

    # Delete all notes that are in double tremolos from the bar
    tremolos.each do |trem|
      @objects.delete(trem.first)
      @objects.delete(trem.second)
    end
    
    # Add tremolos to the bar instead
    @objects += tremolos


  end

  def get_noterest_at(pos)
    noterests = @objects.select{|obj| (obj.is_a?(NoteRest) and (not obj.grace))}
    for nr in noterests
      if (nr.position == pos)
        return nr
      end
    end
    for nr in noterests
      if (nr.position < pos and nr.position + nr.real_duration > pos)
        return nr
      end
    end

    return nil
  end

  def get_nearest_noterest(pos, ignore_rests = false)
    noterests = @objects.select{|obj| obj.is_a?(NoteRest) and (not obj.grace) and (!ignore_rests or !obj.is_rest?)}
    min = 1e99
    argmin = nil
    for nr in noterests
      dist = (nr.position - pos).abs
      if dist < min
        min = dist
        argmin = nr
      end
    end
    return argmin, min
  end
end
