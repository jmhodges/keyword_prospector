# 
# (C) 2008 Los Angeles Times
# 
class Match
  include Comparable
  attr_accessor :keyword, :start_idx, :end_idx, :output

  def initialize(keyword, start_idx=0, end_idx=0, output=nil)
    self.keyword = keyword
    self.start_idx = start_idx
    self.end_idx = end_idx
    self.output = output
  end

  def <=>(other)
    retval = start_idx <=> other.start_idx
    if (retval == 0)
      end_idx <=> other.end_idx
    else
      retval
    end
  end

  def overlap?(other)
    if (start_idx == other.start_idx || end_idx == other.end_idx)
      return true
    elsif (start_idx < other.start_idx)
      return end_idx > other.start_idx
    elsif (start_idx > other.start_idx)
      return other.end_idx > start_idx
    end
  end

  def length
    end_idx - start_idx
  end
end
