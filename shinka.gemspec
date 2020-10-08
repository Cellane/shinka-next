# frozen_string_literal: true

require_relative 'lib/shinka/version'

Gem::Specification.new do |spec|
  spec.name          = 'Shinka'
  spec.license       = 'MIT'
  spec.version       = Shinka::VERSION
  spec.authors       = ['Milan Vit']
  spec.email         = ['milanvit@milanvit.net']

  spec.summary       = 'Tool for mass-updating Dokku applications deployed as pre-built Docker images'
  spec.description   = 'Tool for mass-updating Dokku applications deployed as Docker images from Docker Hub or private repositories (using dokku tags:deploy), and for cleaning old and unused images.'
  spec.homepage      = 'https://github.com/Cellane/shinka'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
