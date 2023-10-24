# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |task|
  task.pattern = Dir.glob("spec/**/*_spec.rb")
  task.rspec_opts = "--format documentation"
end

require "rubocop/rake_task"

RuboCop::RakeTask.new do |task|
  task.requires << 'rubocop-rspec'
end

task default: %i[spec rubocop]
