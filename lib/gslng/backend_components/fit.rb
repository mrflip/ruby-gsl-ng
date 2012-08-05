module GSLng
  backend.instance_eval do

    # regression analysis
    attach_function :gsl_fit_linear, [:pointer, :size_t, :pointer, :size_t, :size_t, :buffer_out, :buffer_out, :buffer_out, :buffer_out, :buffer_out, :buffer_out], :int

  end
end
