# 
# (C) 2008 Los Angeles Times
# 
$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'state'
require 'match'

module KeywordUtilities
  
  class Position < Struct.new(:begin, :end); end

  # KeywordProspector takes a collection of words, and optionally their
  # associated outputs, and builds a match tree for running matches of the
  # keywords against provided text.  While construction of the Aho-Corasick
  # tree takes a long time when there are many keywords, matching runs in time
  # proportional to the length of the text provided.  So, even if you have
  # tens of thousands of keywords to match against, matching will still be
  # very fast.
  class KeywordProspector
    # If words is provided, each word is added to the tree and the tree is
    # initialized.  Otherwise, call add for each word to place in the dictionary.
    def initialize(words=nil)
      @start = State.new(0, 0, [])
      if(words)
        words.each{|word| add word}

        construct_fail
      end
    end
  
    # Add an entry to the tree.  The optional output parameter can be any object,
    # and will be returned when this keyword is matched.  If the entry has a
    # _keywords_ method, it should return a collection of keywords.  In this
    # case, the output will be added for each keyword provided.  If output is
    # not provided, the entry is returned.
    def add(entry, output=nil)
      output ||= entry

      if (entry.respond_to?(:keywords))
        entry.keywords.each do |keyword|
          add_internal(keyword, output)
        end
      else
        add_internal(entry, output)
      end
    end
  
    # Call once after adding all entries.  This constructs failure links in the
    # tree, which allow the state machine to move a single step with every input
    # character instead of backtracking back to the beginning of the tree when
    # a partial match fails to match the next character.
    def construct_fail
      queue = Queue.new
      @start.values.each do |value|
        value.fail = @start
        value.fail_increment = 1
        queue.push value
      end
    
      prepare_root
    
      while !queue.empty?
        r = queue.pop
        r.keys.each do |char|
          s = r[char]
          queue.push s
          state = r.fail
          increment = 0
          while !state[char]
            increment += state.fail_increment
            state = state.fail
          end
          s.fail = state[char]
          s.fail_increment = increment
        end
      end
    end
  
    # Process the provided text for matches.  Returns an array of Match objects.
    # Each Match object contains the keyword matched, the start and end position
    # in the text, and the output object specified when the keyword was added
    # to the search tree.  The end position is actually the position of the
    # character immediately following the end of the keyword, such that end
    # position minus start position equals the length of the keyword string.
    #
    # Options:
    # * :filter_overlaps - When multiple keywords overlap, filter out overlaps
    #   by choosing the longest match.
    def process(bytes, options={})
      retval = [] unless block_given?
      state = @start
      position = Position.new(0, 0)
      bytes.each_byte do |a|
        state = state.transition(a, position)
        if state.keyword && is_position_around_word?(bytes, position)
          match = Match.new(state.keyword, position.begin, position.end, state.output)

          # do something with the found item
          if block_given?
            yield match
          else
            retval << match
          end
        end
      end

      if retval
        if (options[:filter_overlaps])
          KeywordProspector.filter_overlaps(retval)
        end
      end

      return retval
    end
  
    def is_position_around_word?(bytes, position)
      position_starts_word?(bytes, position) && 
      position_after_word_end?(bytes, position)
    end
  
    def position_starts_word?(bytes, position)
      position.begin == 0 || KeywordProspector.word_delimiter?(bytes[position.begin-1])
    end
  
    def position_after_word_end?(bytes, position)
      (position.end == bytes.length || KeywordProspector.word_delimiter?(bytes[position.end]))
    end
  
    # Filters overlaps from an array of results.  If two results overlap, the
    # shorter result is removed.  If both results have the same length, the
    # second result is removed.
    def self.filter_overlaps(results)
      i = 0
      while (i < results.size-1)
        a = results[i]
        b = results[i+1]
        if a.overlap?(b)
          if (a.length < b.length)
            results.delete_at(i)
          else
            results.delete_at(i+1)
          end
        end
        i += 1
      end
    end
  
    private
    WORD_CHARS=[?a..?z, ?A..?Z, ?0..?9, ?_]

    # Returns true if the character provided is a word character.
    def self.word_char?(char)
      WORD_CHARS.each do |spec|
        return true if spec === char
      end

      return false
    end

    # Returns true if the character provided is not a word character.
    def self.word_delimiter?(char)
      return !word_char?(char)
    end

    # Add a single keyword to the tree.
    def add_internal(keyword, output=nil)
      cur_state = @start
      # assuming a string here
      keyword.each_byte {|c| cur_state = cur_state.insert_next_state(c)}
      cur_state.keyword = keyword
      cur_state.output = output
    end

    # Used internally to create links from root back to itself for all states
    # that are not beginnings of known keywords.
    def prepare_root
      0.upto(255) do |i|
        @start[i] = @start if !@start[i]    
      end
    end
  end
end