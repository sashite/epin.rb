# epin.rb

[![Version](https://img.shields.io/github/v/tag/sashite/epin.rb?label=Version&logo=github)](https://github.com/sashite/epin.rb/tags)
[![Yard documentation](https://img.shields.io/badge/Yard-documentation-blue.svg?logo=github)](https://rubydoc.info/github/sashite/epin.rb/main)
[![CI](https://github.com/sashite/epin.rb/actions/workflows/ruby.yml/badge.svg?branch=main)](https://github.com/sashite/epin.rb/actions)
[![License](https://img.shields.io/github/license/sashite/epin.rb?label=License&logo=github)](https://github.com/sashite/epin.rb/raw/main/LICENSE)

> **EPIN** (Extended Piece Identifier Notation) implementation for Ruby.

## Overview

This library implements the [EPIN Specification v1.0.0](https://sashite.dev/specs/epin/1.0.0/).

EPIN extends [PIN](https://sashite.dev/specs/pin/1.0.0/) with an optional derivation marker (`'`) that flags whether a piece uses a native or derived style.

## Installation

```ruby
# In your Gemfile
gem "sashite-epin"
```

Or install manually:

```sh
gem install sashite-epin
```

## Dependencies

```ruby
gem "sashite-pin"  # Piece Identifier Notation
```

## Usage

### Parsing (String → Identifier)

Convert an EPIN string into an `Identifier` object.

```ruby
require "sashite/epin"

# Standard parsing (raises on error)
epin = Sashite::Epin.parse("K^'")
epin.to_s  # => "K^'"

# Access PIN attributes through the component
epin.pin.abbr       # => :K
epin.pin.side       # => :first
epin.pin.state      # => :normal
epin.pin.terminal?  # => true

# Access derivation status
epin.derived?  # => true
epin.native?   # => false

# PIN component is a full Sashite::Pin::Identifier instance
epin.pin.enhanced?      # => false
epin.pin.first_player?  # => true

# Invalid input raises ArgumentError
Sashite::Epin.parse("invalid")  # => raises ArgumentError
```

### Formatting (Identifier → String)

Convert an `Identifier` back to an EPIN string.

```ruby
# From PIN component
pin = Sashite::Pin.parse("K^")
epin = Sashite::Epin::Identifier.new(pin)
epin.to_s  # => "K^"

# With derivation
epin = Sashite::Epin::Identifier.new(pin, derived: true)
epin.to_s  # => "K^'"
```

### Validation

```ruby
# Boolean check
Sashite::Epin.valid?("K")         # => true
Sashite::Epin.valid?("+R^'")      # => true
Sashite::Epin.valid?("invalid")   # => false
Sashite::Epin.valid?("K''")       # => false
Sashite::Epin.valid?("K'^")       # => false
```

### Accessing Components

```ruby
epin = Sashite::Epin.parse("+R^'")

# Get PIN component
epin.pin       # => #<Sashite::Pin::Identifier +R^>
epin.pin.to_s  # => "+R^"

# Check derivation
epin.derived?  # => true
epin.native?   # => false

# Serialize
epin.to_s  # => "+R^'"
```

### Transformations

All transformations return new immutable instances.

```ruby
epin = Sashite::Epin.parse("K^")

# Derivation transformations
epin.derive.to_s  # => "K^'"
epin.native.to_s  # => "K^"

# Replace PIN component
new_pin = Sashite::Pin.parse("+Q^")
epin.with_pin(new_pin).to_s  # => "+Q^"
```

### Transform via PIN Component

```ruby
epin = Sashite::Epin.parse("K^'")

# Change abbr
epin.with_pin(epin.pin.with_abbr(:Q)).to_s  # => "Q^'"

# Change state
epin.with_pin(epin.pin.enhance).to_s  # => "+K^'"

# Change side
epin.with_pin(epin.pin.flip).to_s  # => "k^'"

# Remove terminal
epin.with_pin(epin.pin.non_terminal).to_s  # => "K'"
```

### Component Queries

Use the PIN API directly:

```ruby
epin = Sashite::Epin.parse("+P^'")

# PIN queries
epin.pin.abbr          # => :P
epin.pin.side          # => :first
epin.pin.state         # => :enhanced
epin.pin.terminal?     # => true
epin.pin.first_player? # => true
epin.pin.enhanced?     # => true

# EPIN queries
epin.derived?  # => true
epin.native?   # => false

# Compare EPINs
other = Sashite::Epin.parse("+P^")
epin.pin.same_abbr?(other.pin)   # => true
epin.pin.same_state?(other.pin)  # => true
epin.same_derived?(other)        # => false
```

## API Reference

### Types

```ruby
# Identifier represents a parsed EPIN combining PIN with derivation status.
class Sashite::Epin::Identifier
  # Creates an Identifier from a PIN component.
  # Raises ArgumentError if the PIN is invalid.
  #
  # @param pin [Sashite::Pin::Identifier] PIN component
  # @param derived [Boolean] Derived status
  # @return [Identifier]
  def initialize(pin, derived: false)

  # Returns the PIN component.
  #
  # @return [Sashite::Pin::Identifier]
  def pin

  # Returns true if derived style.
  #
  # @return [Boolean]
  def derived?

  # Returns true if native style.
  #
  # @return [Boolean]
  def native?

  # Returns the EPIN string representation.
  #
  # @return [String]
  def to_s
end
```

### Parsing

```ruby
# Parses an EPIN string into an Identifier.
# Raises ArgumentError if the string is not valid.
#
# @param string [String] EPIN string
# @return [Identifier]
# @raise [ArgumentError] if invalid
def Sashite::Epin.parse(string)
```

### Validation

```ruby
# Reports whether string is a valid EPIN.
#
# @param string [String] EPIN string
# @return [Boolean]
def Sashite::Epin.valid?(string)
```

### Transformations

```ruby
# PIN replacement (returns new Identifier)
def with_pin(new_pin)  # => Identifier with different PIN

# Derivation transformations
def derive  # => Identifier with derived: true
def native  # => Identifier with derived: false
```

### Errors

All parsing and validation errors raise `ArgumentError` with descriptive messages:

| Message | Cause |
|---------|-------|
| `"invalid derivation marker"` | Derivation marker misplaced or duplicated |
| `"invalid PIN component: ..."` | PIN parsing failed |

## PIN Compatibility

Every valid PIN is a valid EPIN (native by default):

```ruby
%w[K +R -p K^ +R^].each do |pin_token|
  epin = Sashite::Epin.parse(pin_token)
  epin.native?  # => true
  epin.to_s     # => pin_token
end
```

## Design Principles

- **Pure composition**: EPIN composes PIN without reimplementing features
- **Minimal API**: Core methods (`pin`, `derived?`, `native?`, `to_s`) plus transformations
- **Component transparency**: Access PIN directly, no wrapper methods
- **Immutable identifiers**: Frozen instances prevent mutation
- **Ruby idioms**: `valid?` predicate, `to_s` conversion, `ArgumentError` for invalid input

## Related Specifications

- [Game Protocol](https://sashite.dev/game-protocol/) — Conceptual foundation
- [EPIN Specification](https://sashite.dev/specs/epin/1.0.0/) — Official specification
- [EPIN Examples](https://sashite.dev/specs/epin/1.0.0/examples/) — Usage examples
- [PIN Specification](https://sashite.dev/specs/pin/1.0.0/) — Base component

## License

Available as open source under the [Apache License 2.0](https://opensource.org/licenses/Apache-2.0).
