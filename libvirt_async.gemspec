require_relative 'lib/libvirt_async/version'

Gem::Specification.new do |spec|
  spec.name          = 'libvirt_async'
  spec.version       = LibvirtAsync::VERSION
  spec.authors       = ['Denis Talakevich']
  spec.email         = ['senid231@gmail.com']

  spec.summary       = 'Libvirt event async implementation.'
  spec.description   = 'Libvirt event implementation on Fibers based on libvirt-ruby and async gems.'
  spec.homepage      = 'https://github.com/senid231/libvirt_async'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'ruby-libvirt', '~> 0.7'
  spec.add_dependency 'async', '~> 1.24'
  spec.add_dependency 'activesupport'
end
