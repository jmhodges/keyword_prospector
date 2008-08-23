# 
# (C) 2008 Los Angeles Times
# 

module KeywordUtilities
  # An object representing the current state in the Aho-Corasick algorithm.
  class State
    @@id_sequence = 1

    # The serial number of this object.  All state objects have a unique id.
    attr_reader   :id

    # The character represented by this object.
    attr_reader   :char

    # The failure link.
    attr_accessor :fail

    # The amount to increment the index in the case of failure.
    attr_accessor :fail_increment

    # The output object, if any, associated with this node.
    attr_accessor :output

    # The depth of this node in the tree.
    attr_accessor :depth

    # The keyword associated with this node.
    attr_accessor :keyword
  
    def initialize(char, depth=0, next_state={})
      # Duck punch next_state to act sorta like a Hash
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
  
    # Add a new state object as a child of this State, associated with the
    # character provided.
    def insert_next_state(char)
      cur_state = @next_state[char]

      if cur_state
        cur_state
      else
        @next_state[char] = State.new(char, depth + 1)
      end
    end
  
    # Return the child state associated with the character provided.
    def [](char)
      @next_state[char]
    end
  
    # Assign a child state to a character.
    def []=(char, value)
      @next_state[char] = value
    end
  
    # Return all the child states.
    def values
      @next_state.values
    end
  
    # Return all the characters associated with child states.
    def keys
      @next_state.keys
    end
  
    # Transition to the next state by following char through the state machine.
    # position is used to track the current position in the match text.
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
end