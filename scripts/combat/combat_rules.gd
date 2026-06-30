class_name CombatRules
## The dice of a mouse encounter, kept pure and separate from the combat scene so
## the odds can be unit-tested. Each roll takes a `RandomNumberGenerator` so tests
## can seed it for repeatable results.

const RUN_ESCAPE_CHANCE := 0.95
const SCREAM_FLEE_CHANCE := 0.50
const THROW_HIT_CHANCE := 0.30
const MOUSE_CHARGE_CHANCE := 0.15


static func run_escapes(rng: RandomNumberGenerator) -> bool:
	return rng.randf() < RUN_ESCAPE_CHANCE


static func scream_scares_mouse(rng: RandomNumberGenerator) -> bool:
	return rng.randf() < SCREAM_FLEE_CHANCE


static func throw_hits(rng: RandomNumberGenerator) -> bool:
	return rng.randf() < THROW_HIT_CHANCE


static func mouse_charges(rng: RandomNumberGenerator) -> bool:
	return rng.randf() < MOUSE_CHARGE_CHANCE
