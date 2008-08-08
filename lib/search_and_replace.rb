# 
# (C) 2008 Los Angeles Times
# 
require 'keyword_prospector'

class SearchAndReplace
  def initialize
    @dl = KeywordProspector.new
    @tree_initialized = false
  end

  def add_replacement(original, replacement)
    @dl.add(original, replacement)
  end

  def initialize_tree
    unless @tree_initialized
      @dl.construct_fail
      @tree_initialized = true
    end
  end

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
