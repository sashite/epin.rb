# epin.rb

[![Version](https://img.shields.io/github/v/tag/sashite/epin.rb?label=Version&logo=github)](https://github.com/sashite/epin.rb/tags)
[![Yard documentation](https://img.shields.io/badge/Yard-documentation-blue.svg?logo=github)](https://rubydoc.info/github/sashite/epin.rb/main)
[![CI](https://github.com/sashite/epin.rb/actions/workflows/ruby.yml/badge.svg?branch=main)](https://github.com/sashite/epin.rb/actions)
[![License](https://img.shields.io/github/license/sashite/epin.rb?label=License&logo=github)](https://github.com/sashite/epin.rb/raw/main/LICENSE)

> **EPIN** (Extended Piece Identifier Notation) implementation for Ruby.

## Overview

This library implements the [EPIN Specification v1.0.0](https://sashite.dev/specs/epin/1.0.0/).

EPIN extends [PIN](https://sashite.dev/specs/pin/1.0.0/) with an optional derivation marker (`'`) that flags whether a piece uses a native or derived style. Every valid PIN token is also a valid EPIN token (native by default).

### Implementation Constraints

| Constraint | Value | Rationale |
|------------|-------|-----------|
| Token length | 1–4 characters | `[+-]?[A-Za-z]\^?'?` per spec |
| Character space | 624 tokens | 312 PIN tokens × 2 derivation statuses |
| Instance pool | 624 objects | All identifiers are pre-instantiated and frozen |

The closed domain of 624 possible values enables a flyweight architecture with zero allocation on the hot path.

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

# PIN component is a cached Sashite::Pin::Identifier instance
epin.pin.enhanced?      # => false
epin.pin.first_player?  # => true

# Returns a cached instance — no allocation
Sashite::Epin.parse("K^'").equal?(Sashite::Epin.parse("K^'"))  # => true

# Invalid input raises ArgumentError
Sashite::Epin.parse("invalid")  # => raises ArgumentError
```

### Safe Parsing (String → Identifier | nil)

Parse without raising exceptions. Returns `nil` on invalid input.

```ruby
# Valid input returns an Identifier
Sashite::Epin.safe_parse("K^'")   # => #<Sashite::Epin::Identifier K^'>
Sashite::Epin.safe_parse("+R")    # => #<Sashite::Epin::Identifier +R>

# Invalid input returns nil — no exception allocated
Sashite::Epin.safe_parse("")        # => nil
Sashite::Epin.safe_parse("invalid") # => nil
Sashite::Epin.safe_parse("K''")     # => nil
Sashite::Epin.safe_parse(nil)       # => nil
```

### Fetching by Components (Pin::Identifier, ... → Identifier)

Retrieve a cached identifier directly by components, bypassing string parsing entirely.

```ruby
# From a cached PIN instance — direct hash lookup, no allocation
pin = Sashite::Pin.parse("K^")
Sashite::Epin.fetch(pin)                  # => #<Sashite::Epin::Identifier K^>
Sashite::Epin.fetch(pin, derived: true)   # => #<Sashite::Epin::Identifier K^'>

# Same cached instance as parse
Sashite::Epin.fetch(pin, derived: true).equal?(Sashite::Epin.parse("K^'"))  # => true

# Invalid PIN raises ArgumentError
Sashite::Epin.fetch(nil)  # => raises ArgumentError
```

### Formatting (Identifier → String)

Convert an `Identifier` back to an EPIN string.

```ruby
epin = Sashite::Epin.parse("K^'")
epin.to_s  # => "K^'"

epin = Sashite::Epin.parse("+r")
epin.to_s  # => "+r"
```

### Validation

```ruby
# Boolean check (never raises)
# Uses an exception-free code path internally for performance.
Sashite::Epin.valid?("K")         # => true
Sashite::Epin.valid?("+R^'")      # => true
Sashite::Epin.valid?("invalid")   # => false
Sashite::Epin.valid?("K''")       # => false
Sashite::Epin.valid?("K'^")       # => false
Sashite::Epin.valid?(nil)         # => false
```

### Transformations

All transformations return cached instances from the flyweight pool — no new object is ever allocated.

```ruby
epin = Sashite::Epin.parse("K^")

# Derivation transformations
epin.derive.to_s  # => "K^'"
epin.native.to_s  # => "K^"

# Replace PIN component
new_pin = Sashite::Pin.parse("+Q^")
epin.with_pin(new_pin).to_s  # => "+Q^"

# Transformations return cached instances
epin.derive.equal?(Sashite::Epin.parse("K^'"))  # => true
```

### Transform via PIN Component

PIN transformations also return cached instances, so the entire chain is allocation-free.

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

### Accessing Components

```ruby
epin = Sashite::Epin.parse("+R^'")

# Get PIN component (cached Pin::Identifier instance)
epin.pin       # => #<Sashite::Pin::Identifier +R^>
epin.pin.to_s  # => "+R^"

# Check derivation
epin.derived?  # => true
epin.native?   # => false

# Serialize
epin.to_s  # => "+R^'"
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

### PIN Compatibility

Every valid PIN is a valid EPIN (native by default):

```ruby
%w[K +R -p K^ +R^].each do |pin_token|
  epin = Sashite::Epin.parse(pin_token)
  epin.native?  # => true
  epin.to_s     # => pin_token
end
```

## API Reference

### Module Methods

```ruby
# Parses an EPIN string into a cached Identifier.
# Returns a pre-instantiated, frozen instance.
# Raises ArgumentError if the string is not valid.
#
# @param string [String] EPIN string
# @return [Identifier]
# @raise [ArgumentError] if invalid
def Sashite::Epin.parse(string)

# Parses an EPIN string without raising.
# Returns a cached Identifier on success, nil on failure.
# Never allocates exception objects or captures backtraces.
# Delegates to Pin.safe_parse for the PIN component.
#
# @param string [String] EPIN string
# @return [Identifier, nil]
def Sashite::Epin.safe_parse(string)

# Retrieves a cached Identifier by PIN component and derivation status.
# Bypasses string parsing entirely — direct hash lookup.
# Raises ArgumentError if the PIN is invalid.
#
# @param pin [Sashite::Pin::Identifier] PIN component
# @param derived [Boolean] Derived status
# @return [Identifier]
# @raise [ArgumentError] if invalid
def Sashite::Epin.fetch(pin, derived: false)

# Reports whether string is a valid EPIN.
# Never raises; returns false for any invalid input.
# Uses an exception-free code path internally for performance.
#
# @param string [String] EPIN string
# @return [Boolean]
def Sashite::Epin.valid?(string)
```

### Identifier

```ruby
# Identifier represents a parsed EPIN combining PIN with derivation status.
# All instances are frozen and pre-instantiated — never construct directly,
# use Sashite::Epin.parse, .safe_parse, or .fetch instead.
class Sashite::Epin::Identifier
  # Returns the PIN component (a cached Sashite::Pin::Identifier instance).
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

### Transformations

All transformations return cached `Sashite::Epin::Identifier` instances from the flyweight pool:

```ruby
# PIN replacement (returns cached Identifier)
def with_pin(new_pin)  # => Identifier with different PIN

# Derivation transformations
def derive  # => Identifier with derived: true
def native  # => Identifier with derived: false
```

### Errors

All errors raise `ArgumentError` with descriptive messages:

| Message | Cause |
|---------|-------|
| `"invalid derivation marker"` | Derivation marker misplaced or duplicated |
| `"invalid PIN component: ..."` | PIN parsing failed |

## Design Principles

- **Spec conformance**: Strict adherence to EPIN v1.0.0
- **Flyweight identifiers**: All 624 possible instances are pre-built and frozen; parsing, fetching, and transformations return cached objects with zero allocation
- **Pure composition**: EPIN composes PIN without reimplementing features; each EPIN instance holds a cached `Pin::Identifier` from PIN's own flyweight pool
- **Performance-oriented internals**: Exception-free validation path; exceptions only at the public API boundary
- **Component transparency**: Access PIN directly, no wrapper methods
- **Ruby idioms**: `valid?` predicate, `to_s` conversion, `ArgumentError` for invalid input
- **Immutable identifiers**: All instances are frozen after creation

### Performance Architecture

EPIN has a closed domain of exactly 624 valid tokens (312 PIN tokens × 2 derivation statuses). The implementation exploits this constraint through three complementary strategies, composing cleanly with PIN's own flyweight pool.

**Flyweight instance pool** — All 624 `Identifier` objects are pre-instantiated and frozen at load time. Each holds a reference to a cached `Pin::Identifier` from PIN's own pool — no duplication of PIN objects. `parse`, `safe_parse`, `fetch`, and all transformation methods return these cached instances via hash lookup. No `Identifier` is ever allocated after the module loads.

**Dual-path parsing** — Parsing is split into two layers to avoid using exceptions for control flow:

- **Validation layer** — `safe_parse` strips the trailing `'` if present, delegates to `Pin.safe_parse` for the core token, and returns the cached `Identifier` on success or `nil` on failure. The entire path — EPIN and PIN combined — never raises, never allocates exception objects, and never captures backtraces.
- **Public API layer** — `parse` calls `safe_parse` internally. On failure, it raises `ArgumentError` exactly once, at the boundary. `valid?` calls `safe_parse` and returns a boolean directly, never raising.

**Zero-allocation transformations** — `derive`, `native`, and `with_pin` compute the target components and perform a direct lookup into the instance pool. Since PIN transformations (`flip`, `enhance`, etc.) also return cached instances, chaining like `epin.with_pin(epin.pin.flip.enhance).derive` performs only hash lookups across both pools — zero allocations end to end.

**Direct component lookup** — `fetch` accepts a `Pin::Identifier` and a derivation flag, performing a single hash lookup. This is the fastest path for callers that already have structured data (e.g., FEEN's piece placement parser constructing EPIN identifiers from already-parsed PIN components).

This architecture ensures that the full SIN → PIN → EPIN → FEEN stack maintains allocation-free hot paths from bottom to top.

## Related Specifications

- [Game Protocol](https://sashite.dev/game-protocol/) — Conceptual foundation
- [EPIN Specification](https://sashite.dev/specs/epin/1.0.0/) — Official specification
- [EPIN Examples](https://sashite.dev/specs/epin/1.0.0/examples/) — Usage examples
- [PIN Specification](https://sashite.dev/specs/pin/1.0.0/) — Base component

## License

Available as open source under the [Apache License 2.0](https://opensource.org/licenses/Apache-2.0).
