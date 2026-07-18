extends Node

signal day_ended(day: int)

const DAYS_PER_WEEK := 5
const DAYS_PER_SEASON := 90
const DAYS_PER_YEAR := 360

var day: int = 1 ## day of year 1..360
var year: int = 1


func reset() -> void:
	day = 1
	year = 1


func season_index() -> int:
	return int((day - 1) / DAYS_PER_SEASON) % 4


func season_name() -> String:
	return ["Весна", "Лето", "Осень", "Зима"][season_index()]


func week_day() -> int:
	return ((day - 1) % DAYS_PER_WEEK) + 1


func is_payday() -> bool:
	return week_day() == DAYS_PER_WEEK


func display_date() -> String:
	return "Год %d, %s, день %d" % [year, season_name(), day]


func end_day() -> void:
	if GameState.is_game_over:
		return

	GameState.process_missions_day()
	if GameState.is_game_over:
		emit_signal("day_ended", day)
		return
	GameState.process_autonomous_quest_choices()

	## Hospital recovery
	for h in GameState.heroes:
		if h is HeroData and h.status == HeroData.Status.HOSPITAL:
			h.hospital_days -= 1
			if h.hospital_days <= 0:
				h.status = HeroData.Status.AVAILABLE
				h.hospital_days = 0
				GameState.add_notification("%s выписан из госпиталя." % h.display_name())

	## Food upkeep
	var mouths := 1
	for h in GameState.heroes:
		if h is HeroData and h.status != HeroData.Status.DEAD:
			mouths += 1
	GameState.food = maxi(0, GameState.food - maxi(1, mouths / 3))
	if GameState.food <= 0:
		GameState.add_notification("Запасы продовольствия на исходе.")

	if is_payday():
		_pay_staff()

	## Advance calendar
	day += 1
	if day > DAYS_PER_YEAR:
		day = 1
		year += 1
		GameState.refresh_quest_board()
		GameState.refresh_tavern()
		GameState.add_notification("Наступил новый год %d." % year)
	elif day % 7 == 1:
		## Soft refresh every ~week of year (day 1,8,...) — use every 10 days
		pass
	if day % 10 == 0:
		GameState.refresh_quest_board()
	if day % 15 == 0:
		GameState.refresh_tavern()
		GameState.refresh_staff_candidates()

	GameState.emit_signal("state_changed")
	emit_signal("day_ended", day)


func _pay_staff() -> void:
	var wage := 0
	for member in GameState.staff_members:
		if typeof(member) == TYPE_DICTIONARY:
			wage += int(member.get("wage", 10))
	if wage <= 0:
		return
	if GameState.gold >= wage:
		GameState.gold -= wage
		GameState.staff_working = true
		if GameState.debt > 0:
			var pay_debt: int = mini(GameState.debt, GameState.gold / 2)
			GameState.gold -= pay_debt
			GameState.debt -= pay_debt
		GameState.add_notification("Выплачена зарплата персоналу: %d золота." % wage)
	else:
		GameState.debt += wage
		GameState.staff_working = false
		GameState.add_notification("Зарплата не выплачена. Долг: %d. Персонал не работает." % GameState.debt)


func to_dict() -> Dictionary:
	return {"day": day, "year": year}


func load_from_dict(d: Dictionary) -> void:
	day = int(d.get("day", 1))
	year = int(d.get("year", 1))
