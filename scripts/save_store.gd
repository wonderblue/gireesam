extends Node
## Local-first bounded records with optional account-backed cloud synchronization.

const SAVE_PATH := "user://save.json"
const SCHEMA_VERSION := 3
const TOP_N := 10
const NAME_LIMIT := 24
const NAME_BYTES := 96
const FONT = preload("res://assets/template/fonts/ui_regular.tres")
var data: Dictionary = _default_data()
var _replay_tutorial := false
var last_save_ok := true
signal save_failed

func _ready() -> void:
	load_save()

func _default_data() -> Dictionary:
	return {"version": SCHEMA_VERSION, "best_score": 0, "player_name": "Calico", "records": [], "tutorial_version": 0, "highest_stage": 0, "total_coins": 0, "reputation": 52}

func load_save() -> void:
	data = _default_data()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or not _number(parsed.get("version")):
		return
	if int(parsed.version) < 1 or int(parsed.version) > SCHEMA_VERSION:
		return
	data.best_score = _safe_int(parsed.get("best_score", 0), 0, 99999999)
	var name_value: Variant = parsed.get("player_name", "Calico")
	if name_value is String and valid_player_name(name_value):
		data.player_name = name_value.strip_edges()
	data.tutorial_version = _safe_int(parsed.get("tutorial_version", 0), 0, 1000)
	data.highest_stage = _safe_int(parsed.get("highest_stage", 0), 0, 99)
	data.total_coins = _safe_int(parsed.get("total_coins", 0), 0, 100000000)
	data.reputation = _safe_int(parsed.get("reputation", 52), -100, 100)
	var records: Variant = parsed.get("records", [])
	if records is Array:
		var seen: Dictionary = {}
		for entry: Variant in records.slice(0, 100):
			var record := _sanitize_record(entry)
			if record.is_empty() or seen.has(record.run_id):
				continue
			seen[record.run_id] = true
			data.records.append(record)
	_sort_records()

func save() -> bool:
	var pending := SAVE_PATH + ".tmp"
	var file := FileAccess.open(pending, FileAccess.WRITE)
	if file == null:
		last_save_ok = false
		save_failed.emit()
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	last_save_ok = DirAccess.rename_absolute(pending, SAVE_PATH) == OK
	if not last_save_ok: save_failed.emit()
	return last_save_ok

func valid_player_name(value: String) -> bool:
	var clean := value.strip_edges()
	if clean.is_empty() or clean.length() > NAME_LIMIT or clean.to_utf8_buffer().size() > NAME_BYTES:
		return false
	for character in clean:
		var point := character.unicode_at(0)
		if point < 32 or point in [60, 62, 38, 127] or (point >= 128 and point <= 159) or point in [0x200b, 0x200c, 0x200d, 0x200e, 0x200f, 0x202a, 0x202b, 0x202c, 0x202d, 0x202e, 0x2066, 0x2067, 0x2068, 0x2069, 0xfeff] or not FONT.has_char(point):
			return false
	return true

func set_player_name(value: String) -> bool:
	if not valid_player_name(value):
		return false
	data.player_name = value.strip_edges()
	return save()

func player_name() -> String:
	return str(data.player_name)

func leaderboard() -> Array:
	return data.records.duplicate(true)

func record_run(result: Dictionary) -> bool:
	var source := result.duplicate(true)
	source.player_name = player_name()
	var record := _sanitize_record(source)
	if record.is_empty():
		return false
	for existing: Dictionary in data.records:
		if existing.run_id == record.run_id:
			return false
	var is_best := int(record.score) > best_score()
	data.best_score = maxi(best_score(), int(record.score))
	data.records.append(record)
	_sort_records()
	save()
	return is_best

func note_reform_fund() -> void:
	data.total_coins = _safe_int(int(data.get("total_coins", 0)) + 1, 0, 100000000)

func update_campaign_progress(stage_number: int, current_reputation: int) -> void:
	data.highest_stage = maxi(int(data.get("highest_stage", 0)), clampi(stage_number, 0, 99))
	data.reputation = clampi(current_reputation, -100, 100)

func cloud_profile() -> Dictionary:
	var best_duration_ms: Variant = null
	for record: Dictionary in data.records:
		if record.outcome == "victory":
			var candidate := maxi(0, roundi(float(record.duration) * 1000.0))
			if best_duration_ms == null or candidate < int(best_duration_ms): best_duration_ms = candidate
	return {
		"displayName": player_name(),
		"highestStage": clampi(int(data.get("highest_stage", 0)), 0, 99),
		"totalCoins": clampi(int(data.get("total_coins", 0)), 0, 100000000),
		"reputation": clampi(int(data.get("reputation", 52)), -100, 100),
		"bestScore": best_score(),
		"bestDurationMs": best_duration_ms,
		"tutorialVersion": clampi(int(data.get("tutorial_version", 0)), 0, 1000),
	}

func cloud_runs(limit: int = 10) -> Array:
	var output: Array = []
	for record: Dictionary in data.records.slice(0, limit):
		output.append({
			"runId": record.run_id,
			"stage": record.stage,
			"outcome": record.outcome,
			"score": clampi(int(record.score), 0, 100000000),
			"durationMs": clampi(roundi(float(record.duration) * 1000.0), 0, 864000000),
			"recordedAt": clampi(int(record.timestamp), 0, 2147483647),
			"eligible": bool(record.eligible),
			"configuration": str(record.configuration).to_lower(),
		})
	return output

func merge_cloud_profile(remote: Dictionary) -> void:
	data.best_score = maxi(best_score(), _safe_int(remote.get("bestScore", 0), 0, 99999999))
	data.highest_stage = maxi(int(data.get("highest_stage", 0)), _safe_int(remote.get("highestStage", 0), 0, 99))
	data.total_coins = maxi(int(data.get("total_coins", 0)), _safe_int(remote.get("totalCoins", 0), 0, 100000000))
	data.tutorial_version = maxi(int(data.get("tutorial_version", 0)), _safe_int(remote.get("tutorialVersion", 0), 0, 1000))
	data.reputation = clampi(_safe_int(remote.get("reputation", data.get("reputation", 52)), -100, 100), -100, 100)
	var remote_name := str(remote.get("displayName", "")).strip_edges()
	if valid_player_name(remote_name) and player_name() == "Calico": data.player_name = remote_name
	var remote_runs: Variant = remote.get("runs", [])
	if remote_runs is Array:
		var seen: Dictionary = {}
		for existing: Dictionary in data.records: seen[existing.run_id] = true
		for entry: Variant in remote_runs:
			if not entry is Dictionary: continue
			var candidate: Dictionary = (entry as Dictionary).duplicate(true)
			candidate["player_name"] = player_name()
			candidate["duration"] = float(candidate.get("durationMs", 0)) / 1000.0
			candidate["timestamp"] = int(candidate.get("recordedAt", 0))
			candidate["run_id"] = str(candidate.get("runId", ""))
			var sanitized := _sanitize_record(candidate)
			if not sanitized.is_empty() and not seen.has(sanitized.run_id):
				seen[sanitized.run_id] = true
				data.records.append(sanitized)
	_sort_records()
	save()

func _sort_records() -> void:
	data.records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.score != b.score: return a.score > b.score
		if a.duration != b.duration: return a.duration < b.duration
		if a.timestamp != b.timestamp: return a.timestamp < b.timestamp
		return a.run_id < b.run_id)
	if data.records.size() > TOP_N:
		data.records.resize(TOP_N)

func _sanitize_record(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {}
	for key in ["run_id", "stage", "outcome", "configuration", "player_name"]:
		if not value.get(key) is String or str(value[key]).is_empty():
			return {}
	if value.run_id.length() > 100 or value.stage.length() > 80 or value.configuration.length() > 128 or not valid_player_name(value.player_name):
		return {}
	if value.outcome not in ["victory", "defeat"] or not value.get("eligible") is bool:
		return {}
	for key in ["score", "duration", "timestamp"]:
		if not _number(value.get(key)) or float(value[key]) < 0.0:
			return {}
	return {"run_id": value.run_id, "player_name": value.player_name.strip_edges(), "score": _safe_int(value.score, 0, 99999999), "stage": value.stage, "outcome": value.outcome, "duration": clampf(float(value.duration), 0.0, 86400.0), "timestamp": _safe_int(value.timestamp, 0, 9999999999), "eligible": value.eligible, "configuration": value.configuration}

func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func _safe_int(value: Variant, minimum: int, maximum: int) -> int:
	return clampi(int(value), minimum, maximum) if _number(value) else minimum

func record_score(score: int) -> bool:
	# Retained for existing callers; full runs use record_run.
	var is_best := score > best_score()
	if is_best:
		data.best_score = clampi(score, 0, 99999999)
		save()
	return is_best

func best_score() -> int:
	return int(data.best_score)

func tutorial_completed(version: int = 1) -> bool:
	return int(data.tutorial_version) >= version

func complete_tutorial(version: int = 1) -> void:
	data.tutorial_version = version
	save()

func request_tutorial_replay() -> void:
	_replay_tutorial = true

func consume_tutorial_replay() -> bool:
	var requested := _replay_tutorial
	_replay_tutorial = false
	return requested
