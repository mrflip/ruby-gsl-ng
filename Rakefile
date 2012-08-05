# -*- ruby -*-
require "bundler/gem_tasks"

__END__
require 'rubygems'
require 'rake'
require 'echoe'
require 'yard'

Echoe.new('ruby-gsl-ng') do |p|
  p.author = 'v01d'
  p.summary = "Ruby/GSL new-generation wrapper"
  p.url = "http://github.com/v01d/ruby-gsl-ng"
  p.version = "0.2.6"
  p.dependencies = ['yard', 'ffi']
#  p.eval = proc { s.has_rdoc = 'yard' }
end

Rake::TaskManager.class_eval do
  def remove_task(task)
    @tasks.delete(task.to_s)
  end
end

Rake.application.remove_task(:docs)
YARD::Rake::YardocTask.new(:docs) {|t| t.options = ['--verbose','--no-private','--hide-void']}

