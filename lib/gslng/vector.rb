module GSLng
  # A fixed-size n-dimensional vector.
  #
  # =Notes
  # * {#each}, {#map} and similar methods are implemented with C versions which should be fast.
  # * {#map} returns a Vector, not an Array. Use {#map_array} for that.
  # * While this class includes Enumerable, certain methods are redefined (like {#max} and {#min})
  #   so they use internal GSL methods.
  # * Some functions (like {#sum}, {#dot}, and others) use BLAS functions (through GSLng's CBLAS interface).
  # * In contrary to Array, operators {#[]} and {#[]=} will raise an exception when accessing out-of-bounds elements.
  # * Operator {#*} multiplies two vectors element-by-element. To perform a dot product use the {#^} operator instead (or the {#dot} alias).
  # * Operands are coerced to vectors so you can do vector + scalar, etc. (see {#coerce})
  #
  class Vector
    include Enumerable
        
    attr_reader :size, :stride
    attr_reader :ptr  # @private
    attr_reader :ptr_value # @private

    # @group Constructors
    
    # Create a Vector of size n. If zero is true, the vector is initialized with zeros.
    # Otherwise, the vector will contain garbage.
    # You can optionally pass a block, in which case {#map_index!} will be called with it (i.e.: it works like {Array.new}).
    def initialize(n, zero = false)
      @backend = GSLng.backend
      ptr = (zero ? @backend.gsl_vector_calloc(n) : @backend.gsl_vector_alloc(n))
      @ptr = FFI::AutoPointer.new(ptr, Vector.method(:release))
      @ptr_value = @ptr.to_i
      @size = n
      @stride = 1
      if (block_given?) then self.map_index!(Proc.new) end
    end

    def initialize_copy(other) # @private
      @backend = GSLng.backend
      ptr = @backend.gsl_vector_alloc(other.size)
      @ptr = FFI::AutoPointer.new(ptr, Vector.method(:release))
      @ptr_value = @ptr.to_i
      @size = other.size
      @stride = 1
      @backend.gsl_vector_memcpy(@ptr, other.ptr)
    end

    def Vector.release(ptr) # @private
      GSLng.backend.gsl_vector_free(ptr)
    end

    # Same as Vector.new(n, true)
    def Vector.zero(n); Vector.new(n, true) end

    # Create a vector from an Array.
    def Vector.from_array(array)
      if (array.empty?) then raise "Can't create empty vector" end
      v = Vector.new(array.size)
      GSLng.backend.gsl_vector_from_array(v.ptr_value, array)
      return v
    end

    # Creates a Vector with linearly distributed values between +start+ and +stop+, separated by +delta+.
    def Vector.linspace(start, stop, delta)
      if (start > stop || delta <= 0) then raise 'Invalid values' end
      Vector.new(((stop - start) / delta).floor.to_i + 1) {|i| start + delta * i}
    end

    # Creates a Vector from an Array or a Range
    # @see Vector::from_array    
    # @example
    #   Vector[1,2,3]
    #   Vector[1..3]
    def Vector.[](*args)
      array = (args.size == 1 && Range === args[0] ? args[0].to_a : args)
      Vector.from_array(array)
    end

    # Generates a Vector of n random numbers between 0 and 1.
    # NOTE: This simply uses {Kernel::rand}
    def Vector.random(n)
      Vector.new(n).map!{|x| Kernel::rand}
    end
    class << self; alias_method :rand, :random end

    # @group Operators
    
    # Add (element-by-element) other to self
    # @return [Vector] self
    def add!(other)
      case other
      when Numeric; @backend.gsl_vector_add_constant(@ptr, other.to_f)
      when Vector; @backend.gsl_vector_add(@ptr, other.ptr)
      else
        x,y = other.coerce(self)
        x.add!(y)
      end
      return self
    end
    
    # Substract (element-by-element) other from self
    # @return [Vector] self    
    def substract!(other)
      case other
      when Numeric; @backend.gsl_vector_add_constant(@ptr, -other.to_f)
      when Vector; @backend.gsl_vector_sub(@ptr, other.ptr)
      else
        x,y = other.coerce(self)
        x.sub!(y)
      end
      return self
    end
    alias_method :sub!, :substract!
    
    # Multiply (element-by-element) other with self
    # @return [Vector] self
    def multiply!(other)
      case other
      when Numeric; @backend.gsl_blas_dscal(other.to_f, @ptr)
      when Vector; @backend.gsl_vector_mul(@ptr, other.ptr)
      else
        x,y = other.coerce(self)
        x.mul!(y)
      end
      return self
    end
    alias_method :mul!, :multiply!
    
    # Divide (element-by-element) self by other
    # @return [Vector] self
    def divide!(other)
      case other
      when Numeric; @backend.gsl_blas_dscal(1.0 / other, @ptr)
      when Vector;  @backend.gsl_vector_div(@ptr, other.ptr)
      else
        x,y = other.coerce(self)
        x.div!(y)
      end
      return self
    end
    alias_method :div!, :divide!

    # Element-by-element addition
    def +(other); self.dup.add!(other) end

    # Element-by-element substraction
    def -(other); self.dup.sub!(other) end

    # Element-by-element product
    # @example
    #  Vector[1,2,3] * 2 => [2.0, 4.0, 6.0]:Vector
    #  Vector[1,2,3] * Vector[0,1,2] => [0.0, 2.0, 6.0]:Vector    
    def *(other)
      case other
      when Numeric; self.dup.mul!(other)
      when Vector; self.dup.mul!(other)
      else
        x,y = other.coerce(self)
        x * y
      end
    end

    # Element-by-element division
    def /(other); self.dup.div!(other) end

    # Invert sign on all elements
    def -@; self.map!(&:-@) end

    # @group Other mathematical operations

    # Dot product between self and other (uses BLAS's ddot)
    # @return [Float]
    # @example
    #  Vector[1,2,3] ^ Vector[0,1,2] => 8.0
    def dot(other)
      out = FFI::Buffer.new(:double)
      @backend.gsl_blas_ddot(@ptr, other.ptr, out)
      return out[0].get_double(0)
    end
    alias_method :^, :dot
    
    # Norm 2 of the vector (uses BLAS's dnrm2)
    def norm; @backend.gsl_blas_dnrm2(@ptr) end
    alias_method :length, :norm

    # Returns the sum of all elements (uses BLAS's dasum)
    def sum; @backend.gsl_blas_dasum(@ptr) end

    # Optimized version of: self += other * alpha (where alpha is a Numeric). Uses BLAS's daxpy.
    def mul_add(other, alpha); @backend.gsl_blas_daxpy(alpha, other.ptr, @ptr); return self end

    # @group Miscelaneous methods
    
    # Reverse the order of elements
    def reverse!; @backend.gsl_vector_reverse(@ptr); return self end
    
    # Swap the i-th element with the j-th element
    def swap(i,j); @backend.gsl_vector_swap_elements(@ptr, i, j); return self end

    def sort!; @backend.gsl_sort_vector(@ptr); return self end
    def sort; self.dup.sort! end

    # Copy other's values into self
    def copy(other); @backend.gsl_vector_memcpy(@ptr, other.ptr); return self end

    # Wraps self into the interval [0,up_to). NOTE: this value must be > 0
    # @param [Vector,Numeric] up_to
    # @return [Vector] a vector of values -1, 1 or 0, if (max-min) was substracted, added to the coordinate,
    # or not modified, respectively.
    # @example Assuming that +v = Vector[-8,2,8]+
    #  v.wrap(5) => [1.0 0.0 -1.0]:Vector
    #  v => [-3.0 2.0 3.0]:Vector
    def wrap!(up_to)
      delta = Vector.new(self.size)
      self.map_index! do |i|
        a,b = self[i].divmod(up_to)
        delta[i] = -a
        b
      end
      return delta
    end
    
    # Compute hash value for this Vector.
    # Note: this may be a bit inefficient for now
    def hash
      self.to_a.hash
    end

    # @group Setting/getting values

    # Access the i-th element.
    # If _index_ is negative, it counts from the end (-1 is the last element).
    # @raise [RuntimeError] if out-of-bounds
    # @todo support ranges
    def [](index)
      @backend.gsl_vector_get_operator(@ptr_value, index)
    end

    # Set the i-th element.
    # If _index_ is negative, it counts from the end (-1 is the last element).
    # @raise [RuntimeError] if out-of-bounds
    # @todo support ranges    
    def []=(index, value)
      @backend.gsl_vector_set_operator(@ptr_value, index, value.to_f)
      #@backend.gsl_vector_set(@ptr, (index < 0 ? @size + index : index), value.to_f)
    end

    # Set all values to v
    def all!(v); @backend.gsl_vector_set_all(@ptr, v); return self end
    alias_method :set!, :all!
    alias_method :fill!, :all!

    # Set all values to zero
    def zero!; @backend.gsl_vector_set_zero(@ptr); return self end

    # Set all values to zero, except the i-th element, which is set to 1
    def basis!(i); @backend.gsl_vector_set_basis(@ptr, i); return self end
    
    # @group Views

    # Create a {Vector::View} from this Vector.
    # If _size_ is nil, it is computed automatically from _offset_ and _stride_
    def view(offset = 0, size = nil, stride = 1)
      if (stride <= 0) then raise 'stride must be positive' end
      
      if (size.nil?)
        size = @size - offset
        k,m = size.divmod(stride)
        size = k + (m == 0 ? 0 : 1)
      end

      view_ptr = @backend.gsl_vector_subvector2(@ptr, offset, stride, size)
      View.new(self, view_ptr, size, stride)
    end
    alias_method :subvector_view, :view

    # Shorthand for #subvector_view(..).to_vector.
    def subvector(*args); subvector_view(*args).to_vector end    

    # @group 2D/3D/4D utility vectors

    # Same as Vector#[0]
    def x; @backend.gsl_vector_get(@ptr, 0) end
    # Same as Vector#[1]
    def y; @backend.gsl_vector_get(@ptr, 1) end
    # Same as Vector#[2]
    def z; @backend.gsl_vector_get(@ptr, 2) end
    # Same as Vector#[3]
    def w; @backend.gsl_vector_get(@ptr, 3) end

    # Same as Vector#[0]=
    def x=(v); @backend.gsl_vector_set(@ptr, 0, v.to_f) end
    # Same as Vector#[1]=
    def y=(v); @backend.gsl_vector_set(@ptr, 1, v.to_f) end
    # Same as Vector#[2]=
    def z=(v); @backend.gsl_vector_set(@ptr, 2, v.to_f) end
    # Same as Vector#[3]=
    def w=(v); @backend.gsl_vector_set(@ptr, 3, v.to_f) end
    
    # @group Predicate methods

    # if all elements are zero
    def zero?; @backend.gsl_vector_isnull(@ptr) == 1 ? true : false end

    # if all elements are strictly positive (>0)
    def positive?; @backend.gsl_vector_ispos(@ptr) == 1 ? true : false end

    #if all elements are strictly negative (<0)
    def negative?; @backend.gsl_vector_isneg(@ptr) == 1 ? true : false end
    
    # if all elements are non-negative (>=0)
    def nonnegative?; @backend.gsl_vector_isnonneg(@ptr) == 1 ? true : false end

    # If each element of self is less than other's elements
    def <(other); (other - self).positive? end

    # If each element of self is greater than other's elements
    def >(other); (other - self).negative? end

    # If each element of self is less-or-equal than other's elements
    def <=(other); (other - self).nonnegative? end

    # If each element of self is less-or-equal than other's elements
    def >=(other); (self - other).nonnegative? end

    # @group Minimum/Maximum

    # Return maximum element of vector
    def max; @backend.gsl_vector_max(@ptr) end
    
    # Return minimum element of vector
    def min; @backend.gsl_vector_min(@ptr) end

    # Same as {Array#minmax}
    def minmax
      min = FFI::Buffer.new(:double)
      max = FFI::Buffer.new(:double)
      @backend.gsl_vector_minmax(@ptr, min, max)
      return [min[0].get_float64(0),max[0].get_float64(0)]
    end

    # Same as {#minmax}, but returns the indices to the elements
    def minmax_index
      min = FFI::Buffer.new(:size_t)
      max = FFI::Buffer.new(:size_t)
      @backend.gsl_vector_minmax_index(@ptr, min, max)
      #return [min[0].get_size_t(0),max[0].get_size_t(0)]
      return [min[0].get_ulong(0),max[0].get_ulong(0)]
    end
    
    # Same as {#min}, but returns the index to the element
    def min_index; @backend.gsl_vector_min_index(@ptr) end

    # Same as {#max}, but returns the index to the element
    def max_index; @backend.gsl_vector_max_index(@ptr) end
    
    # @group Statistics
    
    # Compute the mean of the vector
    def mean; @backend.gsl_stats_mean(self.as_array, self.stride, self.size) end
    
    # Compute the median of the vector
    # *Note* it assumes sorted data!
    def median; @backend.gsl_stats_median_from_sorted_data(self.as_array, self.stride, self.size) end

    # Compute the median of the vector
    # *Note* it assumes sorted data!
    # @param [Float] f A number between 0 and 1 indicating the percentile
    def quantile(f); @backend.gsl_stats_quantile_from_sorted_data(self.as_array, self.stride, self.size, f) end

    # Compute the variance of the vector
    # @param [Float] mean Optionally supply the mean if you already computed it previously with {self#mean}
    # @param [Boolean] fixed_mean If true, the passed mean is taken to be known a priori (see GSL documentation)
    def variance(mean = nil, fixed_mean = false)
      if (mean.nil?) then @backend.gsl_stats_variance(self.as_array, self.stride, self.size)
      else
        if (fixed_mean) then @backend.gsl_stats_variance_with_fixed_mean(self.as_array, self.stride, self.size, mean)
        else @backend.gsl_stats_variance_m(self.as_array, self.stride, self.size, mean) end
      end
    end
    
    # Compute the standard deviation of the vector
    # @see #variance
    def standard_deviation(mean = nil, fixed_mean = false)
      if (mean.nil?) then @backend.gsl_stats_sd(self.as_array, self.stride, self.size)
      else
        if (fixed_mean) then @backend.gsl_stats_sd_with_fixed_mean(self.as_array, self.stride, self.size, mean)
        else @backend.gsl_stats_sd_m(self.as_array, self.stride, self.size, mean) end
      end
    end    

    # Compute the total sum of squares of the vector
    # @see #variance
    def total_sum_squares(mean = nil)
      if (mean.nil?) then @backend.gsl_stats_tss(self.as_array, self.stride, self.size)
      else @backend.gsl_stats_tss_m(self.as_array, self.stride, self.size, mean) end
    end

    # Compute the absolute deviation of the vector
    # @see #variance
    def absolute_deviation(mean = nil)
      if (mean.nil?) then @backend.gsl_stats_absdev(self.as_array, self.stride, self.size)
      else @backend.gsl_stats_absdev_m(self.as_array, self.stride, self.size, mean) end
    end

    # Compute the skewness of the vector. You can optionally provide the mean *and* the standard deviation if you already computed them
    def skew(mean = nil, sd = nil)
      if (mean.nil? || sd.nil?) then @backend.gsl_stats_skew(self.as_array, self.stride, self.size)
      else @backend.gsl_stats_skew_sd_m(self.as_array, self.stride, self.size, mean, sd) end
    end

    # Compute the kurtosis of the vector
    # @see #skew
    def kurtosis(mean = nil, sd = nil)
      if (mean.nil? || sd.nil?) then @backend.gsl_stats_kurtosis(self.as_array, self.stride, self.size)
      else @backend.gsl_stats_kurtosis_sd_m(self.as_array, self.stride, self.size, mean, sd) end
    end

    # Compute the autocorrelation of the vector
    # @see #variance
    def autocorrelation(mean = nil)
      if (mean.nil?) then @backend.gsl_stats_lag1_autocorrelation(self.as_array, self.stride, self.size)
      else @backend.gsl_stats_lag1_autocorrelation(self.as_array, self.stride, self.size, mean) end
    end

    # Compute the covariance between self and other. You can optionally pass the mean of both vectors if you already computed them
    # @see #variance
    def covariance(other, mean1 = nil, mean2 = nil)
      if (mean1.nil? || mean2.nil?) then @backend.gsl_stats_covariance(self.as_array, self.stride, other.as_array, other.stride, self.size)
      else @backend.gsl_stats_covariance(self.as_array, self.stride, other.as_array, other.stride, self.size, mean1, mean2) end
    end

    # Compute the correlation between self and other
    def correlation(other)
      @backend.gsl_stats_correlation(self.as_array, self.stride, other.as_array, other.stride, self.size)
    end

    # @group High-order methods

    # @yield [elem]
    def each(block = Proc.new)
      @backend.gsl_vector_each(@ptr_value, &block)
    end

    # @see #each
    # @yield [elem,i]
    def each_with_index(block = Proc.new)
      @backend.gsl_vector_each_with_index(@ptr_value, &block)
    end

    # @see #map
    def map!(block = Proc.new); @backend.gsl_vector_map!(@ptr_value, &block); return self end

    # Similar to {#map!}, but passes the index to the element instead.
    # @yield [i]
    def map_index!(block = Proc.new); @backend.gsl_vector_map_index!(@ptr_value, &block); return self end

    # @return [Vector]
    # @see #map_index!
    # @yield [i]
    def map_index(block = Proc.new); self.dup.map_index!(block) end

    alias_method :map_old, :map

    # Acts like the normal 'map' method from Enumerator
    # @return [Array]
    # @see #map
    # @yield [i]
    def map_array(block = Proc.new); self.map_old(&block); end

    # @return [Vector]
    # @yield [elem]
    def map(block = Proc.new); self.dup.map!(block) end

    # @group Type conversions

    # @see Array#join
    # @return [String]
    def join(sep = $,)
      s = ''
      self.each do |e|
        s += (s.empty?() ? e.to_s : "#{sep}#{e}")
      end
      return s
    end

    # Coerces _other_ to be a Vector. 
    # @example
    #  Vector[1,2].coerce(5) => [[5.0, 5.0]:Vector, [1.0, 2.0]:Vector]
    def coerce(other)
      case other
      when Vector
        [ other, self ]
      when Numeric
        [ Vector.new(@size).set!(other), self ]
      else
        raise TypeError, "Can't coerce #{other.class} into #{self.class}"
      end
    end

    # @return [String] same format as {Array#to_s}
    # @example
    #  Vector[1,2,3].to_s => "[1.0, 2.0, 3.0]"
    def to_s
      "[" + self.join(', ') + "]"
    end

    def inspect # @private
      "#{self}:Vector"
    end

    # @return [Array]
    def to_a
      @backend.gsl_vector_to_a(@ptr_value)
    end
    
    def as_array # @private
      @backend.gsl_vector_as_array(@ptr)
    end

    # Create a row matrix from this vector
    # @return [Matrix]
    def to_matrix
      m = Matrix.new(1, @size)
      @backend.gsl_matrix_set_row(m.ptr, 0, @ptr)
      return m
    end
    alias_method :to_row, :to_matrix

    # Create a column matrix from this vector
    # @return [Matrix]
    def transpose
      m = Matrix.new(@size, 1)
      @backend.gsl_matrix_set_col(m.ptr, 0, @ptr)
      return m
    end
    alias_method :to_column, :transpose

    # @group Equality test

    # Element-by-element comparison. Admits comparing to Array.
    def ==(other)
      if (self.size != other.size) then return false end
      self.each_with_index do |elem,i|
        if (elem != other[i]) then return false end
      end
      return true
    end

    def eql?(other)
      @backend.gsl_vector_eql?(@ptr_value, other.ptr_value)
    end
  end
end
