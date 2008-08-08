# 
# (C) 2008 Los Angeles Times
# 
require 'set'

class HyperlinkStrategy
  attr_reader :url
  attr_reader :options

  def initialize(url=nil, options={})
    @keywords = Set.new
    self.options = options
    self.url = url
  end

  def keywords=(*keywords)
    @keywords = Set.new(keywords.flatten)
  end

  def keywords
    @keywords
  end

  def url=(url)
    @url = url
    merge_options(@options)
  end

  def options=(options)
    merge_options(options)
  end

  def add_keyword(keyword)
    @keywords.add(keyword)
    self
  end

  def decorate(keyword)
    attributes = ""
    options.each_pair do |key, value|
      attributes += " " unless attributes.length == 0
      attributes += "#{key}=\"#{value}\""
    end

    "<a " + attributes + ">#{keyword}</a>"
  end

  private
  def merge_options(options)
    if @url
      @options = {:href => @url}.merge(options)
    else
      @options = options
    end
  end
end
