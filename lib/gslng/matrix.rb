module GSLng
  # A fixed-size MxN matrix.
  #
  # =Notes
  # See Vector notes. Everything applies with the following *differences/additions*:
  # * The {#*} operator performs actual matrix-matrix and matrix-vector products. To perform element-by-element
  #   multiplication use the {#^} operator (or {#multiply} method) instead. The rest of the operators work element-by-element.
  # * Operators can handle matrix-matrix, matrix-vector and matrix-scalar (also in reversed order). See {#coerce}.
  # * The {#[]} and {#[]=} operators can handle a "wildcard" value for any dimension, just like MATLAB's colon (:).
  class Matrix
    attr_reader :m, :n    
    attr_reader :ptr # internal FFI::Pointer that wraps the underlying gsl_matrix*
    attr_reader :ptr_value # @private

    alias_method :height, :m
    alias_method :width, :n
    alias_method :rows, :m
    alias_method :columns, :n

    # Shorthand for [{#rows},{#columns}]
    def size; [ @m, @n ] end

    # @group Constructors

    # Create a Matrix of m-by-n (rows and columns). If zero is true, the Matrix is initialized with zeros.
    # Otherwise, the Matrix will contain garbage.
    # You can optionally pass a block, in which case {#map_index!} will be called with it (i.e.: it works like Array.new).
    def initialize(m, n, zero = false)
      @backend = GSLng.backend
      ptr = zero ? @backend.gsl_matrix_calloc(m, n) : @backend.gsl_matrix_alloc(m, n)
      @ptr = FFI::AutoPointer.new(ptr, Matrix.method(:release))
      @ptr_value = @ptr.to_i
      @m,@n = m,n
      if (block_given?) then self.map_index!(Proc.new) end
    end

    def initialize_copy(other) # @private
      @backend = GSLng.backend
      ptr = @backend.gsl_matrix_alloc(other.m, other.n)
      @ptr = FFI::AutoPointer.new(ptr, Matrix.method(:release))
      @ptr_value = @ptr.to_i

      @m,@n = other.size
      @backend.gsl_matrix_memcpy(@ptr, other.ptr)
    end

    def Matrix.release(ptr) # @private
      GSLng.backend.gsl_matrix_free(ptr)
    end

    # Same as Matrix.new(m, n, true)
    def Matrix.zero(m, n); Matrix.new(m, n, true) end

    # Create a matrix from an Array
    # @see Matrix::[]
    def Matrix.from_array(array)
      if (array.empty?) then raise "Can't create empty matrix" end

      if (Numeric === array[0])
        m = Matrix.new(1, array.size)
        GSLng.backend.gsl_matrix_from_array(m.ptr_value, [ array ])
        return m
      elsif (Array === array[0])
        m = Matrix.new(array.size, array[0].size)
        GSLng.backend.gsl_matrix_from_array(m.ptr_value, array)
        return m
      else
        Matrix.new(array.size, array[0].to_a.size) {|i,j| array[i].to_a[j]}
      end
    end

    # Create a Matrix from an Array/Array of Arrays/Range
    # @example
    #  Matrix[[1,2],[3,4]] => [1.0 2.0; 3.0 4.0]:Matrix
    #  Matrix[1,2,3] => [1.0 2.0 3.0]:Matrix
    #  Matrix[[1..3],[5..7]] => [1.0 2.0 3.0; 5.0 6.0 7.0]:Matrix
    # @see Matrix::from_array    
    def Matrix.[](*args)
      Matrix.from_array(args)
    end
    
    # Generates a Matrix of m by n, of random numbers between 0 and 1.
    # NOTE: This simply uses {Kernel::rand}
    def Matrix.random(m, n)
      Matrix.new(m, n).map!{|x| Kernel::rand}
    end
    class << self; alias_method :rand, :random end

    # @group Setting/getting values

    # Access the element (i,j), which means (row,column).
    # Symbols :* or :all can be used as wildcards for both dimensions.
    # @example If +m = Matrix[[1,2],[3,4]]+
    #  m[0,0] => 1.0
    #  m[0,:*] => [1.0, 2.0]:Matrix
    #  m[:*,0] => [1.0, 3.0]:Matrix
    #  m[:*,:*] => [1.0, 2.0; 3.0, 4.0]:Matrix
    # @raise [RuntimeError] if out-of-bounds
    # @return [Numeric,Matrix] the element/sub-matrix
    def [](i, j = :*)
      if (Integer === i && Integer === j)
        @backend.gsl_matrix_get_operator(@ptr_value, i, j)
      else
        if (Symbol === i && Symbol === j) then return self
        elsif (Symbol === i)
          col = Vector.new(@m)
          @backend.gsl_matrix_get_col(col.ptr, @ptr, j)
          return col.to_matrix
        elsif (Symbol === j)
          row = Vector.new(@n)
          @backend.gsl_matrix_get_row(row.ptr, @ptr, i)
          return row.to_matrix
        end
      end
    end

    # Set the element (i,j), which means (row,column).
    # @param [Numeric,Vector,Matrix] value depends on indexing
    # @raise [RuntimeError] if out-of-bounds
    # @see #[]
    def []=(i, j, value)
      if (Symbol === i && Symbol === j) then
        if (Numeric === value) then self.fill!(value)
        else
          x,y = self.coerce(value)
          @backend.gsl_matrix_memcpy(@ptr, x.ptr)
        end
      elsif (Symbol === i)
        col = Vector.new(@m)
        x,y = col.coerce(value)
        @backend.gsl_matrix_set_col(@ptr, j, x.ptr)
        return col
      elsif (Symbol === j)
        row = Vector.new(@n)
        x,y = row.coerce(value)
        @backend.gsl_matrix_set_row(@ptr, i, x.ptr)
        return row
      else
        @backend.gsl_matrix_set_operator(@ptr_value, i, j, value)
      end

      return self
    end

    # Set all values to _v_
    def all!(v); @backend.gsl_matrix_set_all(@ptr, v); return self end
    alias_method :set!, :all!
    alias_method :fill!, :all!

    # Set all values to zero
    def zero!; @backend.gsl_matrix_set_zero(@ptr); return self end

    # Set the identity matrix values
    def identity; @backend.gsl_matrix_set_identity(@ptr); return self end

    # Copy matrix values from +other+ to +self+
    def set(other); @backend.gsl_matrix_memcpy(@ptr, other.ptr); return self end

    # @group Views

    # Create a {Matrix::View} from this Matrix.
    # If either _m_ or _n_ are nil, they're computed from _x_, _y_ and the Matrix's {#size}
    # @return [Matrix::View]
    def view(x = 0, y = 0, m = nil, n = nil)
      View.new(self, x, y, (m or @m - x), (n or @n - y))
    end
    alias_method :submatrix_view, :view
    
    # Shorthand for #submatrix_view(..).to_matrix.
    # @return [Matrix]
    def submatrix(*args); self.submatrix_view(*args).to_matrix end

    # Creates a {Matrix::View} for the i-th column
    # @return [Matrix::View]
    def column_view(i, offset = 0, size = nil); self.view(offset, i, (size or (@m - offset)), 1) end

    # Analogous to {#submatrix}
    # @return [Matrix]
    def column(*args); self.column_view(*args).to_matrix end

    # Creates a {Matrix::View} for the i-th row
    # @return [Matrix::View]
    def row_view(i, offset = 0, size = nil); self.view(i, offset, 1, (size or (@n - offset))) end

    # Analogous to {#submatrix}
    # @return [Matrix]
    def row(*args); self.row_view(*args).to_matrix end

    # Same as {#row_view}, but returns a {Vector::View}
    # @return [Vector::View]
    def row_vecview(i, offset = 0, size = nil)
      size = (@n - offset) if size.nil?
      ptr = @backend.gsl_matrix_row_view(@ptr, i, offset, size)
      Vector::View.new(self, ptr, size, 1)
    end

    # Same as {#column_view}, but returns a {Vector::View}
    # @return [Vector::View]
    def column_vecview(i, offset = 0, size = nil)
      size = (@m - offset) if size.nil?
      ptr = @backend.gsl_matrix_column_view(@ptr, i, offset, size)
      Vector::View.new(self, ptr, size, self.columns)
    end

    
    # @group Operators

    # Add other to self
    # @return [Matrix] self
    def add!(other)
      case other
      when Numeric; @backend.gsl_matrix_add_constant(@ptr, other.to_f)
      when Matrix; @backend.gsl_matrix_add(@ptr, other.ptr)
      else
        x,y = other.coerce(self)
        x.add!(y)
      end
      return self
    end

    # Substract other from self
    # @return [Matrix] self    
    def substract!(other)
      case other
      when Numeric; @backend.gsl_matrix_add_constant(@ptr, -other.to_f)
      when Matrix; @backend.gsl_matrix_sub(@ptr, other.ptr)
      else
        x,y = other.coerce(self)
        x.substract!(y)
      end
      return self
    end
    alias_method :sub!, :substract!

    # Multiply (element-by-element) other with self
    # @return [Matrix] self    
    def multiply!(other)
      case other
      when Numeric; @backend.gsl_matrix_scale(@ptr, other.to_f)
      when Matrix; @backend.gsl_matrix_mul_elements(@ptr, other.ptr)
      else
        x,y = other.coerce(self)
        x.multiply!(y)
      end
      return self
    end
    alias_method :mul!, :multiply!

    # Divide (element-by-element) self by other
    # @return [Matrix] self    
    def divide!(other)
      case other
      when Numeric; @backend.gsl_matrix_scale(@ptr, 1.0 / other)
      when Matrix;  @backend.gsl_matrix_div_elements(@ptr, other.ptr)
      else
        x,y = other.coerce(self)
        x.divide!(y)
      end
      return self
    end
    alias_method :div!, :divide!

    # Element-by-element addition
    def +(other); self.dup.add!(other) end

    # Element-by-element substraction
    def -(other); self.dup.substract!(other) end

    # Element-by-element division
    def /(other); self.dup.divide!(other) end

    # Element-by-element product. Both matrices should have same dimensions.
    def ^(other); self.dup.multiply!(other) end
    alias_method :multiply, :^
    alias_method :mul, :^

    # Matrix Product. self.n should equal other.m (or other.size, if a Vector).
    # @example
    #  Matrix[[1,2],[2,3]] * 2 => [2.0 4.0; 4.0 6.0]:Matrix
    # @todo some cases could be optimized when doing Matrix-Matrix, by using dgemv
    def *(other)
      case other
      when Numeric
        self.multiply(other)
      when Vector
        matrix = Matrix.new(self.m, other.size)
        @backend.gsl_blas_dgemm(:no_transpose, :no_transpose, 1, @ptr, other.to_matrix.ptr, 0, matrix.ptr)
        return matrix
      when Matrix
        matrix = Matrix.new(self.m, other.n)
        @backend.gsl_blas_dgemm(:no_transpose, :no_transpose, 1, @ptr, other.ptr, 0, matrix.ptr)
        return matrix
      else
        x,y = other.coerce(self)
        x * y
      end
    end

    # @group Row/column swapping

    # Transposes in-place. Only for square matrices
    def transpose!; @backend.gsl_matrix_transpose(@ptr); return self end

    # Returns the transpose of self, in a new matrix
    def transpose; matrix = Matrix.new(@n, @m); @backend.gsl_matrix_transpose_memcpy(matrix.ptr, @ptr); return matrix end

    # Swap the i-th and j-th columnos
    def swap_columns(i, j); @backend.gsl_matrix_swap_columns(@ptr, i, j); return self end
    
    # Swap the i-th and j-th rows
    def swap_rows(i, j); @backend.gsl_matrix_swap_rows(@ptr, i, j); return self end
    
    # Swap the i-th row with the j-th column. The Matrix must be square.
    def swap_rowcol(i, j); @backend.gsl_matrix_swap_rowcol(@ptr, i, j); return self end

    # Discards rows and columns as necessary (fill them with zero), to "slide" the values of the matrix
    # @param [Integer] i If > 0, slides all values to the bottom (adds +i+ rows of zeros at the top). If < 0,
    #  slides all values to the top and adds zeros in the bottom.
    # @param [Integer] j Analogous to parameter +i+, in this case a value < 0 adds zeros to the right (slides to the left),
    #  and a value > 0 adds zeros to the left (slides to the right).
    def slide(i, j); @backend.gsl_matrix_slide(@ptr, i, j); return self end

    # @group Predicate methods
    
    # if all elements are zero
    def zero?; @backend.gsl_matrix_isnull(@ptr) == 1 ? true : false end

    # if all elements are strictly positive (>0)
    def positive?; @backend.gsl_matrix_ispos(@ptr) == 1 ? true : false end

    #if all elements are strictly negative (<0)
    def negative?; @backend.gsl_matrix_isneg(@ptr) == 1 ? true : false end
    
    # if all elements are non-negative (>=0)
    def nonnegative?; @backend.gsl_matrix_isnonneg(@ptr) == 1 ? true : false end

    # If this is a column Matrix
    def column?; self.columns == 1 end

    # @group Minimum/maximum

    # Maximum element of the Matrix
    def max; @backend.gsl_matrix_max(@ptr) end

    # Minimum element of the Matrix
    def min; @backend.gsl_matrix_min(@ptr) end

    # Same as {Array#minmax}
    def minmax
      min = FFI::Buffer.new(:double)
      max = FFI::Buffer.new(:double)
      @backend.gsl_matrix_minmax(@ptr, min, max)
      return [min[0].get_float64(0),max[0].get_float64(0)]
    end

    # Same as {#minmax}, but returns the indices to the i-th and j-th min, and i-th and j-th max.
    def minmax_index
      i_min = FFI::Buffer.new(:size_t)
      j_min = FFI::Buffer.new(:size_t)
      i_max = FFI::Buffer.new(:size_t)
      j_max = FFI::Buffer.new(:size_t)
      @backend.gsl_matrix_minmax_index(@ptr, i_min, j_min, i_max, j_max)
      #return [min[0].get_size_t(0),max[0].get_size_t(0)]
      return [i_min[0].get_ulong(0),j_min[0].get_ulong(0),i_max[0].get_ulong(0),j_max[0].get_ulong(0)]
    end

    # Same as {#min}, but returns the indices to the i-th and j-th minimum elements
    def min_index
      i_min = FFI::Buffer.new(:size_t)
      j_min = FFI::Buffer.new(:size_t)
      @backend.gsl_matrix_min_index(@ptr, i_min, j_min)
      return [i_min[0].get_ulong(0), j_min[0].get_ulong(0)]
    end

    # Same as {#max}, but returns the indices to the i-th and j-th maximum elements
    def max_index
      i_max = FFI::Buffer.new(:size_t)
      j_max = FFI::Buffer.new(:size_t)
      @backend.gsl_matrix_max_index(@ptr, i_max, j_max)
      return [i_max[0].get_ulong(0), j_max[0].get_ulong(0)]
    end

    # @group High-order methods

    # Yields the specified block for each element going row-by-row
    # @yield [elem]
    def each 
      @m.times {|i| @n.times {|j| yield(self[i,j]) } }
    end

    # Yields the specified block for each element going row-by-row
    # @yield [elem, i, j]
    def each_with_index 
      @m.times {|i| @n.times {|j| yield(self[i,j], i, j) } }
    end

    # Calls the block on each element of the matrix
    # @yield [elem]
    # @return [void]
    def each(block = Proc.new) 
      @backend.gsl_matrix_each(@ptr_value, &block)
    end
    
    # @see #each
    # @yield [elem,i,j]
    def each_with_index(block = Proc.new) 
      @backend.gsl_matrix_each_with_index(@ptr_value, &block)
    end    

    # Yields the block for each row *view* ({Matrix::View}).
    # @yield [view]
    def each_row; self.rows.times {|i| yield(row_view(i))} end

    # Same as {#each_row}, but yields {Vector::View}'s
    # @yield [vector_view]    
    def each_vec_row; self.rows.times {|i| yield(row_vecview(i))} end

    # Same as #each_column, but yields {Vector::View}'s
    # @yield [vector_view]    
    def each_vec_column; self.columns.times {|i| yield(column_vecview(i))} end

    # Yields the block for each column *view* ({Matrix::View}).
    # @yield [view]    
    def each_column; self.columns.times {|i| yield(column_view(i))} end

    # Efficient {#map!} implementation
    # @yield [elem]
    def map!(block = Proc.new); @backend.gsl_matrix_map!(@ptr_value, &block); return self end

    # Alternate version of {#map!}, in this case the block receives the index (row, column) as a parameter.
    # @yield [i,j]
    def map_index!(block = Proc.new); @backend.gsl_matrix_map_index!(@ptr_value, &block); return self end

    # Similar to {#map_index!}, in this case it receives both the element and the index to it
    # @yield [elem,i,j]
    def map_with_index!(block = Proc.new); @backend.gsl_matrix_map_with_index!(@ptr_value, &block); return self end

    # @see #map!
    # @return [Matrix]
    # @yield [elem]
    def map(block = Proc.new); self.dup.map!(block) end

    # @see #map
    # @return [Array]
    # @yield [elem]
    def map_array(block = Proc.new); @backend.gsl_matrix_map_array(@ptr_value, &block) end

    # @group Type conversions

    # Same as {Array#join}
    # @example
    #  Matrix[[1,2],[2,3]].join => "1.0 2.0 2.0 3.0"
    def join(sep = $,)
      s = ''
      self.each do |e|
        s += (s.empty?() ? e.to_s : "#{sep}#{e}")
      end
      return s
    end

    # Converts the matrix to a String, separating each element with a space and each row with a ';' and a newline.
    # @example
    #  Matrix[[1,2],[2,3]] => "[1.0 2.0;\n 2.0 3.0]"
    def to_s
      s = '['
      @m.times do |i|
        s += ' ' unless i == 0
        @n.times do |j|
          s += (j == 0 ? self[i,j].to_s : ' ' + self[i,j].to_s)
        end
        s += (i == (@m-1) ? ']' : ";\n")
      end

      return s
    end
    
    # Converts the matrix to an Array (of Arrays).
    # @example
    #  Matrix[[1,2],[2,3]] => [[1.0,2.0],[2.0,3.0]]
    def to_a
      @backend.gsl_matrix_to_a(@ptr_value)
    end

    def inspect # @private
      "#{self}:Matrix"
    end

    # Coerces _other_ to be of Matrix class.
    # If _other_ is a scalar (Numeric) a Matrix filled with _other_ values is created.
    # Vectors are coerced using {Vector#to_matrix} (which results in a row matrix).
    def coerce(other)
      case other
      when Matrix
        [ other, self ]
      when Numeric
        [ Matrix.new(@m, @n).fill!(other), self ]
      when Vector
        [ other.to_matrix, self ]
      else
        raise TypeError, "Can't coerce #{other.class} into #{self.class}"
      end
    end

    # @group Equality

    # Element-by-element comparison.
    def ==(other)
      if (self.m != other.m || self.n != other.n) then return false end

      @m.times do |i|
        @n.times do |j|
          if (self[i,j] != other[i,j]) then return false end
        end
      end
      
      return true
    end
  end
end
