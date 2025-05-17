📋 Waveborn TD – TaskBoard (Stand: 2025-05-17)
🧱 1. Projektstruktur & Rojo Setup
Element	Status	Beschreibung
default.project.json	✅	Mit $className: "Script" korrekt konfiguriert
Rojo src/-Struktur	✅	Modules, GuiScripts, Server sauber getrennt
.lua UTF-8 Format	✅	Alle Dateien UTF-8 ohne BOM
ModuleScript Struktur	✅	Einheitlich unter ReplicatedStorage/Modules
GUI-ScreenGuis (Rojo/Studio)	✅	Registriert via GuiInitScript

🧾 2. Technische Kernsysteme
System	Status	Beschreibung
PanelManager	✅	Öffnet/schließt Panels via CanvasGroup
PanelDebounce	✅	Clientseitiger Klickschutz
ServerDebounce	✅	Schutz vor Server-Spam via RemoteEvents
GuiResolver	✅	Zugriff per GetPanel(guiName, panelName)
Logging & Debug	✅	Alle Scripts mit print() / warn() versehen

🖼️ 3. GUI-Panelsystem (Client)
Panel/GUI	Status	Besonderheiten
BattlepassPanel	✅	EXP-Bar, LockSystem, modular aufgebaut
ShopPanel	✅	Gamepasses, DevProducts + Serverhandler
CodesPanel	✅	FocusLost + Server-Validation
NewsPanel	✅	Markdown-Parsing, Mehrfachauswahl
ProfilePanel	✅	Titelwahl, Avatarbild, Neonfarben
TitlesPanel	✅	Auswahl-Logik + Feedback
MainMenuGui	✅	Breath-Tween + Mapping via Buttons
QuestsGui	✅	Multi-Tab-System, Claim-System, Indikator, HoverOverlay
InventoryGui	✅	Grid-Layout, Tabs, Stackanzeige, dynamischer Tooltip
UnitInventoryGui	✅	Equip-System, SlotBar, InfoPanel, Equip/Unequip-Buttons
Weitere (z. B. Feed/Fuse)	🔜	Vorbereitung begonnen, noch nicht aktiv

📐 GUI-Standardgrößen
Typ	Größe (Size)	Position
StandardPanel	{0, 910}, {0, 705}	{0, 410}, {0, 80}
MidSizePanel	{0, 450}, {0, 585}	{0, 660}, {0, 150}
SmallPanel	{0, 500}, {0, 350}	{0, 620}, {0, 250}

🔧 4. Serverseitige Systeme
System	Status	Beschreibung
ShopServerHandler	✅	Kaufverarbeitung, Abbruchsicherheit, Logging
CodesServerHandler	✅	Codeprüfung mit DataStore
BattlepassInfoProvider	✅	RemoteFunction liefert EXP, Level
QuestServerHandler	✅	Gibt Testquests zurück, verarbeitet Claim + RewardPopup
RemoteEvents / Functions	✅	Einheitlich in ReplicatedStorage.Remotes vorhanden

🧩 5. Battlepass-System
Element	Status	Beschreibung
BattlepassModule	✅	Belohnungen über Table, modular
EXP-Bar + Levelanzeige	✅	UI-gebunden, animiert
Lock-Status / Premiumcheck	✅	Sichtbarkeit dynamisch
Claim-System	🔜	Muss noch angebunden & mit Server verknüpft werden
Infinity Mode	❌	Noch nicht implementiert

📋 6. Quest-System
Element	Status	Beschreibung
QuestsGui	✅	Tabs (Daily–Progress), Claim-Logik, HoverOverlay, Indicator
QuestClientScript	✅	Serveranbindung, Fortschritt, Rewards, persistente Tab-Auswahl
QuestServerHandler	✅	Gibt Testdaten zurück, verarbeitet Claim + RewardPopup
QuestProgressService	✅	Simuliert Fortschritt (Kills, Summons etc.)
QuestClaimResult	✅	Sendet Popup-Daten bei Erfolg
ClaimAllButton	🔜	Sichtbar, aber noch ohne Funktion
DataStore-Tracking	❌	Noch nicht implementiert

🧰 7. Unit-System (NEU)
Element	Status	Beschreibung
UnitInventoryPanel	✅	Viewport-basierte Darstellung, Sortierung nach Equip-Status
EquipSlotBar	✅	6 feste Slots, sichtbar im MainMenuGui
EquipButton	✅	Rüstet Unit in freien Slot aus
UnequipButton	✅	Entfernt Unit aus Slot, aktualisiert Ansicht
InfoPanel	✅	Zeigt Name, Bild, Typ, Trait
BaseId-Limit	✅	Eine Unit-Art nur 1x gleichzeitig ausrüstbar
ServerSync	🔜	Noch clientseitig, Serverdaten folgen später
Feed/Fuse/SkillTree	🔜	Buttons sichtbar, noch ohne Funktion

📦 8. Geplante Features (Update)
Feature	Status	Beschreibung
🎁 Claim-All Button	🟡	Claim + Servercheck + UI-Finish
🧰 Tooltip-System	🔜	Zentrales Modul folgt später (für Shop, Quests, Units)
📋 Quest-System-Trigger	🔜	Fortschritt durch echte Gameplay-Events
💾 Equip-ServerSync	🔜	Equip/Unequip via Remote an Server übermitteln
🧪 Trait-Tooltip	🔜	Hover über Trait/Type erzeugt InfoPopup
🧠 Fuse/Feed/Skill vorbereiten	🔜	Platzhalter + Basislogik für spätere Freischaltung

📊 9. Entwicklung & Organisation
Bereich	Status	Beschreibung
GitHub-Verknüpfung	✅	Repository aktiv
Rojo-Sync Tools	✅	.bat/.sh zum Synchronisieren vorhanden
Debug-Log-Ausgaben	✅	In allen relevanten Scripts eingebaut
TaskBoard.md	✅	Aktueller Stand dokumentiert (siehe oben)

🔜 10. Nächste Schritte
🧠 TooltipSystem vorbereiten (für Traits, Typen, Rarities)

🔁 Equip/Unequip an Server synchronisieren

🔒 Optionale Limitierungen (z. B. nur 1x Mythic, nur 1x Flying)

🎨 Feed/Fuse/SkillTree-System (UI-Platzhalter vorbereiten)

💾 Save/Load Equip-Daten beim Join über DataStore (später)

