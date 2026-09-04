# Go for a Loop

2D pixel-art Metroidvania built in Godot 4 (GDScript).

## الفكرة
لاعب/Programmer بيتسبب في Infinite Loop برمجي ويلاقي نفسه جوه جهازه.
نظام التشغيل بيبقى العالم، وأيقونات سطح المكتب بتبقى مناطق قابلة للاستكشاف.
المفاهيم البرمجية (Loop, Break, Continue, Recursion) بتتحول لـ gameplay mechanics حقيقية.

## Tech Stack
- Godot 4.7 (Compatibility renderer)
- GDScript
- Internal resolution: 320x180

## الفريق
فريق من شخصين، الاثنين Programmers. تقسيم العمل بأسلوب Feature Ownership:

- **Person A:** Player, Movement, Combat, Abilities, Game Feel
- **Person B:** World, Levels, Enemy systems, Boss systems, Progression, Scene transitions
- **مشترك:** Game Design, Core Mechanics, Level Design decisions, Art direction, Sound, Playtesting, Final integration

## Git Workflow
- `main` — مستقر دايمًا
- `develop` — تكامل الفيتشرز
- `feature/*` — فيتشر لكل branch (مثال: `feature/player-dash`)

## Folder Ownership (لتقليل merge conflicts)
- `scripts/player/`, `scripts/abilities/`, `scripts/combat/` → Person A
- `scripts/enemies/`, `scripts/world/`, `scripts/bosses/` → Person B
- `scripts/core/`, `scripts/systems/` → مشترك
