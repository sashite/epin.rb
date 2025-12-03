# Epin.rb

[![Version](https://img.shields.io/github/v/tag/sashite/epin.rb?label=Version&logo=github)](https://github.com/sashite/epin.rb/tags)
[![Yard documentation](https://img.shields.io/badge/Yard-documentation-blue.svg?logo=github)](https://rubydoc.info/github/sashite/epin.rb/main)
![Ruby](https://github.com/sashite/epin.rb/actions/workflows/main.yml/badge.svg?branch=main)
[![License](https://img.shields.io/github/license/sashite/epin.rb?label=License&logo=github)](https://github.com/sashite/epin.rb/raw/main/LICENSE.md)

> **EPIN** (Extended Piece Identifier Notation) implementation for the Ruby language.

## What is EPIN?

EPIN (Extended Piece Identifier Notation) extends [PIN](https://sashite.dev/specs/pin/1.0.0/) by adding a **derivation marker** to track piece style in cross-style games.

**EPIN is simply: PIN + optional style derivation marker (`'`)**

This gem implements the [EPIN Specification v1.0.0](https://sashite.dev/specs/epin/1.0.0/) with a minimal compositional API.

## Core Concept

```ruby
# EPIN is just PIN + derived flag
pin = Sashite::Pin.parse("K^")
epin = Sashite::Epin.new(pin, derived: false)

epin.to_s      # => "K^" (native)
epin.pin       # => PIN::Identifier instance
epin.derived?  # => false

# Mark as derived
derived_epin = epin.mark_derived
derived_epin.to_s # => "K^'" (derived from opposite side's style)
```

**That's it.** All piece attributes come from the PIN component.

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
gem "sashite-pin" # Piece Identifier Notation
```

## Quick Start

```ruby
require "sashite/epin"

# Parse an EPIN string
epin = Sashite::Epin.parse("K^'")
epin.to_s # => "K^'"

# Access five fundamental attributes through PIN component + derived flag
epin.pin.type          # => :K (Piece Name)
epin.pin.side          # => :first (Piece Side)
epin.pin.state         # => :normal (Piece State)
epin.pin.terminal?     # => true (Terminal Status)
epin.derived?          # => true (Piece Style: derived vs native)

# PIN component is a full PIN::Identifier
epin.pin.enhanced?     # => false
epin.pin.letter        # => "K"
```

## Basic Usage

### Creating Identifiers

```ruby
# Parse from string
epin = Sashite::Epin.parse("K^")      # Native
epin = Sashite::Epin.parse("K^'")     # Derived

# Create from PIN component
pin = Sashite::Pin.parse("K^")
epin = Sashite::Epin.new(pin, derived: false)  # Native
epin = Sashite::Epin.new(pin, derived: true)   # Derived

# Validate
Sashite::Epin.valid?("K^")     # => true
Sashite::Epin.valid?("K^'")    # => true
Sashite::Epin.valid?("K^''")   # => false (multiple markers)
```

### Accessing Components

```ruby
epin = Sashite::Epin.parse("+R^'")

# Get PIN component
epin.pin                       # => #<Pin::Identifier type=:R state=:enhanced terminal=true>
epin.pin.to_s                  # => "+R^"

# Check derivation
epin.derived? # => true

# Serialize
epin.to_s # => "+R^'"
```

### Five Fundamental Attributes

All attributes accessible via PIN component + derived flag:

```ruby
epin = Sashite::Epin.parse("+R^'")

# From PIN component (4 attributes)
epin.pin.type                  # => :R (Piece Name)
epin.pin.side                  # => :first (Piece Side)
epin.pin.state                 # => :enhanced (Piece State)
epin.pin.terminal?             # => true (Terminal Status)

# From EPIN (5th attribute)
epin.derived? # => true (Piece Style: native vs derived)
```

## Transformations

All transformations return new immutable instances:

### Change Derivation Status

```ruby
epin = Sashite::Epin.parse("K^")

# Mark as derived
derived = epin.mark_derived
derived.to_s # => "K^'"

# Mark as native
native = derived.unmark_native
native.to_s # => "K^"

# Toggle
toggled = epin.with_derived(!epin.derived?)
toggled.to_s # => "K^'"
```

### Transform via PIN Component

```ruby
epin = Sashite::Epin.parse("K^'")

# Replace PIN component
new_pin = epin.pin.with_type(:Q)
epin.with_pin(new_pin).to_s # => "Q^'"

# Change type
epin.with_pin(epin.pin.with_type(:Q)).to_s # => "Q^'"

# Change state
epin.with_pin(epin.pin.with_state(:enhanced)).to_s # => "+K^'"

# Remove terminal marker
epin.with_pin(epin.pin.with_terminal(false)).to_s # => "K'"

# Change side
epin.with_pin(epin.pin.flip).to_s # => "k^'"
```

### Multiple Transformations

```ruby
epin = Sashite::Epin.parse("K^")

# Transform PIN and derivation
transformed = epin
              .with_pin(epin.pin.with_type(:Q).with_state(:enhanced))
              .mark_derived

transformed.to_s # => "+Q^'"
```

## Component Queries

Use the PIN component API directly:

```ruby
epin = Sashite::Epin.parse("+P^'")

# PIN queries (name, side, state, terminal)
epin.pin.type                  # => :P
epin.pin.side                  # => :first
epin.pin.state                 # => :enhanced
epin.pin.terminal?             # => true
epin.pin.first_player?         # => true
epin.pin.enhanced?             # => true
epin.pin.letter                # => "P"
epin.pin.prefix                # => "+"
epin.pin.suffix                # => "^"

# EPIN queries (style)
epin.derived?                  # => true
epin.native?                   # => false

# Compare EPINs
other = Sashite::Epin.parse("+P^")
epin.pin.same_type?(other.pin)     # => true (both P)
epin.pin.same_state?(other.pin)    # => true (both enhanced)
epin.same_derivation?(other)       # => false (different derivation)
```

## API Reference

### Main Module

```ruby
# Parse EPIN string
Sashite::Epin.parse(epin_string) # => Epin::Identifier

# Create from PIN component
Sashite::Epin.new(pin, derived: false) # => Epin::Identifier

# Validate string
Sashite::Epin.valid?(epin_string) # => Boolean
```

### Identifier Class

#### Core Methods (6 total)

```ruby
# Creation
Sashite::Epin.new(pin, derived: false) # Create from PIN + derivation flag

# Component access
epin.pin                        # => PIN::Identifier
epin.derived?                   # => Boolean

# Serialization
epin.to_s # => "K^'" or "K^"

# PIN replacement
epin.with_pin(new_pin) # New EPIN with different PIN

# Derivation transformation
epin.mark_derived               # Mark as derived (add ')
epin.unmark_native              # Mark as native (remove ')
epin.with_derived(boolean)      # Set derivation explicitly
```

#### Convenience Queries

```ruby
epin.native?                    # !derived?
epin.same_derivation?(other)    # Compare derivation status
```

#### Equality

```ruby
epin1 == epin2 # True if both PIN and derived flag equal
```

**That's the entire API.** Everything else uses the PIN component API directly.

## Format Specification

### Structure
```
<pin>[']
```

Where:
- `<pin>` is any valid PIN token
- `'` is the optional derivation marker

### Grammar (BNF)
```bnf
<epin> ::= <pin> | <pin> "'"

<pin> ::= ["+" | "-"] <letter> ["^"]
<letter> ::= "A" | ... | "Z" | "a" | ... | "z"
```

### Regular Expression
```ruby
/\A[-+]?[A-Za-z]\^?'?\z/
```

## Examples

### Basic Identifiers

```ruby
# Native pieces (no derivation marker)
native_king = Sashite::Epin.parse("K^")
native_king.pin.type          # => :K
native_king.derived?          # => false

# Derived pieces (with derivation marker)
derived_king = Sashite::Epin.parse("K^'")
derived_king.pin.type         # => :K
derived_king.derived?         # => true

# Enhanced pieces
enhanced_rook = Sashite::Epin.parse("+R'")
enhanced_rook.pin.enhanced?   # => true
enhanced_rook.derived?        # => true

# Diminished pieces
diminished_pawn = Sashite::Epin.parse("-p")
diminished_pawn.pin.diminished?  # => true
diminished_pawn.native?          # => true
```

### Cross-Style Scenarios

Assume first player uses Chess style, second player uses Makruk style:

```ruby
# First player pieces
chess_king = Sashite::Epin.parse("K^")      # Native Chess king
makruk_pawn = Sashite::Epin.parse("P'")     # Derived Makruk pawn (foreign)

chess_king.native?            # => true (uses own style)
makruk_pawn.derived?          # => true (uses opponent's style)

# Second player pieces
makruk_king = Sashite::Epin.parse("k^")     # Native Makruk king
chess_pawn = Sashite::Epin.parse("p'")      # Derived Chess pawn (foreign)

makruk_king.native?           # => true
chess_pawn.derived?           # => true
```

### Component Manipulation

```ruby
# Start with native king
epin = Sashite::Epin.parse("K^")

# Convert to derived
derived = epin.mark_derived
derived.to_s # => "K^'"

# Change to queen (keep derivation)
queen = derived.with_pin(derived.pin.with_type(:Q))
queen.to_s # => "Q^'"

# Enhance (keep derivation)
enhanced = derived.with_pin(derived.pin.with_state(:enhanced))
enhanced.to_s # => "+K^'"

# Change side (keep derivation)
opponent = derived.with_pin(derived.pin.flip)
opponent.to_s # => "k^'"

# Back to native
native = derived.unmark_native
native.to_s # => "K^"
```

### Working with PIN Component

```ruby
epin = Sashite::Epin.parse("+R^'")

# Extract PIN component
pin = epin.pin # => "+R^"

# Transform PIN
new_pin = pin.with_type(:B).with_state(:normal) # => "B^"

# Create new EPIN with transformed PIN
new_epin = epin.with_pin(new_pin)
new_epin.to_s # => "B^'"

# Multiple PIN transformations
complex_pin = pin
              .with_type(:Q)
              .with_state(:diminished)
              .with_terminal(false)
              .flip

epin.with_pin(complex_pin).to_s # => "-q'"
```

### Immutability

```ruby
original = Sashite::Epin.parse("K^")

# All transformations return new instances
derived = original.mark_derived
changed_pin = original.with_pin(original.pin.with_type(:Q))

# Original unchanged
original.to_s                 # => "K^"
derived.to_s                  # => "K^'"
changed_pin.to_s              # => "Q^"

# Components are immutable
pin = original.pin
pin.frozen?                   # => true
original.frozen?              # => true
```

## Attribute Mapping

EPIN exposes all five fundamental attributes from the Sashité Game Protocol:

| Protocol Attribute | EPIN Access | Example |
|-------------------|-------------|---------|
| **Piece Name** | `epin.pin.type` | `:K` (King), `:R` (Rook) |
| **Piece Side** | `epin.pin.side` | `:first`, `:second` |
| **Piece State** | `epin.pin.state` | `:normal`, `:enhanced`, `:diminished` |
| **Terminal Status** | `epin.pin.terminal?` | `true`, `false` |
| **Piece Style** | `epin.derived?` | `false` (native), `true` (derived) |

## Design Principles

### 1. Pure Composition

EPIN doesn't reimplement PIN features — it extends PIN minimally:

```ruby
# EPIN is just PIN + derived flag
class Identifier
  def initialize(pin, derived: false)
    @pin = pin
    @derived = !!derived
  end
end
```

### 2. Absolute Minimal API

**6 core methods only:**
1. `new(pin, derived: false)` — create from PIN
2. `pin` — get PIN component
3. `derived?` — check derivation
4. `to_s` — serialize
5. `with_pin(new_pin)` — replace PIN
6. `with_derived(boolean)` — change derivation

Everything else uses the PIN component API directly.

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
# epin.with_type
# epin.enhanced?
# epin.flip
```

### 4. Backward Compatibility

Every valid PIN is a valid EPIN (without derivation marker):

```ruby
# All PIN identifiers work as EPIN
pin_tokens = ["K", "+R", "-p", "K^", "+R^"]
pin_tokens.each do |token|
  epin = Sashite::Epin.parse(token)
  epin.native?                 # => true
  epin.to_s == token           # => true
end
```

### 5. Immutability

All instances frozen. Transformations return new instances:

```ruby
epin1 = Sashite::Epin.parse("K^")
epin2 = epin1.mark_derived
epin1.frozen?                 # => true
epin2.frozen?                 # => true
epin1.equal?(epin2)           # => false
```

## Semantics

### Native vs Derived

In cross-style games:
- **Native piece**: Uses its own side's style (no `'` marker)
- **Derived piece**: Uses opponent's style (`'` marker present)

```ruby
# Chess vs Makruk match
# First player = Chess, Second player = Makruk

"K"   # First player king in Chess style (native)
"K'"  # First player king in Makruk style (derived from opponent)
"k"   # Second player king in Makruk style (native)
"k'"  # Second player king in Chess style (derived from opponent)
```

### Style Derivation Logic

```ruby
# Assume: first=Chess, second=Makruk

epin = Sashite::Epin.parse("P")
# Piece Side: first
# Style: Chess (first's native) → Native piece

epin = Sashite::Epin.parse("P'")
# Piece Side: first
# Style: Makruk (second's native) → Derived piece

epin = Sashite::Epin.parse("p")
# Piece Side: second
# Style: Makruk (second's native) → Native piece

epin = Sashite::Epin.parse("p'")
# Piece Side: second
# Style: Chess (first's native) → Derived piece
```

## Error Handling

```ruby
# Invalid EPIN string
begin
  Sashite::Epin.parse("invalid")
rescue ArgumentError => e
  e.message # => "Invalid EPIN string: invalid"
end

# Multiple derivation markers
begin
  Sashite::Epin.parse("K''")
rescue ArgumentError => e
  # Invalid format
end

# PIN validation errors delegate
begin
  Sashite::Epin.parse("KK'")
rescue ArgumentError => e
  # PIN validation error
end
```

## Performance Considerations

### Efficient Composition

```ruby
# PIN component created once
pin = Sashite::Pin.parse("K^")
epin = Sashite::Epin.new(pin, derived: true)

# Accessing components is O(1)
epin.pin         # => direct reference
epin.derived?    # => direct boolean check

# No overhead from method delegation
epin.pin.type # => direct method call on PIN component
```

### Transformation Patterns

```ruby
epin = Sashite::Epin.parse("K^'")

# Pattern 1: Change derivation only
epin.unmark_native

# Pattern 2: Change PIN only
epin.with_pin(epin.pin.with_type(:Q))

# Pattern 3: Change both
new_pin = epin.pin.with_type(:Q)
epin.with_pin(new_pin).unmark_native

# Pattern 4: Complex PIN transformation
new_pin = epin.pin
              .with_type(:Q)
              .with_state(:enhanced)
              .flip
epin.with_pin(new_pin).mark_derived
```

## Comparison with PIN

### What EPIN Adds

```ruby
# PIN: 4 attributes
pin = Sashite::Pin.parse("K^")
pin.type          # Piece Name
pin.side          # Piece Side
pin.state         # Piece State
pin.terminal?     # Terminal Status

# EPIN: 5 attributes (PIN + style)
epin = Sashite::Epin.parse("K^'")
epin.pin.type     # Piece Name
epin.pin.side     # Piece Side
epin.pin.state    # Piece State
epin.pin.terminal? # Terminal Status
epin.derived? # Piece Style (5th attribute)
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

## Design Properties

- **Rule-agnostic**: Independent of game mechanics
- **Pure composition**: Extends PIN minimally
- **Minimal API**: Only 6 core methods
- **Component transparency**: Direct PIN access
- **Backward compatible**: All PIN tokens valid
- **Immutable**: Frozen instances
- **Type-safe**: Full PIN type preservation
- **Style-aware**: Tracks native vs derived
- **Compact**: Single character overhead for derivation

## Related Specifications

- [EPIN Specification v1.0.0](https://sashite.dev/specs/epin/1.0.0/) - Technical specification
- [EPIN Examples](https://sashite.dev/specs/epin/1.0.0/examples/) - Usage examples
- [PIN Specification v1.0.0](https://sashite.dev/specs/pin/1.0.0/) - Base component
- [Sashité Game Protocol](https://sashite.dev/game-protocol/) - Foundation

## License

Available as open source under the [MIT License](https://opensource.org/licenses/MIT).

## About

Maintained by [Sashité](https://sashite.com/) — promoting chess variants and sharing the beauty of board game cultures.
