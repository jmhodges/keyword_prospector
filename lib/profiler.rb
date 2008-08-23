#!/usr/bin/env ruby

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'keyword_prospector'

module KeywordUtilities
  # A class for profiling the KeywordProspector libraries.  Use the profile: rake
  # tasks to execute the tests.
  class Profiler
    MATCHWORD_COUNT=2000

    # Get a tree with the provided count of random words.
    def self.get_tree(keyword_count)
      words = get_random_words(keyword_count)
      KeywordProspector.new(words)
    end

    # Run the tree creation profiling test.
    def self.profile_tree_creation(keyword_count, options={})
      total = 0
      time_limit = options[:time_limit] || 0.01

      start_time = Time.now
      iterations = 0
      while Time.now - start_time < time_limit
        start=Time.now
        get_tree(keyword_count)
        total += Time.now - start
        iterations += 1
      end

      puts "Average tree creation time over #{iterations} iterations with #{keyword_count} keywords: #{total/iterations.to_f}"
    end

    # Run the keyword matching profiling test.
    def self.profile_keyword_matching(keyword_count, options={})
      dl = get_tree(keyword_count)
      time_limit = options[:time_limit] || 300

      total = 0
      total_matches = 0
      start_time = Time.now
      iterations = 0
      words = get_random_words(options[:count] || MATCHWORD_COUNT)
      text = words.join(" ")
      while Time.now - start_time < time_limit
        matches = 0
        start = Time.now
        dl.process(text) {matches += 1}
        total += Time.now - start
        total_matches += matches
        iterations += 1
      end

      puts "Average time spent matching: #{total/iterations.to_f}"
      puts "Average number of matches: #{total_matches/iterations.to_f}"
    end

    private
    # Get the requested number of random words from /usr/share/dict/words.
    def self.get_random_words(count=1000)
      words = []
      dict = File.open("/usr/share/dict/words")
      count.times do |index|
        words[index] = dict.readline.chomp
      end

      dict.each_line do |word|
        word = dict.readline.chomp
        index = rand dict.lineno
        if (index < count)
          words[index] = word
        end
      end

      return words
    end
  end
end