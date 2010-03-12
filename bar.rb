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

%w{lyricitem barobject noterest barrest keysignature tuplet specialbarline barline_tweak}.each {|obj| require obj}
class Bar
  attr_accessor :length, :number, :system_staff, :time_signature,
    :nr_count, :bar_voice, :parent, :prev
  attr_reader :objects, :prev_noterest_cache
  def initialize(length, bar_voice, number, system_staff, parent)
    @bar_voice = 1
    @length, @bar_voice, @number, @system_staff, @parent = \
      length, bar_voice, number, system_staff, parent
    @objects = [] #[BarEnd.new(self)]
    @prev_noterest_cache = {}
    @grace_add_counter = MAXGRACE
  end

  # Create a bar populated with objects taken from another bar
	# subject to a filter.
  def Bar.copy(other, fun, parent)
    bar = Bar.new(other.length, nil, other.number, other.system_staff, parent)
    sel = other.objects.select do |obj|
      fun.call(obj)
    end
    sel.each do |obj|
      bar.add(obj.clone)
      #bar.add(Marshal.load( Marshal.dump(obj) ))
    end
    bar
  end

  def Bar.new_from_xml(xml, parent)
    bar = Bar.new(xml["Length"].to_i,
      1,
      xml["BarNumber"].to_i,
      xml.parent.name.eql?("SystemStaff"),
      parent)
    xml.children.each do |object|
      if eval("defined? " + object.name) && Class === eval(object.name)
        bar.add(Object::const_get(object.name).new_from_xml(object))
      end
    end
    bar
  end

  # If the bar is musically empty (e.g. bar rest)
  def musically_empty?
    obj_f = objects.select{|obj| !obj.is_a?(BarlineTweak)}
    obj_f.length == 1 and obj_f.first.is_a?(BarRest)
  end

  def contains_music?
    return objects.find do |obj|
      (obj.is_a?(NoteRest) and !obj.is_a?(BarRest) and !obj.hidden)
    end ? true : false
  end

  # Remove the specified objects from the bar.
  def remove(objs)
    @objects -= [*objs]
    link_noterests
  end

  #  def -(objs)
  #    @objects - [*objs]
  #  end

  # Add the specified objects to the bar.
  def add(objs)
    [*objs].each do |obj|
      obj.bar = self
      @objects << obj
      if obj.is_a?(NoteRest) and obj.grace
        obj.internal_priority = @grace_add_counter;
        @grace_add_counter += 1
      else
        @grace_add_counter = MAXGRACE
      end
    end
    sort_objects
    link_noterests # TODO: Only call it when adding NoteRests?
  end

  def link_noterests
    objects.select{|obj| obj.is_a?(NoteRest) and (not obj.grace)}.each do |nr|
      nr.prev = prev_noterest(nr)
    end
    objects.select{|obj| obj.is_a?(NoteRest) and (not obj.grace)}.each do |nr|
      nr.next = next_noterest(nr)
    end
  end
  #  def update_cache
  #    prev_noterest_cache = {}
  #    noterests = objects.select{|obj| obj.is_a?(NoteRest)}
  #    noterests.each{|nr| prev_noterest_cache[nr] = prev_noterest(nr)}
  #  end
  
  #  def insert(idx, objs)
  #    objs = [*objs]
  #    objs.each do |obj|
  #      obj.bar = self
  #      @objects.insert(idx, obj)
  #      idx += 1
  #    end
  #  end

  def clear
    @objects = []
  end
  
  def to_ly
    s = ""
    # handle pickup bar
    if @time_signature
      time = 1024 * @time_signature.numerator / @time_signature.denominator;
      if time != @length
        f = @length.gcd(1024);
        s << "\\partial "+ (1024/f).to_s + "*" + (@length/f).to_s + " "  ;
      end
      #      if @length > time
      #        # This can happen if one abuses Sibelius's key signature in e.g. cadenzas
      #        extra = fill(time, @length - time, @bar_voice)
      #        @objects += extra
      #      end
    end
    # write objects
    s << objects.select { |obj| not (obj.is_a?(Text) or obj.is_a?(Tuplet))}.map do
      |obj| obj.to_ly
    end.join(' ');
    #    # barlines go at the end of the bar
    #    @objects.select{|obj| obj.is_a?(SpecialBarline)}.each do |obj|
    #      s << obj.to_ly
    #    end
    # bar bumber
    s + " % #{number}\n"
  end

  def fix_missing_nr
    last_end = 0
    fixed = []
    voice = nil
    for obj in objects
      if obj.is_a?(NoteRest)
        voice = obj.voice
        if last_end and obj.position > last_end + 1 # extra 1 for rounding errors when in tuplet
          fixed += fill(last_end, obj.position - last_end, voice)
        end
        last_end = obj.position + obj.real_duration.to_i
      end
      fixed << obj
    end
    if last_end > 0 and last_end + 1 < @length
      fixed += fill(last_end, @length  - last_end, voice)
    end
    clear
    add(fixed)
  end

  def fix_empty_bar(voice)
    nr = objects.select{|obj| obj.is_a?(NoteRest)}
    return unless nr.empty?
    return if objects.find{|obj| obj.is_a?(BarRest)}
    index = 0
    ts = objects.find{|obj| obj.is_a?(TimeSignature)}
    index = objects.index(ts) + 1 if ts
    items = objects.select{|obj| obj.is_a?(SystemTextItem)}
    if !items or items.empty?
      br = BarRest.new
      br.duration = Duration.new(@length)
      br.real_duration = Duration.new(@length)
      br.voice = voice# @bar_voice
      br.hidden = true
      add(br)
    else
      #last_nr = nil
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
          add(nr)
          #last_nr = nr
        end
      end
    end
  end

  def fix_overfull_bar
    nr = objects.select{|obj| obj.is_a?(NoteRest) and !obj.is_a?(BarRest) and !obj.grace}
    return if nr.empty?
    last = nil
    nr.each do |n|
      if last and last.position + last.real_duration.duration > n.position + 1
        ratio = last.duration.duration.to_f / last.real_duration.duration.to_f
        last.real_duration = n.position - last.position
        last.duration = (last.real_duration.duration * ratio).to_i
        puts "WARNING: Overfull bar \#" + @number.to_s
      end
      last = n
    end
  end

  def assign_texts
    texts = objects.select{|objt| objt.is_a?(Text)}
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

  def assign_lyrics
    lyrics = objects.select{|obj| obj.is_a?(LyricItem)}
    lyrics.each do |ly|
      unless ly.text.empty?
        #texts.each do |text|
        owner = get_noterest_at(ly.position)
        owner.lyrics = ly if owner
      end
    end
    remove(lyrics)
  end

  def <<(obj)
    assert(obj.is_a?(BarObject))
    add(obj)
  end

  def fix_multiple_barrests
    # Very rarely there would be more than one BarRest in the same voice per bar
    br = objects.select{|obj| obj.is_a?(BarRest)}
    if br.length > 1
      puts "WARNING! There is a bug in the original Sibelius score: more than"
      puts "two BarRests in bar " + @number.to_s + "! Ignoring the extra."
      for i in 1..br.length - 1
        @objects.delete(br[i])
      end
    end
  end

  def delete_empty_texts
    et = (objects.select {|obj| obj.is_a?(Text) and obj.empty?})
    remove(et)
  end

  def process
    #puts "Bar.process called for Bar #{number} in voice #{parent} at staff #{parent.staff}"
    fix_multiple_barrests

    # remove KeySigature from global except in the first bar
    if @system_staff and @number != 1
      remove(@objects.select{|obj| obj.is_a?(KeySignature)})
    end

    

    # move KeySignature to the beginning of the bar
    #    ks = objects.select{|obj| obj.is_a?(KeySignature)}
    #    @objects -= ks
    #    @objects = ks + @objects


    tuplets = @objects.select{|objt| objt.is_a?(Tuplet)}
    nr = @objects.select{|obj| obj.is_a?(NoteRest) and !obj.grace}

    @nr_count = nr.select{|obj| !obj.hidden and !obj.is_a?(BarRest)}.length
    nr.each { |obj| obj.tuplets += tuplets.select { |objt| is_in?(obj, objt) } }
    nr.each { |obj| obj.tuplets.each { |objt| objt.notes << obj } }
    tuplets.each{|objt| objt.notes.last.ends_tuplet += 1}

    nr.each{|obj| obj.process}
    assign_lyrics

    fix_overfull_bar
    assign_grace_notes
    fix_missing_nr
    move_barlines
    fix_barlines if @parent.next_bar(self).nil?
    process_empty_slurs
    #process_double_slurs (when in Sibelius created two identical slurs, it looks as one slur)
    assign_texts     # assign text to NoteRests
    assign_lyrics
    #compute_double_tremolo_starts_ends
    sort_objects
    # determine_voice_mode
  end

  # Sort BarObjects by position
  def sort_objects
    @objects.sort! do |x, y|
      if x.position == y.position
        y.priority <=> x.priority
      else
        x.position <=> y.position
      end
    end
  end

  def assign_grace_notes
    # assign graces to NoteRests
    nr = @objects.select{|obj| obj.is_a?(NoteRest)}
    graces = nr.select{|obj| obj.grace}
    graces.each  do |grace|
      owner = get_noterest_at(grace.position)
      owner.grace_notes << grace if owner
    end
    @objects -= graces
  end

  def move_barlines
    prev_bar = @parent.prev_bar(self)
    @objects.select{|obj| obj.is_a?(SpecialBarline) and obj.position.eql?(0)}.each do |barline|
      barline.position = prev_bar.length
      if prev_bar
        prev_bar.add(barline)
      end
      remove(barline)
    end
    prev_bar.fix_barlines if prev_bar
  end

  def fix_barlines
    end_barlines = @objects.select{|obj| obj.is_a?(SpecialBarline) and obj.position.eql?(@length)}
    if end_barlines.length.eql?(2)
      #start + end repeat
      remove(end_barlines.first)
			end_barlines.last.barline_type = "DoubleRepeat"
    end
    if end_barlines.length.zero?
      standart_barline = SpecialBarline.new
      standart_barline.barline_type = "Normal"
      standart_barline.position = @length
      add(standart_barline)
    end
    #add tweaks for some barlines
    @objects.select{|obj| obj.is_a?(SpecialBarline) and ["Short", "BetweenStaves"].include?(obj.barline_type) }.each do |obj|
      verbose("Creating tweaks to "+obj.to_s)
      ss = BarlineTweak.new
      ss.tweak_type = obj.barline_type
      ss.position = @length
      add ss
      if (next_bar = @parent.next_bar(self))
        ss = BarlineTweak.new
        ss.tweak_type = obj.barline_type+"End"
        ss.position = next_bar.length
        next_bar.add ss
      end
    end
    #sort_objects
  end

  def process_empty_slurs
    slurs = objects.select { |obj| obj.is_a?(Slur) }
    empty = slurs.select{|obj| obj.start_bar_number == obj.end_bar_number and obj.position == obj.end_position}
    empty.each do |slur|
      nr = get_noterest_at(slur.position)
      unless nr.nil?
        nr.grace_slurred = true if nr.grace_notes.length
      end
    end
    @objects -= empty
  end
  #  # Determine which NoteRests start a double-tremolo
  #  def compute_double_tremolo_starts_ends
  #    nr = @objects.select{|obj| obj.is_a?(NoteRest)}
  #
  #    num_starts = 0
  #    num_ends   = 0
  #    starts = false
  #    # For each NoteRest in the bar
  #    tremolos = []
  #    nr.each do |n|
  #      # A NoteRest starts a double tremolo if double_tremolos is set and
  #      # the previous NoteRest does not start a double tremolo.
  #      if n.double_tremolos > 0 and !starts
  #        n.starts_tremolo = starts = true
  #        num_starts = num_starts + 1
  #      else
  #        starts = n.starts_tremolo = false
  #      end
  #    end
  #
  #    nr.each do |n|
  #      # A NoteRest ends a tremolo if the previous NoteRest
  #      # starts a double tremolo.
  #      if n.prev and n.prev.starts_tremolo
  #        n.ends_tremolo  = true
  #        num_ends = num_ends + 1
  #        tremolos << DoubleTremolo.new(n.prev, n)
  #      end
  #    end
  #
  #    # Check if the number of tremolo starts equals the number of ends
  #    unless num_starts == num_ends
  #      puts "WARNING! I have found a double tremolo that does not have ``the second part'' to it, in bar " + @number.to_s
  #      puts "Check, in the original Sibelius score, if some notes or rests in this bar have an incomlete tremolo."
  #      # This bug occurs in e.g. /Example Scores/Hebrides.sib
  #    end
  #
  #    # Delete all notes that are in double tremolos from the bar
  #    tremolos.each do |trem|
  #      @objects.delete(trem.first)
  #      @objects.delete(trem.second)
  #    end
  #
  #    # Add tremolos to the bar instead
  #    add(tremolos)
  #  end

  # Returns the first NoteRest to which point +pos+ belongs or nil if no
  # such NoteRest is found.
  def get_noterest_at(pos)
    noterests = @objects.select{|obj| (obj.is_a?(NoteRest) and (not obj.grace))}
    result = noterests.find do |nr|
      (nr.position == pos) or \
        (nr.position < pos and nr.position + nr.real_duration.to_i > pos)
    end
    result
  end

  def get_nearest_noterest(pos, ignore_rests = false)
    noterests = @objects.select{|obj| obj.is_a?(NoteRest) and (not obj.grace) \
        and (!ignore_rests or !obj.is_rest?)}
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

  #  # Returns the previous bar
  #  def prev
  #    parent.prev_bar(self)
  #  end

  def last_noterest
    noterests = objects.select {|obj| (obj.is_a?(NoteRest) and (not obj.grace))}
    return noterests.last unless noterests.empty?
    return nil if !prev
    return prev.last_noterest
  end

  def prev_noterest(nr)
    p = prev_noterest_cache[nr]
    #    puts "In cache" if p
    return p if p
    #    puts "Cache miss"
    noterests = objects.select {|obj| (obj.is_a?(NoteRest) and (not obj.grace))}
    idx = noterests.index(nr)
    return nil if idx.nil?
    if idx > 0
      p = noterests[idx - 1]
      prev_noterest_cache[nr] = p
      return p
    end
    return nil if !prev
    p = prev.last_noterest
    prev_noterest_cache[nr] = p if p
    p
  end

  def next_noterest(nr)
    objects.select {|obj| (obj.is_a?(NoteRest) and (not obj.grace))}.find {|n| n.prev == nr}
  end

  def to_s
    "Bar #{@number}"
  end
end
