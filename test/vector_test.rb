# To change this template, choose Tools | Templates
# and open the template in the editor.

$:.unshift File.join(File.dirname(__FILE__),'..','lib')
$:.unshift File.join(File.dirname(__FILE__),'..','ext')

require 'rubygems'
require 'test/unit'
require 'gslng'

include GSLng

class VectorTest < Test::Unit::TestCase
  def test_initialize
		assert_equal(10, Vector.new(10).size)
		assert_equal(10, Vector.zero(10).size)
		assert(Vector.zero(10).zero?)
		assert_nothing_raised { Vector.random(10) }
    assert_equal(Vector[0], Vector.linspace(0, 1, 1.5))
    assert_equal(Vector[0,1], Vector.linspace(0, 1, 1))
    assert_equal(Vector[0,0.5,1], Vector.linspace(0, 1, 0.5))
    assert_equal(Vector[0,0.7], Vector.linspace(0, 1, 0.7))
  end

	def test_to_s
		assert_equal("[0.0]", Vector.zero(1).to_s)
		assert_equal("[0.0, 0.0, 0.0]", Vector.zero(3).to_s)
		assert_equal("[0.0, 1.0, 2.0]", Vector.new(3) {|i| i}.to_s)
    assert_equal("[1.0, 2.0, 3.0]", Vector.new(3) {|i| i+1}.to_s)
		assert_equal("[1.0, 2.0, 3.0]", Vector[1,2,3].to_s)
    assert_equal("1.0 2.0 3.0", Vector[1,2,3].join(' '))
	end

	def test_equal
		assert_equal(Vector[1,2,3], [1,2,3])
		assert_equal(Vector[1,2,3], Vector[1,2,3])
    assert_equal(Vector[0...3], [0,1,2])
		assert_equal(Vector.zero(3), Vector.zero(3))
		assert_not_equal(Vector.zero(4), Vector.zero(3))

    assert(Vector[1,2,3].eql?(Vector[1,2,3]))
    assert(!Vector[1,2,3].eql?(Vector[1,2,4]))
	end

  def test_each
    a = Vector[1.1,2.1,3.8].map_array(&:round)
    assert_kind_of(Array, a)
    assert_equal([1,2,4], a)
    assert_equal(Vector[1,2,4],Vector[1.1,2.1,3.8].map!(&:round))
  end

	def test_copies
		v1 = Vector[1,2,3]
		v2 = Vector[2,3,4]
		assert_not_equal(v1, v2)
		assert_equal(v1.copy(v2), v2)
		assert_equal(v1.dup, v2)
	end

  def test_stats
    assert_equal(Vector[1, 2, 3, 4, 5].median, 3)
    assert_equal(Vector[1, 2, 3, 4].median, 2.5)
    assert_equal([1, 2, 3, 4].to_v.correlation([1, 2, 3, 4].to_v), 1)
  end
  
  def test_regression
    assert_equal([1, 2, 3, 4].to_v.fit_linear([2, 3, 4, 5].to_v), [1.0, 1.0])
  end

	def test_sets
		assert_equal(Vector.zero(3).set!(1), Vector[1,1,1])
		assert_equal(Vector.zero(3).set!(1).zero!, Vector.zero(3))
		assert_equal(Vector.zero(3).basis!(1), Vector[0,1,0])
	end

	def test_operators
		assert_equal(Vector[2,3,4],Vector[1,2,3] + Vector[1,1,1])
		assert_equal(Vector[1,0,3],Vector[1,2,3] * Vector[1,0,1])
		assert_equal(Vector[0,1,2],Vector[1,2,3] - Vector[1,1,1])
		assert_equal(Vector[0.5,1,1.5],Vector[1,2,3] / Vector[2,2,2])
		assert_equal(Vector[3,6,9],Vector[1,2,3] * 3)
		assert_equal(Vector[4,5,6],3 + Vector[1,2,3])
		assert_equal(Vector[4,5,6],Vector[1,2,3] + 3)
    assert_equal(Vector[2,1,0],3 - Vector[1,2,3])
		assert_equal(Vector[-2,-1,0],Vector[1,2,3] - 3)
		assert_equal(Vector[3,6,9],3 * Vector[1,2,3])
		assert_equal(Vector[0.5,1,1.5],Vector[1,2,3] / 2)
	end

	def test_other
    assert_equal(Matrix[1,2,3], Vector[1,2,3].to_matrix)
		assert_equal(Vector[1,2,3], Vector[1,2,3].to_a)
		assert_equal(Vector[1,2,3], Vector[3,1,2].sort)
		assert_equal(6, Vector[3,1,2].sum)
		assert_equal(Vector[3,1,2].mul_add(Vector[1,0,1],0.5), Vector[3.5,1,2.5])
		assert_equal(3, Vector[2,1,2].norm)
		assert_equal(5, Vector[3,1,2] ^ Vector[1,0,1])
	end

	def test_minmax
		assert_equal(1, Vector[1,2,3].min)
		assert_equal(3, Vector[1,2,3].max)
		assert_equal([1,3], Vector[1,2,3].minmax)
		assert_equal(0, (Vector[1,2,3]).min_index)
		assert_equal(2, (Vector[1,2,3]).max_index)
		assert_equal([0,2], Vector[1,2,3].minmax_index)
	end

	def test_set_get
		assert_equal(2, Vector[1,2,3][1])
		#assert_raise { Vector[1,2,3][3] } NOT working in some ruby versions
		assert_equal(3, Vector[1,2,3][-1])
		#assert_raise { Vector[1,2,3][-5] } NOT working in some ruby versions

		v = Vector[1,2,3]
		v[1] = 3
		assert_equal(Vector[1,3,3], v)
		v[-1] = 0
		assert_equal(Vector[1,3,0], v)
	end

  def test_view
    v,view = nil,nil
    assert_nothing_raised {
      v = Vector[1,2,3]
      view = v.view
      view[1] = 3
    }
    assert_equal(Vector[1,3,3], v)
    assert_equal(Vector[1,3,3], view)
    assert_equal(Vector[1,3], Vector[0,1,2,3].view(1,nil,2))
    assert_equal(Vector[0,2], Vector[0,1,2,3].view(0,nil,2))
  end

  def test_wrap
    v = Vector[1,2,8,-1,11]
    assert_equal(Vector[0,0,-1,1,-2],v.wrap!(5))
    assert_equal(Vector[1,2,3,4,1], v)
  end

  def test_predicate
    assert(Vector[1,2,3].positive?)
    assert(Vector[-1,-2,-3].negative?)
    assert(Vector[0,2,3].nonnegative?)
    assert(Vector[0,2,3] < Vector[1,3,4])
    assert(Vector[0,2,3] <= Vector[0,3,4])
    assert(Vector[1,3,4] > Vector[0,2,3])
    assert(Vector[0,2,3] <= Vector[0,3,4])
  end
end
