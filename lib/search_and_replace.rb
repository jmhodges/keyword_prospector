# 
# (C) 2008 Los Angeles Times
# 
require 'keyword_prospector'

module KeywordUtilities
  # A class for replacing arbitrary strings in text.  Uses a KeywordProspector
  # tree for fast matching.
  class SearchAndReplace
    def initialize
      @dl = KeywordProspector.new
      @tree_initialized = false
    end

    # Add a replacement to the tree.
    def add_replacement(original, replacement)
      @dl.add(original, replacement)
    end

    # Initialize the tree.  Call this only once after all replacements have been
    # added.
    def initialize_tree
      unless @tree_initialized
        @dl.construct_fail
        @tree_initialized = true
      end
    end

    # Search and replace on the provided text.  Returns the original text with
    # all replacements substituted.  This method is case insensitive.
    def replace_text(text)
      unless @tree_initialized
        initialize_tree
      end

      matches = @dl.process(text.downcase, :filter_overlaps => true)

      retval = ""
      current_index = 0
      matches.each do |match|
        if (current_index < match.start_idx)
          retval += text[current_index, match.start_idx - current_index]
        end

        retval += match.output
        current_index = match.end_idx
      end

      retval += text[current_index, text.length] unless current_index == text.length

      retval
    end
  end
end