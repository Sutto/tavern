#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rake'
require 'rspec/core'
require 'rspec/core/rake_task'
require 'bundler/gem_tasks'

task :default => :spec

begin
  require 'ci/reporter/rake/rspec'
rescue LoadError
end


desc "Run all specs in spec directory (excluding plugin specs)"
RSpec::Core::RakeTask.new :spec