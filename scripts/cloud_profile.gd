extends Node
## Account-backed profile bridge. Local SaveStore remains authoritative when offline.

signal status_changed(status: String, detail: String)

var status := "local_only"
var detail := ""
var session: Dictionary = {}
var remote_profile: Dictionary = {}
var _requests: Dictionary = {}

func _ready() -> void:
	if ManusAuth.auth_state_changed.is_connected(_on_auth_state_changed) == false:
		ManusAuth.auth_state_changed.connect(_on_auth_state_changed)
	if ManusAuth.api_completed.is_connected(_on_api_completed) == false:
		ManusAuth.api_completed.connect(_on_api_completed)
	call_deferred("_inspect_session")

func _inspect_session() -> void:
	_on_auth_state_changed(ManusAuth.get_session())

func is_authenticated() -> bool:
	return str(session.get("status", "")) == "authenticated"

func account_name() -> String:
	if not is_authenticated(): return ""
	return str(session.get("user", {}).get("name", ""))

func status_text() -> String:
	match status:
		"syncing": return "Syncing account save…"
		"synced": return "Account save synced"
		"sync_error": return "Account sync paused · local save is safe"
		"offline": return "Preview is offline · local save is active"
		"unavailable": return "Account service unavailable · local save is active"
		"authenticated": return "Signed in · account save ready"
		_: return "Not signed in · local save only"

func progress_text() -> String:
	var profile := SaveStore.cloud_profile()
	return "Stage %d · Funds %d · Best %06d" % [int(profile.highestStage), int(profile.totalCoins), int(profile.bestScore)]

func request_login() -> void:
	if status == "offline":
		detail = "online_preview_requires_checkpoint"
		status_changed.emit(status, detail)
		return
	ManusAuth.login()

func request_logout() -> void:
	ManusAuth.logout()

func sync_now() -> void:
	if not is_authenticated():
		return
	if _requests.values().any(func(value: Variant): return str(value) == "profile" or str(value) == "sync"):
		return
	_set_status("syncing", "pull")
	var request_id := ManusAuth.query("profile")
	_requests[request_id] = "profile"

func _on_auth_state_changed(next_session: Dictionary) -> void:
	session = next_session.duplicate(true)
	var next_status := str(session.get("status", "logged_out"))
	if next_status == "authenticated":
		_set_status("authenticated", "")
		sync_now()
	elif next_status == "offline":
		_set_status("offline", "online_preview_requires_checkpoint")
	elif next_status == "unavailable":
		_set_status("unavailable", "auth_unavailable")
	else:
		_set_status("local_only", "")

func _on_api_completed(request_id: String, ok: bool, value: Variant, error: String) -> void:
	if not _requests.has(request_id): return
	var kind := str(_requests[request_id])
	_requests.erase(request_id)
	if not ok:
		_set_status("sync_error", error)
		return
	if kind == "profile":
		if value is Dictionary:
			remote_profile = value.duplicate(true)
			SaveStore.merge_cloud_profile(remote_profile)
		_set_status("syncing", "push")
		var sync_id := ManusAuth.mutate("sync", {"profile": SaveStore.cloud_profile(), "runs": SaveStore.cloud_runs()})
		_requests[sync_id] = "sync"
		return
	if kind == "sync":
		if value is Dictionary:
			remote_profile = value.duplicate(true)
			SaveStore.merge_cloud_profile(remote_profile)
		_set_status("synced", "")

func _set_status(next_status: String, next_detail: String) -> void:
	status = next_status
	detail = next_detail
	status_changed.emit(status, detail)
