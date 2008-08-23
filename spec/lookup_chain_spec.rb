# 
# (C) 2008 Los Angeles Times
# 
require File.dirname(__FILE__) + '/spec_helper'
require 'lookup_chain'
require 'match'
include KeywordUtilities

describe LookupChain do
  before(:each) do
    @dl1 = mock(Object, :process => :dummy_method)
    @dl2 = mock(Object, :process => :dummy_method)
  end

  describe :initialize do
    describe "should check all objects for a process method" do
      it "when given an array of objects" do
        lambda {LookupChain.new([@dl1])}.should_not raise_error
        lambda {LookupChain.new([Object.new])}.should raise_error(ArgumentError)
      end

      it "when given multiple objects in constructor" do
        lambda {LookupChain.new(@dl1, @dl2)}.should_not raise_error
        lambda {LookupChain.new(@dl1, Object.new)}.should raise_error(ArgumentError)
      end
    end
  end

  describe :<< do
    it "should check for a process method" do
      lambda{LookupChain.new << @dl1}.should_not raise_error
      lambda{LookupChain.new << Object.new}.should raise_error(ArgumentError)
    end

    it "should add to the end of the list of lookups" do
      lc = LookupChain.new
      lc.lookups.should == []

      lc << @dl1
      lc.lookups.should == [@dl1]

      lc << @dl2
      lc.lookups.should == [@dl1, @dl2]
    end
  end

  describe :lookups do
    it "should return an array of lookup objects assigned in constructor" do
      LookupChain.new(@dl1, @dl2).lookups.should == [@dl1, @dl2]
      LookupChain.new([@dl2, @dl1]).lookups.should == [@dl2, @dl1]
    end
  end

  describe :process do
    it "should call process on all child objects" do
      @dl1.should_receive(:process).with(:text).and_return([])
      @dl2.should_receive(:process).with(:text).and_return([])
      lc = LookupChain.new(@dl1, @dl2)

      lc.process(:text)
    end

    it "should return a sorted list of match objects from all lookups" do
      match1 = Match.new("match1", 0, 3)
      match2 = Match.new("match2", 5, 7)
      match3 = Match.new("match3", 11, 13)
      match4 = Match.new("match4", 19, 31)

      @dl1.should_receive(:process).with(:text).and_return([match1, match4])
      @dl2.should_receive(:process).with(:text).and_return([match2, match3])

      lc = LookupChain.new(@dl1, @dl2)

      lc.process(:text).should == [match1, match2, match3, match4]
    end

    it "should return the longest match when there are overlaps, regardless of priority order" do
      match1 = Match.new("match1", 0, 3)
      match2 = Match.new("match2", 1, 7)

      @dl1.stub!(:process).with(:text).and_return([match1])
      @dl2.stub!(:process).with(:text).and_return([match2])

      lc = LookupChain.new(@dl1, @dl2)
      lc.process(:text).should == [match2]

      lc = LookupChain.new(@dl2, @dl1)
      lc.process(:text).should == [match2]
    end

    it "should prioritize the first lookup object in the list when there are overlapping matches of equal length" do
      match1 = Match.new("match1", 0, 3)
      match2 = Match.new("match2", 1, 4)

      @dl1.stub!(:process).with(:text).and_return([match1])
      @dl2.stub!(:process).with(:text).and_return([match2])

      lc = LookupChain.new(@dl1, @dl2)
      lc.process(:text).should == [match1]

      lc = LookupChain.new(@dl2, @dl1)
      lc.process(:text).should == [match2]
    end
  end
end
