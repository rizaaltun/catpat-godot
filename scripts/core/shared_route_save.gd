extends "res://scripts/core/save_service.gd"
## Isolated preview progress. Main B01–B03 saves and their schema stay unchanged.
const ROUTE_SCHEMA=4
const ROUTE_ID="summit.shared"
const ROUTE_GEOMETRY="shared-v16"
const PARTY_IDS=["rabbit","badger","monkey"]
const FIELDS=["schema_version","route_id","geometry","bank","party_ids","facing","lantern","rope","waymark"]
const LANTERN_STAGES=["unseen","accepted","prepared","lit"]
const ROPE_STAGES=["loose","carried","requested","ready"]
const WAYMARK_STAGES=["loose","carried","placed","ready","seen"]
func fresh() -> Dictionary:
	return {"schema_version":ROUTE_SCHEMA,"route_id":ROUTE_ID,"geometry":ROUTE_GEOMETRY,"bank":0,"party_ids":PARTY_IDS.duplicate(),"facing":1,"lantern":"unseen","rope":"loose","waymark":"loose"}
func valid(data) -> bool:
	if not data is Dictionary or data.size()!=FIELDS.size() or not data.has_all(FIELDS):return false
	if typeof(data.schema_version) not in [TYPE_INT,TYPE_FLOAT]:return false
	if not data.route_id is String or not data.geometry is String:return false
	if data.schema_version!=ROUTE_SCHEMA or data.route_id!=ROUTE_ID or data.geometry!=ROUTE_GEOMETRY:return false
	if typeof(data.bank) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(data.bank)):return false
	if data.bank!=floorf(float(data.bank)) or data.bank<0 or data.bank>2:return false
	if typeof(data.facing) not in [TYPE_INT,TYPE_FLOAT] or absf(float(data.facing))!=1.0:return false
	if not (data.party_ids is Array and data.party_ids==PARTY_IDS and data.lantern is String and data.lantern in LANTERN_STAGES):return false
	if not (data.rope is String and data.rope in ROPE_STAGES and (data.rope=="loose" or data.lantern=="lit")):return false
	return data.waymark is String and data.waymark in WAYMARK_STAGES and (data.waymark=="loose" or data.rope=="ready")
func decode(text: String) -> Dictionary:
	var parser=JSON.new()
	if parser.parse(text)!=OK:return {"ok":false,"reason":"invalid_json"}
	var raw=parser.data
	if not raw is Dictionary or not raw.get("payload") is Dictionary:return {"ok":false,"reason":"invalid_json"}
	if not raw.get("sha256") is String:return {"ok":false,"reason":"invalid_checksum"}
	if raw.get("sha256")!=JSON.stringify(raw.payload).sha256_text():return {"ok":false,"reason":"invalid_checksum"}
	if typeof(raw.payload.get("schema_version")) not in [TYPE_INT,TYPE_FLOAT]:return {"ok":false,"reason":"unsupported_schema"}
	var version_value=float(raw.payload.schema_version)
	if not is_finite(version_value) or version_value!=floorf(version_value):return {"ok":false,"reason":"unsupported_schema"}
	var old_version=int(version_value)
	if old_version not in [1,2,3,ROUTE_SCHEMA]:return {"ok":false,"reason":"unsupported_schema"}
	if old_version==1:
		if raw.payload.size()!=6 or raw.payload.has("lantern"):return {"ok":false,"reason":"invalid_legacy_payload"}
		raw.payload.lantern="unseen"
	if old_version==1 or old_version==2:
		if raw.payload.size()!=7 or raw.payload.has("rope"):return {"ok":false,"reason":"invalid_legacy_payload"}
		raw.payload.rope="loose"
	if old_version in [1,2,3]:
		if raw.payload.size()!=8 or raw.payload.has("waymark"):return {"ok":false,"reason":"invalid_legacy_payload"}
		raw.payload.schema_version=ROUTE_SCHEMA;raw.payload.waymark="loose"
	if not valid(raw.payload):return {"ok":false,"reason":"invalid_payload"}
	return {"ok":true,"data":raw.payload,"migrated":old_version!=ROUTE_SCHEMA}
