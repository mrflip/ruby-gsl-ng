require 'ffi'

module GSLng
  # Anonymous module: avoids exposing this internal module when doing "include GSLng" at the top-level.
  # If ruby had "private" modules I wouldn't have to do this.
  @backend = Module.new do
    extend FFI::Library
    ffi_lib(FFI::CURRENT_PROCESS)
  end

  # Returns the internal backend module
  def GSLng.backend # @private
    @backend
  end
end

require 'gslng_extensions'
require 'gslng/backend_components/vector'
require 'gslng/backend_components/matrix'
require 'gslng/backend_components/error_handling'
require 'gslng/backend_components/rng'
require 'gslng/backend_components/special'
require 'gslng/backend_components/stats'
require 'gslng/backend_components/fit'
