# 
# (C) 2008 Los Angeles Times
# 
require File.dirname(__FILE__) + '/spec_helper'
require 'state'

include KeywordUtilities

describe State do
  before(:each) do
    @state = State.new(:char)
  end

  describe "initializer" do
    it "should increment id for each new object" do
      state1 = State.new(:char)
      state2 = State.new(:char)
      state3 = State.new(:char)

      state2.id.should > state1.id

      state3.id.should > state2.id
    end
    
    it "should initialize char with the value passed" do
      state = State.new(:value)
      state.char.should == :value
    end
  end

  describe "should have accessor" do
    [:fail, :fail_increment, :output, :depth, :keyword].each do |method|
      it method do
        @state.send(method.to_s + "=", :any_object)
        @state.send(method.to_s).should == :any_object
      end
    end
  end

  describe "children" do
    it "should initially be nil" do
      @state[:char].should == nil
    end

    it "should be assignable" do
      @state[:char] = :value
      @state[:char].should == :value
    end

    it "should have their keys available" do
      keys = [?a, ?b, ?c]
      keys.each {|key| @state[key] = :dont_care}

      @state.keys.sort.should == keys
    end

    it "should have their values available" do
      values = [?a, ?b, ?c]

      values.size.times do |time|
        @state[time] = values[time]
      end

      @state.values.sort.should == values
    end
  end

  describe "insert_next_state" do
    it "should create a new state initialized with the value provided" do
      child_state = State.new(:char)
      State.should_receive(:new).with(:char, 1).and_return(child_state)

      @state.insert_next_state(:char)

      @state[:char].should be_eql(child_state)
    end

    it "should not create a new child state if one already exists" do
      child_state = State.new(:char)
      State.should_receive(:new).exactly(1).times.with(:char, 1).
        and_return(child_state)

      @state.insert_next_state(:char)
      @state.insert_next_state(:char)

      @state[:char].should be_eql(child_state)
    end
  end

  describe "transition" do
    it "should return next state selected by char" do
      @state[:char] = :next_state
      @state.transition(:char).should == :next_state
    end

    it "to self should increment start position and set end position to equal start" do
      @state[:char] = @state
      position = Object.new
      position.should_receive(:begin).and_return(1)
      position.should_receive(:begin=).with(2)
      position.should_receive(:end=).with(2)

      @state.transition(:char, position)
    end

    it "should increment end position by one if state is found" do
      position = Object.new
      position.should_receive(:end).and_return(42)
      position.should_receive(:end=).with(43)

      @state[:char] = :next_state

      @state.transition(:char, position)
    end

    describe "failures" do
      before(:each) do
        @fail_state = State.new(:dont_care)
        @state.fail = @fail_state
      end

      it "should transition from fail state if next state doesn't exist" do
        @fail_state.should_receive(:transition).with(:char).
          and_return(:fail_state_transition)

        @state.transition(:char).should == :fail_state_transition
      end
    end
  end
end
