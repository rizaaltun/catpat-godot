extends RefCounted
## Main-save contract only; independent route preview retains its own schema.
const FIELDS=["bank","facing","lantern","rope","waymark"]
const LANTERN=["unseen","accepted","prepared","lit"]
const ROPE=["loose","carried","requested","ready"]
const WAYMARK=["loose","carried","placed","ready","seen"]
static func fresh() -> Dictionary:
	return {"bank":0,"facing":1,"lantern":"unseen","rope":"loose","waymark":"loose"}
static func valid(s) -> bool:
	if not s is Dictionary or s.size()!=5 or not s.has_all(FIELDS):return false
	if typeof(s.bank) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(s.bank)) or s.bank!=floorf(float(s.bank)) or s.bank<0 or s.bank>2:return false
	if typeof(s.facing) not in [TYPE_INT,TYPE_FLOAT] or absf(float(s.facing))!=1:return false
	if not (s.lantern is String and s.lantern in LANTERN and s.rope is String and s.rope in ROPE and s.waymark is String and s.waymark in WAYMARK):return false
	return (s.rope=="loose" or s.lantern=="lit") and (s.waymark=="loose" or s.rope=="ready")
