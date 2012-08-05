# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors = ["ronen barzel", "v01d"]
  gem.email = ["ronen@barzel.org"]
  gem.description = "Ruby/GSL new-generation wrapper (memory leak fix)"
  gem.summary = "Ruby/GSL new-generation wrapper (memory leak fix)"
  gem.homepage = "http://github.com/ronen/gsl-ng"

  gem.extra_rdoc_files = ["README.rdoc", "ext/extconf.rb", "ext/gslng_extensions.cpp", "ext/plotting.cpp", "lib/core_extensions/array.rb", "lib/gslng.rb", "lib/gslng/backend.rb", "lib/gslng/backend_components/error_handling.rb", "lib/gslng/backend_components/matrix.rb", "lib/gslng/backend_components/rng.rb", "lib/gslng/backend_components/special.rb", "lib/gslng/backend_components/stats.rb", "lib/gslng/backend_components/vector.rb", "lib/gslng/matrix.rb", "lib/gslng/matrix_view.rb", "lib/gslng/plotter.rb", "lib/gslng/rng/gaussian.rb", "lib/gslng/rng/rng.rb", "lib/gslng/rng/uniform.rb", "lib/gslng/special.rb", "lib/gslng/vector.rb", "lib/gslng/vector_view.rb"]
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")

  gem.name = "ruby-gsl-ngx"
  gem.require_paths = ["lib", "ext"]
  gem.version = "0.2.6.1"
  gem.extensions = ["ext/extconf.rb"]

  gem.add_dependency "ffi"
  gem.add_development_dependency "yard"
end
