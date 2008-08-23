# 
# (C) 2008 Los Angeles Times
# 
require 'set'
require 'lookup_chain'
require 'keyword_prospector'
require 'hyperlink_strategy'
require 'rubygems'
require 'hpricot'

module KeywordUtilities
  # 
  # Given a set of keywords and url's, and optionally HTML attributes to set
  # on links, takes text and adds hyperlinks from the specified keywords to
  # their associated URL's.  Example:
  #
  #   linker = KeywordLinker.new
  #   linker.add_url('http://www.latimes.com', 'Los Angeles Times')
  #   linker.link_text("Let's check out the Los Angeles Times!")
  #   => "Let's check out the <a href=\"http://www.latimes.com\">Los Angeles Times</a>!"
  #
  # KeywordLinker depends on hpricot for parsing HTML.  This is done to prevent
  # hyperlinks from being added inside of other hyperlinks and inside of
  # attribute text.
  #
  class KeywordLinker  
    @@blacklist_strategy = Object.new
    class << @@blacklist_strategy
      def decorate(keyword)
        keyword
      end
    end

    # Takes an optional array of lookup objects.  A lookup object is anything
    # that responds to the process method and returns an array of Match objects,
    # including KeywordLinker, KeywordProspector, and LookupChain objects.  If
    # multiple objects are specified, a LookupChain is created that gives highest
    # priority to matches from objects closer to the end of the array.
    def initialize(*lookups)
      @tree_initialized=true

      if(lookups)
        @lookup = LookupChain.new(lookups)
      end
    end

    # Takes a url and a keyword String or Array of keywords, and adds it to the
    # tree of keywords in the KeywordLinker.  Takes an optional hash of html
    # attributes to be associated with this url.
    #
    # Only the first occurrence of the url will be linked.  If multiple keywords
    # are specified, then only the first occurrence of any of the keywords is
    # linked to the target url.  ie, if multiple keywords match for this url,
    # only one instance of one keyword will be linked.
    def add_url(url, keyword, html_attributes={})
      init_lookup

      strategy = HyperlinkStrategy.new(url, html_attributes)
      strategy.keywords = keyword

      @dl.add(strategy)
    end

    # Blacklist this keyword or array of keywords.  If a keyword is blacklisted,
    # it will not be linked.  For example, if the "Los Angeles" part of
    # "Los Angeles Times" is getting linked, you can blacklist
    # "Los Angeles Times" to keep it from being linked.
    def blacklist_keyword(keyword)
      init_lookup

      @dl.add(keyword, @@blacklist_strategy)
    end

    # Initialize the tree after _all_ url's have been added.  This needs to be
    # called once.  If you don't call init_tree, it will be called automatically
    # on the first call to the process or link_text method.  You may find this
    # annoying or inconvenient if it happens on the first request to your
    # application and you've constructed a large set of links.  Adding url's
    # after calling init_tree, process, or link_text is not supported.
    def init_tree
      unless @tree_initialized
        @dl.construct_fail
        @tree_initialized = true
      end
    end

    # Adds links to known url's into the text provided.  Only the first instance
    # of each keyword or set of keywords associated to a url is linked.  In cases
    # of overlap, the longest keyword is chosen to resolve the overlap.
    def link_text(text)
      init_tree unless @tree_initialized

      linked_outputs = Set.new

      htext = Hpricot(text)

      link_text_in_elem(htext, linked_outputs)

      return htext.to_s
    end

    # Returns an array of matches in the specified text.  Doesn't filter overlaps
    # or parse HTML to prevent matches in attribute text or inside of existing
    # hyperlinks.  Primarily for internal use.
    def process(text)
      init_tree unless @tree_initialized

      @lookup.process(text)
    end

    private
    # Initialize the KeywordProspector object if needed.  Called only when adding
    # our own url's, not when aggregating other lookup objects.
    def init_lookup
      unless @dl
        @dl = KeywordProspector.new
        @tree_initialized = false

        if @lookup
          @lookup << @dl
        else
          @lookup = @dl
        end
      end
    end

    # Given a single hpricot element, link text inside of all child elements.
    def link_text_in_elem(elem, linked_outputs)
      elem.children.each do |e|
        case e
        when Hpricot::Text
          text = e.to_s

          results = process(text)

          results.sort!
          KeywordProspector.filter_overlaps(results)

          unless (results.nil? || results.empty?)
            e.content = link_text_internal(text, results, linked_outputs)
          end
        when Hpricot::Elem
          link_text_in_elem(e, linked_outputs) if e.stag.name != "a"
        end
      end
    end

    # Called internally to substitute links in element text.
    def link_text_internal(text, results, linked_outputs = nil)
      linked_outputs ||= Set.new

      retval = ""
      cursor = 0
      results.each do |result|
        unless linked_outputs.include?(result.output)
          if(result.start_idx > cursor)
            retval += text[cursor, result.start_idx - cursor]
            cursor = result.start_idx
          end

          retval += result.output.decorate(result.keyword)
          cursor = result.end_idx

          linked_outputs.add(result.output)
        end
      end

      if(cursor < text.size)
        retval += text[cursor, text.size-cursor]
      end

      return retval
    end
  end
end