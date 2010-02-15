require 'assert'
#require 'comparable'

class Duration
  include Comparable
  attr_accessor :duration

  def initialize(duration)
    if duration.is_a?(self.class)
      @duration = duration.duration
    else
    assert(duration.to_i == duration)
    @duration = duration
    end
  end

  def to_i
    @duration.to_i
  end

  # Returns the duration as a fraction of the whole, as string.
  def as_fraction(whole = 1024)
    f = @duration.gcd(whole)
    "#{(@duration/f)}/#{(whole/f)}"
  end

  def Duration.count_trailing_zeros(v)
    raise "The number must be a positive integer." unless v > 0
    v = (v ^ (v - 1)) >> 1 # Set v's trailing 0s to 1s and zero rest
    q = 0
    while v > 0
      q += 1
      v >>= 1
    end
    q
  end

  def coerce(other)
    return  self, Duration.new(other)
  end

  def + other
    if other.is_a?(self.class)
      self.class.new(duration + other.duration)
    else
      self.class.new(duration + other)
    end
  end

  def * other
    if other.is_a?(self.class)
      self.class.new(duration * other.duration)
    else
      self.class.new(duration * other)
    end
  end

    def / other
    if other.is_a?(self.class)
      self.class.new(duration / other.duration)
    else
      self.class.new(duration / other)
    end
  end

  def - other
    if other.is_a?(self.class)
      self.class.new(duration - other.duration)
    else
      self.class.new(duration - other)
    end
  end

  def <=> other
    if other.is_a?(self.class)
      duration <=> other.duration
    else
      duration <=> other
    end
  end

  def to_ly
    # Factor duration into 2^q * (2^(n-q+1) - 1).
    # If it is doable, then the duration is expressible as:
    # WHOLE/(2^n) with (n-q) dots.
    q = Duration.count_trailing_zeros(@duration)
    dd = (@duration / (2**q)) + 1 # dd = 2^(n-q+1)
    nq = Duration.count_trailing_zeros(dd)
    if 2**nq == dd
      # Yes, we can represent the duration as note with dots
      dots = nq - 1
      value = 2**(nq + q - 1)
      assert(value <= 2048, \
          "Note durations must not be greater than a \\breve with dots.")
      if value > 1024
        s = "\\breve "
      else
        s = (1024/value).to_s
      end
      dots.times {s << '.'}
    else
      s = "1*" + as_fraction
    end
    s
  end

  def to_s
    to_ly
  end
end