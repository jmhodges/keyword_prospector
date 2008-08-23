# 
# (C) 2008 Los Angeles Times
# 

module KeywordUtilities
  # An object for holding information about a match.
  class Match
    include Comparable

    # The keyword matched.
    attr_accessor :keyword

    # The index in the matched text where the keyword begins.
    attr_accessor :start_idx

    # The index in the matched text one past the end of the keyword matched.
    attr_accessor :end_idx

    # The output object associated with the keyword.
    attr_accessor :output

    # Initialize the match object.
    def initialize(keyword, start_idx=0, end_idx=0, output=nil)
      self.keyword = keyword
      self.start_idx = start_idx
      self.end_idx = end_idx
      self.output = output
    end

    # Compare to another match object.  One match object comes before another
    # if its start index is less than the other's start index.  If start indexes
    # are equal, then the object ending first comes first in sequence.
    def <=>(other)
      retval = start_idx <=> other.start_idx
      if (retval == 0)
        end_idx <=> other.end_idx
      else
        retval
      end
    end

    # Return true if two Match objects overlap.
    def overlap?(other)
      if (start_idx == other.start_idx || end_idx == other.end_idx)
        return true
      elsif (start_idx < other.start_idx)
        return end_idx > other.start_idx
      elsif (start_idx > other.start_idx)
        return other.end_idx > start_idx
      end
    end

    # Return the length of the match.
    def length
      end_idx - start_idx
    end
  end
end