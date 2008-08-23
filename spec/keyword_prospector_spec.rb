# 
# (C) 2008 Los Angeles Times
# 
require File.dirname(__FILE__) + '/spec_helper'
require 'set'
include KeywordUtilities

describe KeywordProspector do
  it "should match keywords in text, respecting word boundaries" do
    dl = KeywordProspector.new
    
    dl.add('test')
    dl.add('fido')
    dl.add('te')
    dl.add('fi')
    dl.add('dot')
    dl.add('dots')
    dl.add('sis')
    
    dl.construct_fail
    
    matches = []
    dl.process('hello fido this is a test') {|x| matches << x}
    matches.size.should == 2
    (matches.collect{|match| match.keyword} & %w{test fido}).
        size.should == 2
  end

  it "should give correct location for a single match within a string" do
    dl = KeywordProspector.new(["foo"])

    match = nil
    dl.process("A foo and his money are soon parted") {|x| match = x}

    match.start_idx.should == 2
    match.end_idx.should == 5
  end

  it "should give correct location for the second match within a string" do
    dl = KeywordProspector.new(["foo", "bar"])

    match = []
    dl.process("foo bar") {|x| match << x}

    match
    match[0].keyword.should == "foo"
    match[0].start_idx.should == 0
    match[0].end_idx.should == 3
    match[1].keyword.should == "bar"
    match[1].start_idx.should == 4
    match[1].end_idx.should == 7
  end

  it "Should include information about where the match is present in the string" do
    dl = KeywordProspector.new %w{foo oo bar baz xyzzy thud}

    matches = {}

    dl.process('foo, bar, xyzzy and also the baz') {|x| matches[x.keyword] = x}

    matches["foo"].should_not be_nil
    matches["bar"].should_not be_nil
    matches["baz"].should_not be_nil
    matches["xyzzy"].should_not be_nil

    matches["foo"].start_idx.should == 0
    matches["foo"].end_idx.should == 3
    matches["bar"].start_idx.should == 5
    matches["bar"].end_idx.should == 8
    matches["xyzzy"].start_idx.should == 10
    matches["xyzzy"].end_idx.should == 15
    matches["baz"].start_idx.should == 29
    matches["baz"].end_idx.should == 32
  end

  it "should match a single word to itself" do
    dl = KeywordProspector.new(["foo"])
    count = 0
    dl.process("foo"){count += 1}
    count.should == 1
  end

  it "should not match a single word to a different word" do
    dl = KeywordProspector.new(["foo"])
    count = 0
    dl.process("bar"){count += 1}
    count.should == 0
  end

  it "should call the block once for every match" do
    dl = KeywordProspector.new(["foo"])
    count = 0
    dl.process("foo foo foo"){count += 1}
    count.should == 3
  end

  it "Should get correct start and end matches with overlapping matches" do
    keywords = ['Sling Blade', 'Blade Runner', 'foo', 'bar']
    dl = KeywordProspector.new(keywords)
    candidate = 'Sling Blade Runner foo bar'
    matches = {}
    dl.process(candidate) {|x| matches[x.keyword] = x}

    keywords.each do |keyword|
      matches[keyword].start_idx.should == candidate.index(keyword)
      matches[keyword].end_idx.should == candidate.index(keyword) +
                                           keyword.length
    end
  end

  it "returns a sorted array of matches when a block is not given" do
    keywords = %w{foo bar baz xyzzy thud}

    dl = KeywordProspector.new(keywords)
    results =
        dl.process("The best metavariables are thud, xyzzy, and of course foo.")

    results.class.should == Array

    results.should == results.sort
  end

  it "filters out shorter matches multiple matches overlap" do
    dl = KeywordProspector.new(["a b c", "c d", "e f", "f g h", "i j k l m",
                               "k l m n o p q"])

    results = dl.process("a b c d, e f g h, i j k l m n o p q",
                         :filter_overlaps => true)

    results.size.should == 3

    results[0].keyword.should == 'a b c'
    results[1].keyword.should == 'f g h'
    results[2].keyword.should == 'k l m n o p q'
  end

  it "detects word chars" do
    KeywordProspector.word_char?(?a).should be_true
    KeywordProspector.word_char?(?k).should be_true
    KeywordProspector.word_char?(?z).should be_true
    KeywordProspector.word_char?(?A).should be_true
    KeywordProspector.word_char?(?K).should be_true
    KeywordProspector.word_char?(?Z).should be_true
    KeywordProspector.word_char?(?0).should be_true
    KeywordProspector.word_char?(?7).should be_true
    KeywordProspector.word_char?(?9).should be_true
    KeywordProspector.word_char?(?_).should be_true
  end

  it "detects non-word chars" do
    KeywordProspector.word_char?(?-).should be_false
    KeywordProspector.word_char?(?>).should be_false
    KeywordProspector.word_char?(?<).should be_false
    KeywordProspector.word_char?(?.).should be_false
    KeywordProspector.word_char?(32).should be_false
    KeywordProspector.word_char?(9).should be_false
  end

  it "word_delimiter? is opposite of word_char?" do
    KeywordProspector.word_delimiter?(?.).should be_true
    KeywordProspector.word_delimiter?(32).should be_true
    KeywordProspector.word_delimiter?(?K).should be_false
  end

  describe "word boundary detection" do
    before(:each) do
      keywords = %w{foo bar baz xyzzy thud}
      @dl = KeywordProspector.new(keywords)
    end

    describe "allows" do
      it "matching at beginning of string" do
        results = @dl.process("foo is the word")

        results.size.should == 1
        results[0].keyword.should == "foo"
      end

      it "matching at end of string" do
        results = @dl.process("the word is bar")

        results.size.should == 1
        results[0].keyword.should == "bar"
      end
    end

    describe "doesn't allow" do
      it "matches not starting on a word boundary" do
        results = @dl.process("topaz is a gem but tobaz is not")
        results.size.should == 0
      end

      it "matches not ending on a word boundary" do
        results = @dl.process("are you xyzzypated?")
        results.size.should == 0
      end

      it "matches at the beginning of the string and not ending on a word boundary" do
        results = @dl.process("fooby you too?")
        results.size.should == 0
      end

      it "multiple candidate matches in various places" do
        results = @dl.process("fooby barby bazby tofoo tobar tobaz ambazbafoo")
        results.size.should == 0
      end
    end
  end

  describe "with decoration strategy objects" do
    it "should read keywords from the object" do
      strategy = Object.new
      strategy.should_receive(:keywords).and_return(Set.new(%w{foo bar baz}))

      dl = KeywordProspector.new([strategy])
    end

    it "should return strategy objects in results" do
      strategy = Object.new
      strategy.should_receive(:keywords).and_return(Set.new(%w{foo bar baz}))

      dl = KeywordProspector.new([strategy])

      results = dl.process("foo, bar, and baz")

      results.size.should == 3

      results.each do |result|
        result.output.should == strategy
      end
    end
  end
end
