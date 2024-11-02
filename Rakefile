require 'rake'
require 'rbconfig'

def os
  @os ||= begin
    host_os = RbConfig::CONFIG['host_os']
    case host_os
    when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
      :windows
    when /darwin|mac os/
      :macos
    when /linux/
      :linux
    else
      raise Error, "Unknown OS: #{host_os.inspect}"
    end
  end
end

DRAGONRUBY_PATH = case os
                  when :windows
                    '../dragonruby.exe'
                  when :macos, :linux
                    '../dragonruby'
                  end

desc 'Run the game'
task :run do
  system DRAGONRUBY_PATH
end

TestLog = 'test_results.log'

# NOTE: could also use the Rake testing toolset here. Now just running all tests with the DragonRuby
# test runner - not optimal for library tests that don't need anything from DR, perhaps
desc 'Run all tests'
task :test do
  # NOTE: the dependency to test_runner.rb, which is expected to actually run the tests and produce
  # the test log (into the TestLog file)
  system "#{DRAGONRUBY_PATH} mygame --eval app/spec/test_runner.rb"
  if File.exist? TestLog
    puts 'DragonRuby tests failed:'
    puts File.read(TestLog)
  else
    puts 'DragonRuby tests completed successfully!'
  end
end

task default: :run
