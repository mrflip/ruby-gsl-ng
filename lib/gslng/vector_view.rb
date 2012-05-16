module GSLng
  class Vector
    # A View of a Vector.
    #
    # Views reference an existing Vector (or a row/column from a Matrix) and can be used to access parts of it without
    # having to copy it entirely. You can treat a View just like a Vector.
    # But note that modifying elements of a View will modify the elements of the original Vector/Matrix.
    #
    # Note also that Views are not meant to be created explicitly, but through methods of the Vector/Matrix classes
    #
    class View < Vector
      # @return [Vector,Matrix] The owner of the data this view accesses
      attr_reader :owner 
      
      def initialize(owner, view_ptr, size, stride)
        @backend = GSLng.backend
        @owner,@size,@stride = owner,size,stride
        @view_ptr = FFI::AutoPointer.new(view_ptr, View.method(:release))
        @ptr = GSLng.backend.gsl_vector_view_get_vector(@view_ptr)
        @ptr_value = @ptr.to_i
      end

      def View.release(ptr)
        GSLng.backend.gsl_vector_view_free(ptr)
      end
      
      # Returns a Vector (*NOT* a View) copied from this view. In other words,
      # you'll get a Vector which you can modify without modifying {#owner}'s elements
      # @return [Vector]
      def dup
        v = Vector.new(@size)
        @backend.gsl_vector_memcpy(v.ptr, @ptr)
        return v
      end
      alias_method :clone, :dup
      alias_method :to_vector, :dup

      def view # @private
        raise "Can't create a View from a View"
      end

      def inspect # @private
        "#{self}:VectorView"
      end
    end
  end
end
