# 
# (C) 2008 Los Angeles Times
# 

class State
  @@id_sequence = 1

  attr_reader   :id
  attr_reader   :char

  attr_accessor :fail
  attr_accessor :fail_increment
  attr_accessor :output
  attr_accessor :depth
  attr_accessor :keyword
  
  def initialize(char, depth=0, next_state={})
    if next_state.is_a?(Array)
      class << next_state
        def values
          self.select{|value| value}
        end

        def keys
          retval = []
          self.each_index{|i| retval << i if self[i]}

          retval
        end
      end
    end

    @char = char
    @id = @@id_sequence
    @next_state = next_state
    @@id_sequence += 1
    self.depth = depth
  end
  
  def insert_next_state(char)
    cur_state = @next_state[char]

    if cur_state
      cur_state
    else
      @next_state[char] = State.new(char, depth + 1)
    end
  end
  
  def [](char)
    @next_state[char]
  end
  
  def []=(char, value)
    @next_state[char] = value
  end
  
  def values
    @next_state.values
  end
  
  def keys
    @next_state.keys
  end
  
  def transition(char, position=nil)
    next_state = @next_state[char]

    if next_state == self
      if position
        position.end = position.begin += 1
      end
    elsif next_state
      position.end += 1 if position
    else
      next_state = fail.transition(char)
      if position
        position.begin += depth - (next_state.depth - 1)
        position.end += 1
      end
    end

    next_state
  end
end
