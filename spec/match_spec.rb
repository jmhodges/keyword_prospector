# 
# (C) 2008 Los Angeles Times
# 
require File.dirname(__FILE__) + '/spec_helper'
require 'match'
include KeywordUtilities

describe Match do
  describe "spaceship operator" do
    it "returns -1 when start position of other is greater than start position of self" do
      match = Match.new(:dont_care, 1, 5)
      other_matches = [Match.new(:dont_care, 5, 7),
                       Match.new(:dont_care, 2, 7),
                       Match.new(:dont_care, 2, 3)]

      other_matches.each do |m|
        (match <=> m).should == -1
      end
    end

    it "returns -1 when start positions are equal and end position of other is greater than end position of self" do
      match = Match.new(:dont_care, 1, 5)
      other_matches = [Match.new(:dont_care, 1, 7),
                       Match.new(:dont_care, 1, 9)]

      other_matches.each do |m|
        (match <=> m).should == -1
      end
    end

    it "returns 0 when start position and end position are the same" do
      [[0, 7], [1, 13], [7, 9]].each do |values|
        match1 = Match.new(:dont_care, values[0], values[1])
        match2 = Match.new(:dont_care, values[0], values[1])

        (match1 <=> match2).should == 0
      end
    end

    it "returns 1 when start position of other is less than start position of self" do
      match = Match.new(:dont_care, 5, 9)
      other_matches = [Match.new(:dont_care, 1, 4),
                       Match.new(:dont_care, 2, 6),
                       Match.new(:dont_care, 4, 11)]

      other_matches.each do |m|
        (match <=> m).should == 1
      end
    end

    it "returns 1 when start positions are equal and end position of other is less than end position of self" do
      match = Match.new(:dont_care, 5, 9)
      other_matches = [Match.new(:dont_care, 5, 6),
                       Match.new(:dont_care, 5, 8)]

      other_matches.each do |m|
        (match <=> m).should == 1
      end
    end
  end

  describe "accessors" do
    before(:each) do
      @match = Match.new(:first, :second, :third, :fourth)
    end

    it "keyword, start, and end should be assigned correctly" do
      @match.keyword.should == :first
      @match.start_idx.should == :second
      @match.end_idx.should == :third
      @match.output.should == :fourth
    end
  end

  describe "overlap?" do
    it "should return false when there is no overlap" do
      match1 = Match.new("foo", 1, 4)
      match2 = Match.new("bar", 7, 10)

      should_not_overlap(match1, match2)
    end

    it "should return true when there is an overlap" do
      match1 = Match.new("foo", 1, 4)
      match2 = Match.new("bar", 2, 10)

      should_overlap(match1, match2)
    end

    it "should return false when matches are consecutive" do
      match1 = Match.new("foo", 1, 4)
      match2 = Match.new("bar", 4, 10)

      should_not_overlap(match1, match2)
    end

    it "should return true when overlap is one character" do
      match1 = Match.new("foo", 1, 4)
      match2 = Match.new("bar", 3, 10)

      should_overlap(match1, match2)
    end

    def should_not_overlap(a, b)
      a.overlap?(b).should == false
      b.overlap?(a).should == false
    end

    def should_overlap(a, b)
      a.overlap?(b).should == true
      b.overlap?(a).should == true
    end
  end

  describe "length" do
    it "should return the difference between start and end indices" do
      [[1, 4], [2, 7]].each do |start_idx, end_idx|
        Match.new("don't care", start_idx, end_idx).length.should ==
                                                          end_idx - start_idx
      end
    end
  end

  describe "equality" do
    it "should be true if matches occupy same space regardless of keyword" do
      m1 = Match.new("foo", 1, 7)
      m2 = Match.new("bar", 1, 7)

      m1.should == m2
    end

    it "should be false if matches don't occupy same space" do
      m1 = Match.new("foo", 1, 7)
      m2 = Match.new("bar", 2, 7)
      m3 = Match.new("bar", 1, 6)

      m1.should_not == m2
      m1.should_not == m3
    end
  end
end
