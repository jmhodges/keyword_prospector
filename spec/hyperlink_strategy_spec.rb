# 
# (C) 2008 Los Angeles Times
# 
require File.dirname(__FILE__) + '/spec_helper'
require 'hyperlink_strategy'
include KeywordUtilities

describe HyperlinkStrategy do
  before :each do
    @strategy = HyperlinkStrategy.new
  end

  it "Should create hyperlinks to the provided URL" do
    @strategy.url="http://travel.latimes.com"

    @strategy.decorate("Foo").should == "<a href=\"#{@strategy.url}\">Foo</a>"
  end

  it "should accept url and options in the constructor" do
    tmp = HyperlinkStrategy.new(:url, :foo => :bar)
    tmp.url.should == :url
    tmp.options[:foo].should == :bar
  end

  it "should accept options to specify html attributes" do
    @strategy.options = {:title => "foo title", :style => "hidden;"}
    @strategy.url = 'foourl'
    
    linked_text = @strategy.decorate("Foo")
    linked_text.should match(%r{<a .*>Foo</a>})
    linked_text.should match(%r{href="foourl"})
    linked_text.should match(%r{title="foo title"})
    linked_text.should match(%r{style="hidden;"})
  end

  describe "keywords" do
    it "should allow setting and retrieving keywords" do
      keywords = %w{a b c d e}
      @strategy.keywords = keywords

      @strategy.keywords.should == Set.new(keywords)
    end

    it "should allow comma-separated strings for setting" do
      @strategy.keywords = "foo", "bar", "baz"
      @strategy.keywords.should == Set.new(["foo", "bar", "baz"])
    end

    it "should allow a single string for setting" do
      @strategy.keywords = "xyzzy"
      @strategy.keywords.should == Set.new(["xyzzy"])
    end
  end

  describe "add_keyword" do
    it "should add keywords to empty set" do
      @strategy.keywords.should == Set.new

      @strategy.add_keyword("foo").keywords.should == Set.new("foo")
    end

    it "should add keywords to existing set" do
      keywords = %w{foo, bar, baz}
      @strategy.keywords = keywords

      @strategy.add_keyword("xyzzy").keywords.should ==
        Set.new(keywords + ["xyzzy"])
    end
  end
end
