# Guild Master: Chronicles of the Realm

Прототип на **Godot 4 + GDScript** (вертикальный срез).

## Требования

- Godot **4.3+** (рекомендуется 4.7.x из Flathub: `org.godotengine.Godot`)
- Linux / Windows / Steam Deck

### Установка Godot (Steam Deck / Arch)

```bash
flatpak install -y flathub org.godotengine.Godot
flatpak run org.godotengine.Godot
```

Или скачайте бинарник с https://godotengine.org/download

## Запуск

1. Откройте папку `guild_master/` в Godot.
2. **F5** — стартует **главное меню**:
   - Продолжить (слоты сохранений)
   - Новая игра → создание названия гильдии + генерация/пересоздание ГМ
   - Настройки (подсказки, громкость, полный экран)
   - Выход

Из терминала (Flatpak):

```bash
cd "guild_master"
flatpak run org.godotengine.Godot --path . 
```

## Smoke test (headless):
##   flatpak run org.godotengine.Godot --path . --headless -s res://scripts/systems/smoke_test.gd

## Что есть в прототипе (v0.3)

- UI по `UI/Guild_Master_UI_Visual_Concept.md` (копия в `guild_master/ui/`)
- App Shell: сайдбар 240px + топбар + «Закончить день» (зелёный/жёлтый)
- Палитра менеджера + цвета рангов E–SSS
- Карточки героев, status badges
- Заглушки: почта, турниры, карта, финансы, журнал

## Данные

| Файл | Назначение |
|------|------------|
| `data/balance.json` | Константы баланса |
| `data/classes.json` | Воин / Лучник / Маг / Послушник |
| `data/quest_templates.json` | Шаблоны квестов |
| `data/names.json` | Имена героев |

## Документы дизайна

Лежат в корне репозитория: `Guild_Master_GDD.md`, `class.md`, `Quest_Types.md` и др.

## Вне среза (позже)

Битва Гильдий, карта Аркадии, крафт, данжи, полный class tree, ранги S–SSS.
