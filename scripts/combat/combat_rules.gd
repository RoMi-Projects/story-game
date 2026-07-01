class_name CombatRules
## The dice of the creature encounters (the mouse and the cat), kept pure and
## separate from the combat scenes so the odds can be unit-tested. Each roll takes
## a `RandomNumberGenerator` so tests can seed it for repeatable results.

const RUN_ESCAPE_CHANCE := 0.95
const SCREAM_FLEE_CHANCE := 0.50
const THROW_HIT_CHANCE := 0.30
const MOUSE_CHARGE_CHANCE := 0.15

const PET_SUCCESS_CHANCE := 0.20
const CALL_APPROACH_CHANCE := 0.50
const CAT_BREAKS_BAG_CHANCE := 0.50


static func run_escapes(rng: RandomNumberGenerator) -> bool:
	return rng.randf() < RUN_ESCAPE_CHANCE


static func scream_scares_mouse(rng: RandomNumberGenerator) -> bool:
	return rng.randf() < SCREAM_FLEE_CHANCE


static func throw_hits(rng: RandomNumberGenerator) -> bool:
	return rng.randf() < THROW_HIT_CHANCE


static func mouse_charges(rng: RandomNumberGenerator) -> bool:
	return rng.randf() < MOUSE_CHARGE_CHANCE


static func cat_pet_succeeds(rng: RandomNumberGenerator) -> bool:
	return rng.randf() < PET_SUCCESS_CHANCE


static func cat_approaches(rng: RandomNumberGenerator) -> bool:
	return rng.randf() < CALL_APPROACH_CHANCE


static func cat_breaks_bag(rng: RandomNumberGenerator) -> bool:
	return rng.randf() < CAT_BREAKS_BAG_CHANCE
