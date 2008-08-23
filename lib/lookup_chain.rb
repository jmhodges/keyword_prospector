# 
# (C) 2008 Los Angeles Times
# 
require 'enumerator'

module KeywordUtilities
  # Manages a list of lookup objects, prioritizing the matches from the earlier
  # objects over matches from previous objects in cases of exact collisions or
  # cases where two matches have the same length.  Otherwise, when there are
  # overlaps, the longest match always wins.
  #
  # A lookup object is anything with a process method that accepts text and
  # returns an array of Match objects.
  class LookupChain
    # Returns the array of lookup objects used internally.
    attr_reader :lookups

    # Initialize with an array of lookup objects.
    def initialize(*lookups)
      @lookups = []
      lookups.flatten!

      lookups.each do |lookup|
        check_lookup(lookup)
        @lookups << lookup
      end
    end

    # Add a lookup object to the end of the chain.
    def <<(lookup)
      check_lookup(lookup)

      self.lookups << lookup
    end

    # Process matches in the text in all of the lookup objects in the chain.
    # If there are overlaps, it returns the longest match.  If there are
    # collisions (exact matches), it prefers the match from the object earliest
    # in the list.
    def process(text)
      matches = []

      @lookups.each do |lookup|
        new_matches = lookup.process(text)
        matches += new_matches
        matches.sort!
        i = 0
        while(i+1 < matches.size)
          (match1, match2) = matches[i,2]

          if(match1.overlap?(match2))
            if (match1.length > match2.length)
              matches.delete_at(i+1)
            elsif (match1.length < match2.length)
              matches.delete_at(i)
            else
              if (new_matches.include?(match1))
                matches.delete_at(i)
              else
                matches.delete_at(i+1)
              end
            end
          else
            i += 1
          end
        end
      end

      return matches
    end

    private
    # Verify that the object provided is a valid lookup object.
    def check_lookup(lookup)
      raise ArgumentError.new("lookup objects must respond to process method") unless lookup.respond_to?(:process)
    end
  end
end