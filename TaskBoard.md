📋 Waveborn TD – TaskBoard (Stand: 2025-05-13)
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
Weitere (Units etc.)	🔜	Noch nicht begonnen

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
QuestServerHandler	✅	Liefert Testquests, verarbeitet Claims & Rewards
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

📦 7. Geplante Features
Feature	Status	Beschreibung
🎁 Claim-All Button	🟡	Claim + Servercheck + UI-Finish
🎟️ Premium Unlock (Item-basiert)	🟡	Aktivierung über Inventory-Eintrag
🧰 Tooltip-System	🟡	Hover-Text für Rewards, Einheiten etc.
📦 Inventory-System	🔜	Struktur, Anzeige, Filter
📋 Quest-System	🔜	Daily / Weekly Fortschritt mit echtem Trigger
🧪 Unit-System	🔜	Tags, Traits, Rarity
🌐 Leaderboards	❌	Noch nicht entworfen

📊 8. Entwicklung & Organisation
Bereich	Status	Beschreibung
GitHub-Verknüpfung	✅	Repository live & synchronisiert
Rojo-Sync Tools	✅	.bat/.sh zum Synchronisieren
Debug-Log-Ausgaben	✅	Vollständig in allen Scripts eingebaut
Panel-Logging	✅	Jede Öffnung/Schließung sichtbar im Output

🔜 Nächste Schritte
🎁 ClaimAll aktivieren (Client + Server-Verarbeitung)

✨ RewardPopupGui für visuelles Item-Feedback nach Claim

🧠 QuestServerHandler: type-Feld pro Quest standardisieren

🔁 QuestProgressService: Trigger über Spielaktionen einbauen

🟢 Tab-Indikatoren bei Server-Fail (z. B. F5) stabilisieren

🌈 HoverOverlay-Effekt weiter optimieren (Kollisionsvermeidung, Mausgeschwindigkeit)

🎨 Visuals für erfüllte/erledigte Quests (z. B. graue Card + ✓ Symbol)

