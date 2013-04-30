# This test is duplicated in Gemfile, and needs to match
# the conditions in lib/scanny/ruby_version_check.rb in the scanny gem
if defined?(RUBY_ENGINE) && RUBY_ENGINE == "rbx" && RUBY_VERSION >= '1.9'
  require "scanny/rake_task"

  Scanny::RakeTask.new do |t|
    t.format  = :stdout       # you will see output on travis website
    t.fail_on_error = false   # security errors should not break build
  end
else
  print "\nWARNING: Not using Rubinius in 1.9 mode - scanny task skipped\n\n"
end
