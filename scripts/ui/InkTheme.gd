extends RefCounted

const INK := Color(0.035, 0.034, 0.032, 0.97)
const INK_SOFT := Color(0.075, 0.071, 0.064, 0.96)
const PAPER := Color(0.91, 0.875, 0.80)
const PAPER_MUTED := Color(0.66, 0.63, 0.57)
const GOLD := Color(0.82, 0.64, 0.28)
const GOLD_DIM := Color(0.38, 0.30, 0.16)
const VERMILION := Color(0.68, 0.23, 0.18)


static func make_theme(font: Font) -> Theme:
	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = 14

	theme.set_color("font_color", "Label", PAPER)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.72))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_color("default_color", "RichTextLabel", PAPER)
	theme.set_color("font_selected_color", "RichTextLabel", INK)
	theme.set_color("selection_color", "RichTextLabel", GOLD)

	theme.set_stylebox("panel", "Panel", panel_style())
	theme.set_stylebox("normal", "Button", button_style())
	theme.set_stylebox("hover", "Button", button_style(true))
	theme.set_stylebox("pressed", "Button", button_style(true, true))
	theme.set_stylebox("focus", "Button", focus_style())
	theme.set_stylebox("disabled", "Button", button_style(false, false, true))
	theme.set_color("font_color", "Button", PAPER)
	theme.set_color("font_hover_color", "Button", Color(1.0, 0.94, 0.80))
	theme.set_color("font_pressed_color", "Button", Color(1.0, 0.88, 0.58))
	theme.set_color("font_disabled_color", "Button", Color(PAPER_MUTED, 0.44))
	theme.set_font_size("font_size", "Button", 14)

	theme.set_stylebox("normal", "LineEdit", inset_style())
	theme.set_stylebox("normal", "TextEdit", inset_style())
	theme.set_stylebox("panel", "TooltipPanel", panel_style(GOLD_DIM))
	theme.set_color("font_color", "TooltipLabel", PAPER)
	theme.set_stylebox("separator", "HSeparator", separator_style())
	return theme


static func panel_style(border: Color = GOLD_DIM) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = INK
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.shadow_color = Color(0, 0, 0, 0.56)
	style.shadow_size = 10
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


static func button_style(hovered := false, pressed := false, disabled := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.095, 0.085, 0.94)
	style.border_color = Color(GOLD_DIM, 0.92)
	if hovered:
		style.bg_color = Color(0.16, 0.14, 0.10, 0.98)
		style.border_color = Color(GOLD, 0.88)
	if pressed:
		style.bg_color = Color(0.22, 0.16, 0.07, 1.0)
	if disabled:
		style.bg_color = Color(0.06, 0.06, 0.055, 0.72)
		style.border_color = Color(PAPER_MUTED, 0.16)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style


static func focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(GOLD, 0.88)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	return style


static func inset_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.018, 0.72)
	style.border_color = Color(PAPER_MUTED, 0.20)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style


static func separator_style() -> StyleBoxLine:
	var style := StyleBoxLine.new()
	style.color = Color(GOLD, 0.30)
	style.thickness = 1
	return style
