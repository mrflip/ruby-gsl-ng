module GSLng
  backend.instance_eval do
    # memory handling
    attach_function :gsl_matrix_alloc, [ :size_t, :size_t ], :pointer
    attach_function :gsl_matrix_calloc, [ :size_t, :size_t ], :pointer
    attach_function :gsl_matrix_free, [ :pointer ], :void

    # initializing
    attach_function :gsl_matrix_set_all, [ :pointer, :double ], :void
    attach_function :gsl_matrix_set_zero, [ :pointer ], :void
    attach_function :gsl_matrix_set_identity, [ :pointer ], :void

    # copying
    attach_function :gsl_matrix_memcpy, [ :pointer, :pointer ], :int

    # operations
    attach_function :gsl_matrix_add, [ :pointer, :pointer ], :int
    attach_function :gsl_matrix_sub, [ :pointer, :pointer ], :int
    attach_function :gsl_matrix_mul_elements, [ :pointer, :pointer ], :int
    attach_function :gsl_matrix_div_elements, [ :pointer, :pointer ], :int
    attach_function :gsl_matrix_scale, [ :pointer, :double ], :int
    attach_function :gsl_matrix_add_constant, [ :pointer, :double ], :int

    # copy rows/columns into
    attach_function :gsl_matrix_get_row, [ :pointer, :pointer, :size_t ], :int
    attach_function :gsl_matrix_get_col, [ :pointer, :pointer, :size_t ], :int
    attach_function :gsl_matrix_set_row, [ :pointer, :size_t, :pointer ], :int
    attach_function :gsl_matrix_set_col, [ :pointer, :size_t, :pointer ], :int

    # element access
    attach_function :gsl_matrix_get, [ :pointer, :size_t, :size_t ], :double
    attach_function :gsl_matrix_set, [ :pointer, :size_t, :size_t, :double ], :void
    
    # properties
    attach_function :gsl_matrix_isnull, [ :pointer ], :int
    attach_function :gsl_matrix_ispos, [ :pointer ], :int
    attach_function :gsl_matrix_isneg, [ :pointer ], :int
    attach_function :gsl_matrix_isnonneg, [ :pointer ], :int

    # max and min
    attach_function :gsl_matrix_max, [ :pointer ], :double
    attach_function :gsl_matrix_min, [ :pointer ], :double
    attach_function :gsl_matrix_minmax, [ :pointer, :buffer_out, :buffer_out ], :void
    attach_function :gsl_matrix_max_index, [ :pointer, :buffer_out, :buffer_out ], :void
    attach_function :gsl_matrix_min_index, [ :pointer, :buffer_out, :buffer_out ], :void
    attach_function :gsl_matrix_minmax_index, [ :pointer, :buffer_out, :buffer_out, :buffer_out, :buffer_out ], :void

    # exchange elements
    attach_function :gsl_matrix_swap_rows, [ :pointer, :size_t, :size_t ], :int
    attach_function :gsl_matrix_swap_columns, [ :pointer, :size_t, :size_t ], :int
    attach_function :gsl_matrix_swap_rowcol, [ :pointer, :size_t, :size_t ], :int
    attach_function :gsl_matrix_transpose_memcpy, [ :pointer, :pointer ], :int
    attach_function :gsl_matrix_transpose, [ :pointer ], :int
    
    # From local extension    
    # views
    attach_function :gsl_matrix_submatrix2, [ :pointer, :size_t, :size_t, :size_t, :size_t ], :pointer
    attach_function :gsl_matrix_row_view, [ :pointer, :size_t, :size_t, :size_t ], :pointer
    attach_function :gsl_matrix_column_view, [ :pointer, :size_t, :size_t, :size_t ], :pointer
    attach_function :gsl_matrix_view_get_matrix, [ :pointer ], :pointer
    attach_function :gsl_matrix_view_free, [ :pointer ], :void

    # slide
    attach_function :gsl_matrix_slide, [ :pointer, :ssize_t, :ssize_t ], :void

    # BLAS interface
    enum :cblas_transpose_t, [ :no_transpose, 111, :transpose, :conjugate_transpose ]
    attach_function :gsl_blas_dgemv, [ :cblas_transpose_t, :double, :pointer, :pointer, :double, :pointer ], :int
    attach_function :gsl_blas_dgemm, [ :cblas_transpose_t, :cblas_transpose_t, :double, :pointer, :pointer, :double, :pointer ], :int

    # communication to gnuplot
    attach_function :gsl_matrix_putdata, [ :pointer, :int ], :int
  end
end
