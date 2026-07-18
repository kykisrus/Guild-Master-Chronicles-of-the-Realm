extends ConfirmationDialog
## Reusable Tiny confirmation / info dialog.


func _ready() -> void:
	theme = TinyThemeFactory.build()


func setup(title_text: String, body_text: String, ok_text: String = "", cancel_text: String = "") -> void:
	title = title_text
	dialog_text = body_text
	ok_button_text = ok_text if not ok_text.is_empty() else tr("menu.ok")
	var cancel := get_cancel_button()
	if cancel_text.is_empty():
		cancel.hide()
	else:
		cancel.show()
		cancel.text = cancel_text


func setup_confirm_delete(slot: int) -> void:
	setup(
		tr("save.delete_title") % slot,
		tr("save.delete_warning"),
		tr("menu.delete"),
		tr("menu.cancel")
	)
