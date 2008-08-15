require 'profiler'

namespace(:profile) do
  desc 'Run tree creation profiling test'
  task(:tree_creation) do
    puts "Profiling tree creation"

    [1000, 10000, 20000, 40000].each do |keyword_count|
      puts "Starting iteration with #{keyword_count}-keyword trees"

      Profiler.profile_tree_creation(keyword_count, :time_limit => 300)
    end
  end
  
  desc 'Run keyword matching profiling test'
  task(:keyword_matching) do
    puts "Profiling keyword matching"

    [1000, 10000, 20000, 40000].each do |keyword_count|
      puts "Starting iteration with #{keyword_count}-keyword trees"

      Profiler.profile_keyword_matching(keyword_count)
    end
  end
end
