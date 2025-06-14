📋 Waveborn TD – TaskBoard (Stand: 2025-06-14)

🧱 1. Projektstruktur & Rojo Setup  
Element | Status | Beschreibung  
---|---|---  
default.project.json | ✅ | Mit $className: "Script" korrekt konfiguriert  
Rojo src/-Struktur | ✅ | Modules, GuiScripts, Server sauber getrennt  
.lua UTF-8 Format | ✅ | Alle Dateien UTF-8 ohne BOM  
ModuleScript Struktur | ✅ | Einheitlich unter ReplicatedStorage/Modules  
GUI-ScreenGuis (Rojo/Studio) | ✅ | Registriert via GuiInitScript  

🧾 2. Technische Kernsysteme  
System | Status | Beschreibung  
---|---|---  
PanelManager | ✅ | Öffnet/schließt Panels via CanvasGroup  
PanelDebounce | ✅ | Clientseitiger Klickschutz  
ServerDebounce | ✅ | Schutz vor Server-Spam via RemoteEvents  
GuiResolver | ✅ | Zugriff per GetPanel(guiName, panelName)  
TooltipModule | ✅ | Unterstützt [b], [img:id], dynamische Inhalte  
Logging & Debug | ✅ | Alle Scripts mit Debug-Ausgaben ausgestattet  
Neue Scriptstruktur | ✅ | Einheitlich: Services, Modules, GUI, Remotes, Events  

🖼️ 3. GUI-Panelsystem (Client)  
Panel/GUI | Status | Besonderheiten  
---|---|---  
BattlepassPanel | ✅ | EXP-Bar, LockSystem, modular aufgebaut  
ShopPanel | ✅ | Gamepasses, DevProducts + Serverhandler  
CodesPanel | ✅ | FocusLost + Server-Validation  
NewsPanel | ✅ | Markdown-Parsing, Mehrfachauswahl  
ProfilePanel | ✅ | Titelwahl, Avatarbild, Neonfarben  
TitlesPanel | ✅ | Auswahl-Logik + Feedback  
MainMenuGui | ✅ | Breath-Tween, zentraler `TeleportButton`  
QuestsGui | ✅ | Multi-Tab-System, Claim-System, Tooltip, Indikator  
InventoryGui | ✅ | Stackanzeige, Tabs, Suchfunktion vorbereitet, Tooltip  
UnitInventoryGui | ✅ | InfoPanel, EquipSystem, SlotBar  
MapTeleportGui | ✅ | Stage-Wahl, Rewards + Tooltip, Server-Teleport  
FastTravelGui | ✅ | Lobby-Teleport per UI (Story, Raid, Summon)  
Weitere (z. B. SkillTree) | 🔜 | Noch nicht begonnen  

📐 GUI-Standardgrößen  
Typ | Größe (Size) | Position  
---|---|---  
StandardPanel | {0, 910}, {0, 705} | {0, 410}, {0, 80}  
MidSizePanel | {0, 450}, {0, 585} | {0, 660}, {0, 150}  
SmallPanel | {0, 500}, {0, 350} | {0, 620}, {0, 250}  

🔧 4. Serverseitige Systeme  
System | Status | Beschreibung  
---|---|---  
ShopServerHandler | ✅ | Kaufverarbeitung + Logging  
CodesServerHandler | ✅ | Einlösung + DataStore-Prüfung  
BattlepassInfoProvider | ✅ | EXP, Level via RemoteFunction  
QuestServerHandler | ✅ | Testquests, Claim, RewardPopup-Support  
TeleportPortalHandler | ✅ | Trigger per Part.Touch  
TeleportStageHandler | ✅ | Teleportiert zu PlaceId  
TeleportLobbyHandler | ✅ | In-Place-Teleport zu Ziel-Parts (Story etc.)  
RemoteEvents / Functions | ✅ | Standardisiert in ReplicatedStorage  

🧩 5. Battlepass-System  
Element | Status | Beschreibung  
---|---|---  
BattlepassModule | ✅ | Stufen und Rewards als Tabelle  
EXP-Bar + Levelanzeige | ✅ | Fortschrittsbalken animiert  
Lock-Status / Premiumcheck | ✅ | Dynamisch sichtbar  
Claim-System | 🔜 | Visuelles Popup + Serverabgleich folgt  
Infinity Mode | ❌ | Noch nicht begonnen  

📋 6. Quest-System  
Element | Status | Beschreibung  
---|---|---  
QuestsGui | ✅ | Multi-Tab (Daily, Weekly etc.), ClaimButtons  
QuestClientScript | ✅ | Refactored, TooltipModule integriert  
QuestServerHandler | ✅ | DummyQuests, verarbeitet Claim + Serverlogik  
QuestProgressService | ✅ | Simulierte Fortschrittsverarbeitung  
QuestClaimResult | ✅ | Serverantwort → Popup später  
ClaimAllButton | 🔜 | Sichtbar, aber keine Funktion  
DataStore-Tracking | ❌ | Noch nicht begonnen  

📦 7. Units-System  
Element | Status | Beschreibung  
---|---|---  
UnitInventoryGui | ✅ | GridFrame, EquipBar, InfoPanel  
UnitClientScript | ✅ | EquipLogik, SlotSync, PreviewRender  
UnitModels | ✅ | Models zentral in ReplicatedStorage  
UnitStatsModule | ✅ | PlacementCost, Damage, Range etc.  
UnitAbilitiesModule | ✅ | Aktive/passive Fähigkeiten  
UnitInfoPanelScript | ✅ | PageSwitch, Hover-Stat-Felder  
Dropdown-Menü | ✅ | Feed, Evolve, Fuse etc. per Button aufrufbar  
CameraSetup | ✅ | Einheitlich: FOV, Licht, PrimaryPart-Check  

📍 8. Teleport-System  
Element | Status | Beschreibung  
---|---|---  
Touched → MapTeleportGui | ✅ | Trigger über Portal  
MapTeleportGui | ✅ | Weltwahl → Stagewahl → Teleport  
UIStroke für Weltbuttons | ✅ | Visueller Auswahlrahmen  
StageRewardInfo | ✅ | Erst bei Stageklick sichtbar  
TeleportStageRequest | ✅ | Ziel wird durch MapData bestimmt  
MapDataModule | ✅ | Weltname → Stages mit Rewards + PlaceId  
TimeoutReturn | ✅ | Rück-Teleport via Remote  
FastTravelGui | ✅ | Eigenes GUI mit ScrollingFrame, Buttons  
TeleportToAreaRequest | ✅ | Zielname → Server → Position  
TeleportLobbyHandler | ✅ | Setzt CFrame auf ZielPart  
Responsives Layout | ✅ | Alle GUIs 100 % auf `Scale`, AnchorPoint  

📋 9. Entwicklung & Organisation  
Bereich | Status | Beschreibung  
---|---|---  
GitHub-Verknüpfung | ✅ | Repo synchronisiert mit Rojo  
Debug-Log-Ausgaben | ✅ | Alle wichtigen Scripts loggen Server/Client  
Tooltip-System zentral | ✅ | In allen GUIs verfügbar  
Scriptstruktur-Standard | 🔜 | Alle Module auf neues Format umstellen  
PanelManager-Wrapper | 🔜 | Alle GUIs auf `Open()` / `Close()` migrieren  

🧠 Technische Erweiterungen & Roadmap  
Eintrag | Status | Notiz  
---|---|---  
[Tooltip] mit [img:id] | ✅ | Funktioniert inkl. Hover  
[Tooltip] StatTemplate | 🔜 | z. B. für Quests und Items  
PanelManager:CloseSync | 🔜 | Rücksetzen isOpen-State später  
ClaimAll | 🔜 | Funktion + Serverlogik fehlt  
RewardPopupGui | 🔜 | Visuelles Feedback nach Claim  
TeleportQueue | 🔜 | Vorbereitung für Gruppen/Trial-Teleports  
MapData: PlaceId je Stage | 🔜 | Struktur bereits angelegt  
HoverOverlay-Optimierung | 🔜 | Verbesserter Maus-Check  
FastTravelGui: Slide-FX | 🔜 | Panel-Effekt optional später  

🔜 10. Nächste Schritte  
🎁 ClaimAll aktivieren (Client + Server)  
✨ RewardPopupGui visuell implementieren  
📘 QuestClientScript vereinheitlichen  
📊 Inventory: UnitCount + Suchleiste  
📦 PanelManager `Open()`/`Close()` Wrapper in allen GUIs  
🧭 FastTravelGui visuell erweitern (FX, Lock, etc.)  
