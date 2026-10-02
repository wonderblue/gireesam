extends "res://scripts/menu_modal.gd"

var _status: Label
var _progress: Label
var _account: Label
var _login: Button
var _sync: Button
var _logout: Button

func _ready() -> void:
	super._ready()
	heading("account.title")
	var intro := STYLE.label(I18n.t("account.intro"), 15)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.add_theme_color_override("font_color", STYLE.MUTED)
	content.add_child(intro)
	var card := PanelContainer.new()
	var card_style := STYLE.plate(Color("#f7e3bd"), 18)
	card_style.set_corner_radius_all(16)
	card_style.set_border_width_all(0)
	card.add_theme_stylebox_override("panel", card_style)
	content.add_child(card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	card.add_child(stack)
	_account = STYLE.label("", 22)
	_account.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_account.add_theme_font_override("font", STYLE.BOLD)
	stack.add_child(_account)
	_status = STYLE.label("", 15)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_color_override("font_color", STYLE.MUTED)
	stack.add_child(_status)
	_progress = STYLE.label("", 18)
	_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress.add_theme_color_override("font_color", STYLE.COCOA)
	stack.add_child(_progress)
	_login = STYLE.button(I18n.t("account.login"), true)
	_login.pressed.connect(_login_pressed)
	_sync = STYLE.button(I18n.t("account.sync"))
	_sync.pressed.connect(CloudProfile.sync_now)
	_logout = STYLE.button(I18n.t("account.logout"))
	_logout.pressed.connect(CloudProfile.request_logout)
	content.add_child(_login)
	content.add_child(_sync)
	content.add_child(_logout)
	add_close_button()
	CloudProfile.status_changed.connect(_refresh)
	_refresh(CloudProfile.status, CloudProfile.detail)

func _login_pressed() -> void:
	CloudProfile.request_login()
	_refresh(CloudProfile.status, CloudProfile.detail)

func _refresh(_next_status: String = "", _detail: String = "") -> void:
	if not is_instance_valid(_status): return
	_status.text = CloudProfile.status_text()
	_progress.text = CloudProfile.progress_text()
	_account.text = CloudProfile.account_name() if CloudProfile.is_authenticated() else I18n.t("account.guest")
	_login.visible = not CloudProfile.is_authenticated()
	_sync.visible = CloudProfile.is_authenticated()
	_logout.visible = CloudProfile.is_authenticated()
	_login.disabled = CloudProfile.status in ["offline", "syncing"]
	_sync.disabled = CloudProfile.status == "syncing"
	_layout()
