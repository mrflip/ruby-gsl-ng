module GSLng
  class Matrix
    # A View of a Matrix.
    #
    # Views reference an existing Matrix and can be used to access parts of it without having to copy
    # it entirely. You can treat a View just like a Matrix.
    # But note that modifying elements of a View will modify the elements of the original matrix.
    #
    class View < Matrix
      attr_reader :owner # The Matrix owning the data this View uses

      # Create a Matrix::View of the sub-matrix starting at (x,y), of size (m,n)
      def initialize(owner, x, y, m, n) # @private
        @owner = owner
        @m,@n = m,n

        @backend = GSLng.backend
        ptr = GSLng.backend::gsl_matrix_submatrix2(owner.ptr, x, y, m, n)
        @view_ptr = FFI::AutoPointer.new(ptr, View.method(:release))
        @ptr = GSLng.backend::gsl_matrix_view_get_matrix(@view_ptr)
        @ptr_value = @ptr.to_i
      end

      def View.release(ptr)
        GSLng.backend.gsl_matrix_view_free(ptr)
      end

      # Returns a Matrix (*NOT* a View) copied from this view. In other words,
      # you'll get a Matrix which you can modify without modifying #owner elements.
      # @return [Matrix]
      def dup
        matrix = Matrix.new(@m, @n)
        GSLng.backend::gsl_matrix_memcpy(matrix.ptr, @ptr)
        return matrix
      end
      alias_method :clone, :dup
      alias_method :to_matrix, :dup

      def view  # @private
        raise "Can't create a View from a View"
      end

      def inspect # @private
        "#{self}:MatrixView"
      end
    end
  end
end
