# 
# (C) 2008 Los Angeles Times
# 
require File.dirname(__FILE__) + '/spec_helper'
require 'search_and_replace'
include KeywordUtilities

describe SearchAndReplace do
  before(:each) do
    @sar = SearchAndReplace.new
  end

  describe :add_replacement do
    it "should take an original and a replacement" do
      @sar.add_replacement("original", "replacement")
    end
  end

  describe :replace_text do
    before(:each) do
      @sar.add_replacement("original", "replacement")
      @sar.add_replacement("foo", "bar")
    end

    it "should replace text" do
      @sar.replace_text("original").should == "replacement"
    end

    it "should replace text at the beginning of the string" do
      @sar.replace_text("original is me").should == "replacement is me"
    end

    it "should replace text in the middle of the string" do
      @sar.replace_text("is original me").should == "is replacement me"
    end

    it "should replace text at the end of the string" do
      @sar.replace_text("me is original").should == "me is replacement"
    end

    it "should replace multiple instances of the same word" do
      @sar.replace_text("original original original").should == "replacement replacement replacement"
    end

    it "should replace multiple words" do
      @sar.replace_text("original foo original foo").should == "replacement bar replacement bar"
    end

    it "should have no trouble with html code" do
      link = '<a href="http://travel.latimes.com/destinations/bar-url">bar</a>'
      @sar.add_replacement(link, "bar")
      @sar.replace_text(link).should == "bar"
    end

    it "respects word boundaries" do
      @sar.replace_text("football").should == "football"
    end
  end
end
