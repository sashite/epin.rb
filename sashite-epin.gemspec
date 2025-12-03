# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name    = "sashite-epin"
  spec.version = ::File.read("VERSION.semver").chomp
  spec.author  = "Cyril Kato"
  spec.email   = "contact@cyril.email"
  spec.summary = "EPIN (Extended Piece Identifier Notation) implementation for Ruby extending PIN with style derivation markers."

  spec.description = <<~DESC
    EPIN (Extended Piece Identifier Notation) extends PIN to provide style-aware piece representation
    in abstract strategy board games. This gem implements the EPIN Specification v1.0.0 with
    a modern Ruby interface featuring immutable identifier objects and functional programming
    principles. EPIN adds derivation markers to PIN that distinguish pieces by their style
    origin, enabling cross-style game scenarios and piece origin tracking. Represents all
    four Game Protocol piece attributes with full PIN backward compatibility. Perfect for
    game engines, cross-tradition tournaments, and hybrid board game environments.
  DESC

  spec.homepage               = "https://github.com/sashite/epin.rb"
  spec.license                = "MIT"
  spec.files                  = ::Dir["LICENSE.md", "README.md", "lib/**/*"]
  spec.required_ruby_version  = ">= 3.2.0"

  spec.add_dependency "sashite-pin", "~> 3.2.0"

  spec.metadata = {
    "bug_tracker_uri"       => "https://github.com/sashite/epin.rb/issues",
    "documentation_uri"     => "https://rubydoc.info/github/sashite/epin.rb/main",
    "homepage_uri"          => "https://github.com/sashite/epin.rb",
    "source_code_uri"       => "https://github.com/sashite/epin.rb",
    "specification_uri"     => "https://sashite.dev/specs/epin/1.0.0/",
    "rubygems_mfa_required" => "true"
  }
end
