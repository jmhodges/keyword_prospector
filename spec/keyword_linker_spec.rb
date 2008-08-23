# 
# (C) 2008 Los Angeles Times
# 
require File.dirname(__FILE__) + '/spec_helper'
require 'keyword_linker'
include KeywordUtilities

describe KeywordLinker do
  before(:each) do
    @kl = KeywordLinker.new
  end

  describe :add_url do
    it "should accept a string (url) and a single keyword" do
      @kl.add_url("url", "keyword")
    end

    it "should accept a string (url) and an array of keywords" do
      @kl.add_url("url", ["keyword1", "keyword2"])
    end

    it "should accept options for html attributes" do
      @kl.add_url("url", "keyword", :class => "awesome")

      linked_text = @kl.link_text("keyword")

      linked_text.should match(%r{^<a .*>keyword</a>$})
      linked_text.should match(%r{href="url"})
      linked_text.should match(%r{class="awesome"})
    end
  end

  describe :link_text do
    it "should init_tree if I forget to" do
      @kl.add_url("url", "foo")

      @kl.link_text("Is there a foo in the house?").should ==
        "Is there a <a href=\"url\">foo</a> in the house?"
    end

    it "should return original text when there are no matches" do
      @kl.add_url("url", "foo")
      @kl.init_tree

      orig_text = "Is there a bar in the house?"
      @kl.link_text(orig_text).should == orig_text
    end

    it "should return linked text when URL's are provided with keyword" do
      @kl.add_url("url", "foo")
      @kl.init_tree

      @kl.link_text("Is there a foo in the house?").should ==
        "Is there a <a href=\"url\">foo</a> in the house?"
    end

    it "should return linked text when URL's are provided with keyword array" do
      @kl.add_url("url", %w{foo bar baz})
      @kl.init_tree

      @kl.link_text("pool bar party").should == "pool <a href=\"url\">bar</a> party"
    end

    it "should link correctly at the beginning of the text" do
      @kl.add_url("url", "foo")

      @kl.link_text("foo is the word").should == '<a href="url">foo</a> is the word'
    end

    it "should link correctly at the end of the text" do
      @kl.add_url("url", "foo")

      @kl.link_text("the word is foo").should == 'the word is <a href="url">foo</a>'
    end

    it "should perform multiple links in the text" do
      @kl.add_url("url1", "foo")
      @kl.add_url("url2", "bar")

      @kl.link_text("the foo and the bar are awesome").should ==
        'the <a href="url1">foo</a> and the <a href="url2">bar</a> are awesome'
    end

    it "should link only the first instance of each keyword" do
      @kl.add_url("url", "foo")

      @kl.link_text("foo, foo, or foo?").should == '<a href="url">foo</a>, foo, or foo?'
    end

    it "should link only the first instance of each keyword in separate text elements" do
      @kl.add_url("url", "foo")

      @kl.link_text("<i>foo</i>, <b>foo</b>, or <u>foo</u>?").should == '<i><a href="url">foo</a></i>, <b>foo</b>, or <u>foo</u>?'
    end

    it "should link only the first instance of each url" do
      @kl.add_url("url", %w[foo bar baz])

      @kl.link_text("bar, baz, or foo?").should == '<a href="url">bar</a>, baz, or foo?'
    end

    it "should link longest match in overlapping text" do
      @kl.add_url("url", ["foo bar", "bar baz xyzzy"])

      @kl.link_text("foo bar baz xyzzy").should == 'foo <a href="url">bar baz xyzzy</a>'
    end

    describe "with another KeywordLinker in the constructor" do
      before(:each) do
        @combo_linker = KeywordLinker.new(@kl)
      end

      it "should link keywords from both linkers" do
        @kl.add_url("foourl", "foo")
        @combo_linker.add_url("barurl", "bar")

        @combo_linker.link_text("foo bar").should == '<a href="foourl">foo</a> <a href="barurl">bar</a>'
      end

      it "should prioritize its own keywords over the parent's keywords" do
        @kl.add_url("foourl1", "foo")
        @combo_linker.add_url("foourl2", "foo")

        @combo_linker.link_text("foo").should == '<a href="foourl2">foo</a>'
      end
    end

    describe "with an array of KeywordLinkers as parents in the constructor" do
      before(:each) do
        @kl2 = KeywordLinker.new
        @combo_linker = KeywordLinker.new([@kl, @kl2])
      end

      it "should link keywords from all linkers" do
        @kl.add_url("foourl", "foo")
        @kl2.add_url("barurl", "bar")
        @combo_linker.add_url("bazurl", "baz")

        @combo_linker.link_text("foo bar baz").should == '<a href="foourl">foo</a> <a href="barurl">bar</a> <a href="bazurl">baz</a>'
      end

      it "should prioritize its own keywords over the parents' keywords" do
        @kl.add_url("foourl1", "foo")
        @kl2.add_url("foourl2", "foo")
        @combo_linker.add_url("foourl3", "foo")

        @combo_linker.link_text("foo").should == '<a href="foourl3">foo</a>'
      end
    end

    describe "with an array of KeywordLinkers as lookups in the constructor" do
      before(:each) do
        @kl2 = KeywordLinker.new
        @combo_linker = KeywordLinker.new([@kl, @kl2])
      end

      it "should link keywords from all lookups" do
        @kl.add_url("foourl", "foo")
        @kl2.add_url("barurl", "bar")

        @combo_linker.link_text("foo bar baz").should == '<a href="foourl">foo</a> <a href="barurl">bar</a> baz'
      end
    end

    describe "with an arbitrary lookup object in the constructor" do
      it "should provide results from the lookup object" do
        lookup = mock(Object)
        lookup.should_receive(:process).with(:text).and_return([:result])
        kl = KeywordLinker.new(lookup)
        kl.process(:text).should == [:result]
      end

      it "should reject objects from the constructor if they don't have a process method" do
        lookup = mock(Object)
        lambda{KeywordLinker.new(nil, lookup)}.should raise_error(ArgumentError)
      end
    end

    describe "with multiple level hierarchy" do
      before(:each) do
        @kl2 = KeywordLinker.new(@kl)
        @kl3 = KeywordLinker.new(@kl2)
        @combo_linker = KeywordLinker.new(@kl3)
      end

      it "should link keywords from all linkers" do
        @kl.add_url("foourl", "foo")
        @kl2.add_url("barurl", "bar")
        @kl3.add_url("bazurl", "baz")
        @combo_linker.add_url("xyzzyurl", "xyzzy")

        @combo_linker.link_text("foo bar baz xyzzy").should == '<a href="foourl">foo</a> <a href="barurl">bar</a> <a href="bazurl">baz</a> <a href="xyzzyurl">xyzzy</a>'
      end
    end
  end

  describe "linking html text" do
    it "should skip linking inside tag attributes" do
      @kl.add_url("url", "foo")

      @kl.link_text('<td title="another foo for you">foo</td>').should ==
        '<td title="another foo for you"><a href="url">foo</a></td>'
    end

    it "should not link inside of <a></a> tags" do
      @kl.add_url("url", "foo")

      @kl.link_text('<a href="bar">baz foo bar</a> and foo').should ==
        '<a href="bar">baz foo bar</a> and <a href="url">foo</a>'
    end

    it "shouldn't choke on bogus etags" do
      @kl.add_url("url", "foo")

      lambda{@kl.link_text('foo </i>')}.should_not raise_error
    end
  end

  describe "blacklisting keywords" do
    it "should stop linking of every occurrence of the keyword" do
      @kl.add_url("url", "Los Angeles")
      @kl.blacklist_keyword("Los Angeles Times")

      @kl.link_text("Los Angeles Times Los Angeles Times").should == "Los Angeles Times Los Angeles Times"
    end
  end
end
