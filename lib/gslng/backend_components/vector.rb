module GSLng
  backend.instance_eval do
    # memory handling
    attach_function :gsl_vector_alloc, [ :size_t ], :pointer
    attach_function :gsl_vector_calloc, [ :size_t ], :pointer
    attach_function :gsl_vector_free, [ :pointer ], :void

    # initializing
    attach_function :gsl_vector_set_all, [ :pointer, :double ], :void
    attach_function :gsl_vector_set_zero, [ :pointer ], :void
    attach_function :gsl_vector_set_basis, [ :pointer, :size_t ], :int

    # operations
    attach_function :gsl_vector_add, [ :pointer, :pointer ], :int
    attach_function :gsl_vector_sub, [ :pointer, :pointer ], :int
    attach_function :gsl_vector_mul, [ :pointer, :pointer ], :int
    attach_function :gsl_vector_div, [ :pointer, :pointer ], :int
    attach_function :gsl_vector_scale, [ :pointer, :double ], :int
    attach_function :gsl_vector_add_constant, [ :pointer, :double ], :int

    # element access
    attach_function :gsl_vector_get, [ :pointer, :size_t ], :double
    attach_function :gsl_vector_set, [ :pointer, :size_t, :double ], :void

    # properties
    attach_function :gsl_vector_isnull, [ :pointer ], :int
    attach_function :gsl_vector_ispos, [ :pointer ], :int
    attach_function :gsl_vector_isneg, [ :pointer ], :int
    attach_function :gsl_vector_isnonneg, [ :pointer ], :int

    # max and min
    attach_function :gsl_vector_max, [ :pointer ], :double
    attach_function :gsl_vector_min, [ :pointer ], :double
    attach_function :gsl_vector_minmax, [ :pointer, :buffer_out, :buffer_out ], :void
    attach_function :gsl_vector_max_index, [ :pointer ], :size_t
    attach_function :gsl_vector_min_index, [ :pointer ], :size_t
    attach_function :gsl_vector_minmax_index, [ :pointer, :buffer_out, :buffer_out ], :void

    # copying
    attach_function :gsl_vector_memcpy, [ :pointer, :pointer ], :int

    # exchanging elements
    attach_function :gsl_vector_swap_elements, [ :pointer, :size_t, :size_t ], :int
    attach_function :gsl_vector_reverse, [ :pointer ], :int

    # BLAS functions
    attach_function :gsl_blas_ddot, [ :pointer, :pointer, :buffer_out ], :int
    attach_function :gsl_blas_dnrm2, [ :pointer ], :double
    attach_function :gsl_blas_dasum, [ :pointer ], :double
    #attach_function :gsl_blas_idamax, [ :pointer ], clbas_index??
    #attach_function :gsl_blas_dcopy, use this instead of memcpy?
    attach_function :gsl_blas_daxpy, [ :double, :pointer, :pointer ], :int
    attach_function :gsl_blas_dscal, [ :double, :pointer ], :void

    # Sorting
    attach_function :gsl_sort_vector, [ :pointer ], :void
    
    # From local extension
    # views
    attach_function :gsl_vector_subvector2, [ :pointer, :size_t, :size_t, :size_t ], :pointer
    attach_function :gsl_vector_view_get_vector, [ :pointer ], :pointer
    attach_function :gsl_vector_view_free, [ :pointer ], :void
    attach_function :gsl_vector_as_array, [ :pointer ], :pointer    
  end
end
