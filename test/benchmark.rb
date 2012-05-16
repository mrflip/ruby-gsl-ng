#!/usr/bin/ruby 
$:.unshift('../lib')
$:.unshift('../ext')
require 'benchmark'
require 'gslng'
require 'rbgsl'
require 'narray'
include Benchmark

puts '#################################### Vector ####################################'

n=500000
size = 50000
puts "Vector#[]"
bmbm do |x|
  v = GSLng::Vector.random(size)
  gv = GSL::Vector.alloc(v.to_a)
  x.report("rb-gsl :") {n.times {i=rand(size); gv[i]}}
  x.report("GSLng  :") {n.times {i=rand(size); v[i]}}
end
puts

n = 100
size = 5000
puts "Vector#each - vector of #{size} elements"
bmbm do |x|
  v = GSLng::Vector.zero(size)
  gv = GSL::Vector.alloc(v.to_a)
  x.report("rb-gsl :") {n.times {s = 0; gv.each do |e| s += e end}}
  x.report("GSLng  :") {n.times {s = 0; v.each do |e| s += e end}}
end
puts

n = 500
size = 50000
puts "Norm (BLAS) - vector of #{size} elements"
bmbm do |x|
  v = GSLng::Vector.random(size)
  gv = GSL::Vector.alloc(v.to_a)
  x.report("rb-gsl :") {n.times {gv.dnrm2}}
  x.report("GSLng  :") {n.times {v.norm}}
end
puts

n=10
size = 50000
puts "Vector#map!"
bmbm do |x|
  v = GSLng::Vector.random(size)
  gv = GSL::Vector.alloc(v.to_a)
  i = rand(size)
  l = lambda{|e| rand}
  x.report("rb-gsl :") {n.times {gv.collect!{|e| rand}}}
  x.report("GSLng  :") {n.times {v.map!{|e| rand}}}
end
puts


n=5000
size = 5000
puts "Vector product - two vectors of #{size} elements"
bmbm do |x|
  v,v2 = GSLng::Vector.random(size),GSLng::Vector.random(size)
  gv,gv2 = GSL::Vector.alloc(v.to_a),GSL::Vector.alloc(v2.to_a)
  x.report("rb-gsl :") {n.times {gv.mul!(gv2)}}
  x.report("GSLng  :") {n.times {v.mul!(v2)}}
end
puts

n=500
size = 5000
puts "Sort - vector of #{size} elements"
bmbm do |x|
  v = GSLng::Vector.random(size)
  gv = GSL::Vector.alloc(v.to_a)
  x.report("rb-gsl :") {n.times {gv.sort!}}
  x.report("GSLng  :") {n.times {v.sort!}}
end
puts

n=500
size = 5000
puts "Vector#to_a"
bmbm do |x|
  v = GSLng::Vector.random(size)
  gv = GSL::Vector.alloc(v.to_a)
  x.report("rb-gsl :") {n.times {gv.to_a}}
  x.report("GSLng  :") {n.times {v.to_a}}
end
puts

n=500
size = 50000
puts "Vector::from_array"
bmbm do |x|
  a = Array.new(size) { rand }
  x.report("rb-gsl :") {n.times {GSL::Vector.alloc(a)}}
  x.report("GSLng  :") {n.times {GSLng::Vector.from_array(a)}}
end
puts

puts '#################################### Matrix ####################################'

n=500000
size = 50
puts "Matrix#[] - 50 x 50"
bmbm do |x|
  v = GSLng::Matrix.random(size, size)
  gv = GSL::Matrix.alloc(size, size)
  x.report("rb-gsl :") {n.times {i,j=rand(size),rand(size); gv[i,j]}}
  x.report("GSLng  :") {n.times {i,j=rand(size),rand(size); v[i,j]}}
end
puts
