# Sashite::Epin

[![Version](https://img.shields.io/github/v/tag/sashite/epin.rb?label=Version&logo=github)](https://github.com/sashite/epin.rb/tags)
[![Yard documentation](https://img.shields.io/badge/Yard-documentation-blue.svg?logo=github)](https://rubydoc.info/github/sashite/epin.rb/main)
![Ruby](https://github.com/sashite/epin.rb/actions/workflows/main.yml/badge.svg?branch=main)
[![License](https://img.shields.io/github/license/sashite/epin.rb?label=License&logo=github)](https://github.com/sashite/epin.rb/raw/main/LICENSE.md)

> **EPIN** (Extended Piece Identifier Notation) implementation for Ruby.

## What is EPIN?

EPIN (Extended Piece Identifier Notation) extends [PIN](https://sashite.dev/specs/pin/1.0.0/) by adding a **derivation marker** to track piece style in cross-style games.

**EPIN is simply: PIN + optional style derivation marker (`'`)**

This gem implements the [EPIN Specification v1.0.0](https://sashite.dev/specs/epin/1.0.0/) with a minimal compositional API.

## Installation

```ruby
# In your Gemfile
gem "sashite-epin"
```

Or install manually:

```sh
gem install sashite-epin
```

This will also install `sashite-pin` as a dependency.

## Core Concept

```ruby
require "sashite/epin"

# EPIN is just PIN + derived flag
pin = Sashite::Pin.parse("K^")
epin = Sashite::Epin.new(pin)

epin.to_s     # => "K^" (native)
epin.pin      # => #<Sashite::Pin K^>
epin.derived  # => false

# Mark as derived
derived_epin = epin.mark_derived
derived_epin.to_s # => "K^'" (derived from opposite side's style)
```

**That's it.** All piece attributes come from the PIN component.

## Usage

```ruby
require "sashite/epin"

# Parse EPIN strings
epin = Sashite::Epin.parse("K^'")
epin.to_s # => "K^'"

# Access five fundamental attributes through PIN component + derived flag
epin.pin.type       # => :K (Piece Name)
epin.pin.side       # => :first (Piece Side)
epin.pin.state      # => :normal (Piece State)
epin.pin.terminal   # => true (Terminal Status)
epin.derived        # => true (Piece Style: derived vs native)

# PIN component is a full Sashite::Pin instance
epin.pin.enhanced?      # => false
epin.pin.letter         # => "K"
epin.pin.first_player?  # => true
```

### Creating Identifiers

```ruby
# Parse from string
epin = Sashite::Epin.parse("K^")    # Native
epin = Sashite::Epin.parse("K^'")   # Derived

# Create from PIN component
pin = Sashite::Pin.parse("K^")
epin = Sashite::Epin.new(pin)                 # Native (default)
epin = Sashite::Epin.new(pin, derived: true)  # Derived

# Validation
Sashite::Epin.valid?("K^")    # => true
Sashite::Epin.valid?("K^'")   # => true
Sashite::Epin.valid?("K^''")  # => false (multiple markers)
Sashite::Epin.valid?("K'^")   # => false (wrong order)
```

### Accessing Components

```ruby
epin = Sashite::Epin.parse("+R^'")

# Get PIN component
epin.pin         # => #<Sashite::Pin +R^>
epin.pin.to_s    # => "+R^"

# Check derivation
epin.derived     # => true
epin.derived?    # => true
epin.native?     # => false

# Serialize
epin.to_s # => "+R^'"
```

### Transformations

All transformations return new immutable instances.

```ruby
epin = Sashite::Epin.parse("K^")

# Mark as derived
derived = epin.mark_derived
derived.to_s # => "K^'"

# Mark as native
native = derived.unmark_derived
native.to_s # => "K^"

# Set explicitly
toggled = epin.with_derived(true)
toggled.to_s # => "K^'"
```

### Transform via PIN Component

```ruby
epin = Sashite::Epin.parse("K^'")

# Replace PIN component
new_pin = epin.pin.with_type(:Q)
epin.with_pin(new_pin).to_s # => "Q^'"

# Change state
new_pin = epin.pin.enhance
epin.with_pin(new_pin).to_s # => "+K^'"

# Remove terminal marker
new_pin = epin.pin.unmark_terminal
epin.with_pin(new_pin).to_s # => "K'"

# Change side
new_pin = epin.pin.flip
epin.with_pin(new_pin).to_s # => "k^'"
```

### Multiple Transformations

```ruby
epin = Sashite::Epin.parse("K^")

# Transform PIN and derivation
new_pin = epin.pin.with_type(:Q).enhance
transformed = epin.with_pin(new_pin).mark_derived

transformed.to_s # => "+Q^'"
```

### Component Queries

Use the PIN API directly:

```ruby
epin = Sashite::Epin.parse("+P^'")

# PIN queries (name, side, state, terminal)
epin.pin.type                # => :P
epin.pin.side                # => :first
epin.pin.state               # => :enhanced
epin.pin.terminal            # => true
epin.pin.first_player?       # => true
epin.pin.enhanced?           # => true
epin.pin.letter              # => "P"
epin.pin.prefix              # => "+"
epin.pin.suffix              # => "^"

# EPIN queries (style)
epin.derived?                # => true
epin.native?                 # => false

# Compare EPINs
other = Sashite::Epin.parse("+P^")
epin.pin.same_type?(other.pin)   # => true (both P)
epin.pin.same_state?(other.pin)  # => true (both enhanced)
epin.same_derived?(other)        # => false (different derivation)
```

## Five Fundamental Attributes

EPIN exposes all five attributes from the [Sashité Game Protocol](https://sashite.dev/game-protocol/):

| Protocol Attribute | EPIN Access | Example |
|-------------------|-------------|---------|
| **Piece Name** | `epin.pin.type` | `:K` (King), `:R` (Rook) |
| **Piece Side** | `epin.pin.side` | `:first`, `:second` |
| **Piece State** | `epin.pin.state` | `:normal`, `:enhanced`, `:diminished` |
| **Terminal Status** | `epin.pin.terminal` | `true`, `false` |
| **Piece Style** | `epin.derived` | `false` (native), `true` (derived) |

## Format Specification

### Structure

```
<pin>[']
```

Where:
- `<pin>` is any valid PIN token
- `'` is the optional derivation marker

### Grammar (EBNF)

```ebnf
epin ::= pin | pin "'"
pin  ::= ["+" | "-"] letter ["^"]
letter ::= "A" | ... | "Z" | "a" | ... | "z"
```

### Regular Expression

```ruby
/\A[-+]?[A-Za-z]\^?'?\z/
```

### Examples

| EPIN | Side | State | Terminal | Derived | Description |
|------|------|-------|----------|---------|-------------|
| `K` | First | Normal | No | No | Standard native king |
| `K'` | First | Normal | No | Yes | Derived king |
| `K^` | First | Normal | Yes | No | Terminal native king |
| `K^'` | First | Normal | Yes | Yes | Terminal derived king |
| `+R'` | First | Enhanced | No | Yes | Enhanced derived rook |
| `-p` | Second | Diminished | No | No | Diminished native pawn |

## Cross-Style Game Example

In a chess-vs-makruk cross-style match where:
- First side native style = chess
- Second side native style = makruk

```ruby
# First player pieces
chess_king = Sashite::Epin.parse("K^")   # Native Chess king
makruk_pawn = Sashite::Epin.parse("P'")  # Derived Makruk pawn (foreign)

chess_king.native?      # => true (uses own style)
makruk_pawn.derived?    # => true (uses opponent's style)

# Second player pieces
makruk_king = Sashite::Epin.parse("k^")  # Native Makruk king
chess_pawn = Sashite::Epin.parse("p'")   # Derived Chess pawn (foreign)

makruk_king.native?     # => true
chess_pawn.derived?     # => true
```

## API Reference

### Parsing and Validation

```ruby
Sashite::Epin.parse(epin_string)  # => Sashite::Epin | raises ArgumentError
Sashite::Epin.valid?(epin_string) # => boolean
```

### Creation

```ruby
Sashite::Epin.new(pin)                 # Native (default)
Sashite::Epin.new(pin, derived: true)  # Derived
```

### Conversion

```ruby
epin.to_s # => String
```

### Transformations

All transformations return new `Sashite::Epin` instances:

```ruby
# PIN replacement
epin.with_pin(new_pin) # => Sashite::Epin with different PIN

# Derivation
epin.mark_derived            # => Sashite::Epin with derived: true
epin.unmark_derived          # => Sashite::Epin with derived: false
epin.with_derived(boolean)   # => Sashite::Epin with specified derivation
```

### Queries

```ruby
# Derivation
epin.derived?                # => true if derived
epin.native?                 # => true if not derived

# Comparison
epin.same_derived?(other) # => true if same derivation status
```

## Data Structure

```ruby
Sashite::Epin
  #pin     => Sashite::Pin     # Underlying PIN instance
  #derived => true | false     # Derivation status
```

## Comparison with PIN

### What EPIN Adds

```ruby
# PIN: 4 attributes
pin = Sashite::Pin.parse("K^")
pin.type       # Piece Name
pin.side       # Piece Side
pin.state      # Piece State
pin.terminal   # Terminal Status

# EPIN: 5 attributes (PIN + style)
epin = Sashite::Epin.parse("K^'")
epin.pin.type       # Piece Name
epin.pin.side       # Piece Side
epin.pin.state      # Piece State
epin.pin.terminal   # Terminal Status
epin.derived        # Piece Style (5th attribute)
```

### When to Use EPIN vs PIN

**Use PIN when:**
- Single-style games (both players use same style)
- Style information not needed
- Maximum compatibility required

**Use EPIN when:**
- Cross-style games (different styles per player)
- Pieces can change style (promotion to foreign piece)
- Need to track native vs derived pieces

## Design Principles

### 1. Pure Composition

EPIN doesn't reimplement PIN features — it extends PIN minimally:

```ruby
def initialize(pin, derived: false)
  @pin = pin
  @derived = !!derived
  freeze
end
```

### 2. Minimal API

**6 core methods only:**
1. `new` — create from PIN
2. `pin` — get PIN component
3. `derived` / `derived?` — check derivation
4. `to_s` — serialize
5. `with_pin` — replace PIN
6. `with_derived` / `mark_derived` / `unmark_derived` — change derivation

Everything else uses the PIN API directly.

### 3. Component Transparency

Access PIN directly — no wrappers:

```ruby
# Use PIN API directly
epin.pin.type
epin.pin.with_type(:Q)
epin.pin.enhanced?
epin.pin.flip

# No need for wrapper methods like:
# epin.type
# epin.with_type(:Q)
# epin.enhanced?
# epin.flip
```

### 4. Backward Compatibility

Every valid PIN is a valid EPIN (without derivation marker):

```ruby
# All PIN identifiers work as EPIN
%w[K +R -p K^ +R^].each do |token|
  epin = Sashite::Epin.parse(token)
  epin.native?  # => true
  epin.to_s     # => token
end
```

## Related Specifications

- [EPIN Specification v1.0.0](https://sashite.dev/specs/epin/1.0.0/) — Technical specification
- [EPIN Examples](https://sashite.dev/specs/epin/1.0.0/examples/) — Usage examples
- [PIN Specification v1.0.0](https://sashite.dev/specs/pin/1.0.0/) — Base component
- [Sashité Game Protocol](https://sashite.dev/game-protocol/) — Foundation

## License

Available as open source under the [MIT License](https://opensource.org/licenses/MIT).

## About

Maintained by [Sashité](https://sashite.com/) — promoting chess variants and sharing the beauty of board game cultures.
