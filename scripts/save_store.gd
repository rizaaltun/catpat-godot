extends RefCounted
const PATH = "user://festival-v2.json"
static func read_save() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not parsed is Dictionary or parsed.get("version",0)!=2:
		return {}
	var result = {"lanterns":[],"wood":[],"flowers":[],"friends":[],"checkpoint":0,"finished":false}
	for key in ["lanterns","wood","flowers","friends"]:
		var limit = 3 if key in ["lanterns","wood","friends"] else 5
		var source = parsed.get(key,[])
		if source is Array:
			for value in source:
				if (value is float or value is int) and value == int(value) and value>=0 and value<limit and not int(value) in result[key]:
					result[key].append(int(value))
	result.checkpoint = clampi(int(parsed.get("checkpoint",0)),0,3) if parsed.get("checkpoint",0) is float or parsed.get("checkpoint",0) is int else 0
	result.finished = parsed.get("finished",false) == true and result.friends.size()==3
	return result
static func write_save(data: Dictionary):
	var file = FileAccess.open(PATH,FileAccess.WRITE)
	if file:
		data["version"]=2
		file.store_string(JSON.stringify(data))
