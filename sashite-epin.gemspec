# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name    = "sashite-epin"
  spec.version = ::File.read("VERSION.semver").chomp
  spec.author  = "Cyril Kato"
  spec.email   = "contact@cyril.email"
  spec.summary = "EPIN (Extended Piece Identifier Notation) implementation for Ruby extending PIN with style derivation markers."

  spec.description = <<~DESC
    EPIN (Extended Piece Identifier Notation) implementation for Ruby.
    Extends PIN by adding a derivation marker to track piece style in cross-style
    abstract strategy board games with a minimal compositional API.
  DESC

  spec.homepage               = "https://github.com/sashite/epin.rb"
  spec.license                = "MIT"
  spec.files                  = ::Dir["LICENSE.md", "README.md", "lib/**/*"]
  spec.required_ruby_version  = ">= 3.2.0"

  spec.add_dependency "sashite-pin", "~> 3.3.0"

  spec.metadata = {
    "bug_tracker_uri"       => "https://github.com/sashite/epin.rb/issues",
    "documentation_uri"     => "https://rubydoc.info/github/sashite/epin.rb/main",
    "homepage_uri"          => "https://github.com/sashite/epin.rb",
    "source_code_uri"       => "https://github.com/sashite/epin.rb",
    "specification_uri"     => "https://sashite.dev/specs/epin/1.0.0/",
    "rubygems_mfa_required" => "true"
  }
end
