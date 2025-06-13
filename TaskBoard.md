📋 Waveborn TD – TaskBoard (Stand: 2025-06-12)

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
Logging & Debug | ✅ | Alle Scripts mit print() / warn() versehen  

🖼️ 3. GUI-Panelsystem (Client)  
Panel/GUI | Status | Besonderheiten  
---|---|---  
BattlepassPanel | ✅ | EXP-Bar, LockSystem, modular aufgebaut  
ShopPanel | ✅ | Gamepasses, DevProducts + Serverhandler  
CodesPanel | ✅ | FocusLost + Server-Validation  
NewsPanel | ✅ | Markdown-Parsing, Mehrfachauswahl  
ProfilePanel | ✅ | Titelwahl, Avatarbild, Neonfarben  
TitlesPanel | ✅ | Auswahl-Logik + Feedback  
MainMenuGui | ✅ | Breath-Tween + Mapping via Buttons  
QuestsGui | ✅ | Multi-Tab-System, Claim-System, Indikator, HoverOverlay  
InventoryGui | ✅ | Grid-Layout, Tabs, Stackanzeige, TooltipModule integriert  
UnitInventoryGui | ✅ | UnitGridFrame, InfoPanel, EquipSystem, SlotBar  
MapTeleportGui | ✅ | Welten- und Stage-Auswahl, RewardInfo, Tooltip, Teleport + Timeout  
TooltipGui | ✅ | Eigenes ScreenGui für globalen Tooltip (ZIndex via DisplayOrder)  
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
ShopServerHandler | ✅ | Kaufverarbeitung, Abbruchsicherheit, Logging  
CodesServerHandler | ✅ | Codeprüfung mit DataStore  
BattlepassInfoProvider | ✅ | RemoteFunction liefert EXP, Level  
QuestServerHandler | ✅ | Gibt Testquests zurück, verarbeitet Claim + RewardPopup  
TeleportPortalHandler | ✅ | Portal-Touched → MapTeleportGui öffnen  
TeleportStageHandler | ✅ | TeleportStageRequest → echter PlaceId-Teleport  
RemoteEvents / Functions | ✅ | Einheitlich in ReplicatedStorage.Remotes vorhanden  

🧩 5. Battlepass-System  
Element | Status | Beschreibung  
---|---|---  
BattlepassModule | ✅ | Belohnungen über Table, modular  
EXP-Bar + Levelanzeige | ✅ | UI-gebunden, animiert  
Lock-Status / Premiumcheck | ✅ | Sichtbarkeit dynamisch  
Claim-System | 🔜 | Muss noch angebunden & mit Server verknüpft werden  
Infinity Mode | ❌ | Noch nicht implementiert  

📋 6. Quest-System  
Element | Status | Beschreibung  
---|---|---  
QuestsGui | ✅ | Tabs (Daily–Progress), Claim-Logik, HoverOverlay, Indicator  
QuestClientScript | ✅ | Serveranbindung, Fortschritt, Rewards, persistente Tab-Auswahl  
QuestServerHandler | ✅ | Gibt Testdaten zurück, verarbeitet Claim + RewardPopup  
QuestProgressService | ✅ | Simuliert Fortschritt (Kills, Summons etc.)  
QuestClaimResult | ✅ | Sendet Popup-Daten bei Erfolg  
ClaimAllButton | 🔜 | Sichtbar, aber noch ohne Funktion  
DataStore-Tracking | ❌ | Noch nicht implementiert  

📦 7. Units-System  
Element | Status | Beschreibung  
---|---|---  
UnitInventoryGui | ✅ | Vollständige Struktur inkl. SlotBar, InfoPanel  
UnitClientScript | ✅ | Equip-Logik, Slot-Anzeige, PreviewRenderer  
UnitModels (ReplicatedStorage) | ✅ | Modelle geladen & zentralisiert  
UnitStatsModule | ✅ | Einheitliche Statstruktur (PlacementCost, Damage usw.)  
UnitAbilitiesModule | ✅ | Passive/Active-Auflistung, dynamisch generiert  
UnitInfoPanelScript | ✅ | Preview, Seitenwechsel, Stat-Parsing  
EquipButton | ✅ | Triggert Slot-Vergabe und Slot-Preview  
UnEquipButton | ✅ | Entfernt Unit visuell & logisch  
CameraSetup | ✅ | Einheitlich mit FieldOfView, Licht & PrimaryPart-Check  
InfoPanelStats | ✅ | Dynamisch geladen über Frame.Name  
AbilityPage | ✅ | UIListLayout, Auto-Inhalt via AbilitiesModule  
Dropdown-Menü (Feed, Evolve etc.) | ✅ | Animiertes Menü mit Hover + Outside-Klick-Schließen  

📍 8. Teleport-System  
Element | Status | Beschreibung  
---|---|---  
Portal-Part `Touched` → UI | ✅ | Öffnet MapTeleportGui via Remote  
MapTeleportGui | ✅ | Zeigt Welten, Stages, Rewards  
TeleportStageRequest | ✅ | Teleport zu echtem Roblox-PlaceId  
TimeoutReturn | ✅ | Rückteleport zu `Portals.BacktoLobby`  
Close-Button | ✅ | Schließt Panel + löst Rückteleport aus  
Debounce/Touched-Guard | ✅ | Verhindert Mehrfach-Öffnen  
Countdown-Anzeige | ✅ | Zeigt verbleibende Zeit (5 s)  
TouchEnded-Abort | ✅ | Panel schließt beim Portal-Verlassen  

📚 9. Tooltip-System  
Element | Status | Beschreibung  
---|---|---  
TooltipGui | ✅ | Zentrales GUI für alle Tooltips mit DisplayOrder  
TooltipModule | ✅ | Unterstützt [b], \n, [img:id], dynamische Callbacks  
Markup-Parser | ✅ | Farben, Fonts, Icons, Multiline  
Attach-API | ✅ | TooltipModule:Attach(instance, text|function)  
Hover-Follow | ✅ | Positioniert sich zum Cursor, Icon-Support  
Komplexe Inhalte (Stat-Cards) | 🔜 | Geplant für später  

📋 10. Entwicklung & Organisation  
Bereich | Status | Beschreibung  
---|---|---  
GitHub-Verknüpfung | ✅ | Repository live & synchronisiert  
Rojo-Sync Tools | ✅ | .bat/.sh zum Synchronisieren  
Debug-Log-Ausgaben | ✅ | Vollständig in allen Scripts eingebaut  
PanelManager-Vereinheitlichung | 🔜 | `Open()`/`Close()` Wrapper in allen GUIs  
Zentrales Styling-Modul | 🔜 | Für Fonts, Farben & UI-Standards  
GuiLayerManager | 🔜 | Zentrale Verwaltung von DisplayOrder / ZIndex-Prioritäten  

🔜 11. Nächste Schritte  
🎁 ClaimAll aktivieren (Client + Server-Verarbeitung)  
✨ RewardPopupGui für visuelles Item-Feedback nach Claim  
🧠 QuestServerHandler: type-Feld pro Quest standardisieren  
🔁 QuestProgressService: Trigger über Spielaktionen einbauen  
🌈 HoverOverlay-Effekt weiter optimieren (Kollisionsvermeidung, Mausgeschwindigkeit)  
📊 UnitInventory: UnitCount fixen (korrekte Anzahl anzeigen)  
🔍 UnitInventory: funktionierende SearchBar einbauen  
📖 InfoPanel: AbilityPage-Button aktivieren (manueller Wechsel)  
🚪 MapDataModule: Stage.PlaceId einfügen für Teleport pro Map  
🧭 StageTeleport: Dynamisch je nach Modus (Story, Trial, Raid)  
👥 TeleportQueue-System: Gruppen-Matchmaking und Warteschlangen
