📋 Waveborn TD – TaskBoard (Stand: 2025-06-18)

🧱 1. Projektstruktur & Rojo Setup

| Element                      | Status | Beschreibung                                     |
| ---------------------------- | ------ | ------------------------------------------------ |
| default.project.json         | ✅      | Mit \$className: "Script" korrekt konfiguriert   |
| Rojo src/-Struktur           | ✅      | Modules, GuiScripts, Server sauber getrennt      |
| .lua UTF-8 Format            | ✅      | Alle Dateien UTF-8 ohne BOM                      |
| ModuleScript Struktur        | ✅      | Einheitlich unter ReplicatedStorage/Modules      |
| GUI-ScreenGuis (Rojo/Studio) | ✅      | Registriert via GuiInitScript                    |
| Scriptstruktur (neu)         | ✅      | Einheitliche Blöcke: Services, Modules, GUI etc. |

🧾 2. Technische Kernsysteme

| System          | Status | Beschreibung                                             |
| --------------- | ------ | -------------------------------------------------------- |
| PanelManager    | ✅      | Öffnet/schließt Panels via CanvasGroup                   |
| PanelDebounce   | ✅      | Clientseitiger Klickschutz                               |
| ServerDebounce  | ✅      | Schutz vor Server-Spam via RemoteEvents                  |
| GuiResolver     | ✅      | Zugriff per GetPanel(guiName, panelName)                 |
| TooltipModule   | ✅      | Finalisiert – mit Markup, Images, Funktionsunterstützung |
| Logging & Debug | ✅      | Alle Scripts mit print() / warn() versehen               |

🖼️ 3. GUI-Panelsystem (Client)

| Panel/GUI                       | Status | Besonderheiten                                            |
| ------------------------------- | ------ | --------------------------------------------------------- |
| BattlepassPanel                 | ✅      | EXP-Bar, LockSystem, modular aufgebaut                    |
| ShopPanel                       | ✅      | Gamepasses, DevProducts + Serverhandler                   |
| CodesPanel                      | ✅      | FocusLost + Server-Validation                             |
| NewsPanel                       | ✅      | Markdown-Parsing, Mehrfachauswahl                         |
| ProfilePanel                    | ✅      | Titelwahl, Avatarbild, Neonfarben                         |
| TitlesPanel                     | ✅      | Auswahl-Logik + Feedback                                  |
| MainMenuGui                     | ✅      | Breath-Tween + Mapping via Buttons                        |
| QuestsGui                       | ✅      | Multi-Tab-System, Claim-System, Indikator, HoverOverlay   |
| InventoryGui                    | ✅      | Grid-Layout, Tabs, Stackanzeige, dynamischer Tooltip      |
| UnitInventoryGui                | ✅      | UnitGridFrame, InfoPanel, EquipSystem, SlotBar            |
| MapTeleportGui                  | ✅      | Welten- und Stage-Auswahl, RewardInfo, Teleport + Timeout |
| FastTravelGui                   | ✅      | Panel mit Story/Raid/Summon-Zielbuttons, teleportfähig    |
| Weitere (z. B. Trade/SkillTree) | 🔜     | Noch nicht begonnen                                       |

📐 GUI-Standardgrößen

| Typ           | Größe (Size)       | Position           |
| ------------- | ------------------ | ------------------ |
| StandardPanel | {0, 910}, {0, 705} | {0, 410}, {0, 80}  |
| MidSizePanel  | {0, 450}, {0, 585} | {0, 660}, {0, 150} |
| SmallPanel    | {0, 500}, {0, 350} | {0, 620}, {0, 250} |

🔧 4. Serverseitige Systeme

| System                   | Status | Beschreibung                                           |
| ------------------------ | ------ | ------------------------------------------------------ |
| ShopServerHandler        | ✅      | Kaufverarbeitung, Abbruchsicherheit, Logging           |
| CodesServerHandler       | ✅      | Codeprüfung mit DataStore                              |
| BattlepassInfoProvider   | ✅      | RemoteFunction liefert EXP, Level                      |
| QuestServerHandler       | ✅      | Gibt Testquests zurück, ClaimSingle + ClaimAll         |
| TeleportPortalHandler    | ✅      | Portal-Touched → MapTeleportGui öffnen                 |
| TeleportStageHandler     | ✅      | TeleportStageRequest + TimeoutReturn → CFrame-Teleport |
| TeleportLobbyHandler     | ✅      | Empfängt Zielname → Positionswechsel                   |
| RemoteEvents / Functions | ✅      | Einheitlich in ReplicatedStorage.Remotes vorhanden     |

🧩 5. Battlepass-System

| Element                    | Status | Beschreibung                        |
| -------------------------- | ------ | ----------------------------------- |
| BattlepassModule           | ✅      | Belohnungen über Table, modular     |
| EXP-Bar + Levelanzeige     | ✅      | UI-gebunden, animiert               |
| Lock-Status / Premiumcheck | ✅      | Sichtbarkeit dynamisch              |
| Claim-System               | ✅      | Belohnung per Event + RewardService |
| Infinity Mode              | ❌      | Noch nicht implementiert            |

📋 6. Quest-System

| Element              | Status | Beschreibung                                                |
| -------------------- | ------ | ----------------------------------------------------------- |
| QuestsGui            | ✅      | Tabs (Daily–Progress), Claim-Logik, HoverOverlay, Indicator |
| QuestClientScript    | ✅      | Refactort – ClaimAll, Fortschritt, UI aktualisiert          |
| QuestServerHandler   | ✅      | Refactort – ClaimAll + RewardEvent                          |
| QuestProgressService | 🔜     | Veraltet, wird entfernt                                     |
| QuestClaimResult     | ✅      | Sendet Popup-Daten bei Erfolg                               |
| ClaimAllButton       | ✅      | Funktioniert, Debounce + Eventanbindung                     |

📦 7. Units-System

| Element                           | Status | Beschreibung                                           |
| --------------------------------- | ------ | ------------------------------------------------------ |
| UnitInventoryGui                  | ✅      | Vollständige Struktur inkl. SlotBar, InfoPanel         |
| UnitClientScript                  | ✅      | Equip-Logik, Slot-Anzeige, PreviewRenderer             |
| UnitModels (ReplicatedStorage)    | ✅      | Modelle geladen & zentralisiert                        |
| UnitStatsModule                   | ✅      | InfoPanel-Werte klar getrennt                          |
| UnitAbilitiesModule               | ✅      | Passive/Active-Auflistung, dynamisch generiert         |
| UnitInfoPanelScript               | ✅      | Preview, Seitenwechsel, Stat-Parsing                   |
| EquipButton                       | ✅      | Triggert Slot-Vergabe und Slot-Preview                 |
| UnEquipButton                     | ✅      | Entfernt Unit visuell & logisch                        |
| CameraSetup                       | ✅      | Einheitlich mit FieldOfView, Licht & PrimaryPart-Check |
| InfoPanelStats                    | ✅      | Dynamisch geladen über Frame.Name                      |
| AbilityPage                       | ✅      | UIListLayout, Auto-Inhalt via AbilitiesModule          |
| Dropdown-Menü (Feed, Evolve etc.) | ✅      | Animiertes Menü mit Hover + Outside-Klick-Schließen    |

📍 8. Teleport-System

| Element                    | Status | Beschreibung                                           |
| -------------------------- | ------ | ------------------------------------------------------ |
| Portal-Part `Touched` → UI | ✅      | Öffnet MapTeleportGui via Remote                       |
| MapTeleportGui             | ✅      | Zeigt Welten, Stages, Rewards                          |
| TeleportStageRequest       | ✅      | TeleportStageRequest + TimeoutReturn → CFrame-Teleport |
| TimeoutReturn              | ✅      | Rückteleport zu `Portals.BacktoLobby`                  |
| Close-Button               | ✅      | Schließt Panel + löst Rückteleport aus                 |
| Debounce/Touched-Guard     | ✅      | Verhindert Mehrfach-Öffnen                             |
| Countdown-Anzeige          | ✅      | Zeigt verbleibende Zeit (5 s)                          |
| TouchEnded-Abort           | ✅      | Panel schließt beim Portal-Verlassen                   |
| MapDataModule              | ✅      | Pro Welt einheitliche Map, Stages definierbar          |
| WorldSelection             | ✅      | Auswahl via Button + UIStroke                          |
| StageInfo                  | ✅      | Rewards mit Tooltip, ImageLabel + Text                 |
| Initialzustand             | ✅      | Keine Stage/Info sichtbar bis Auswahl                  |

🧭 9. FastTravel-System

| Element               | Status | Beschreibung                                      |
| --------------------- | ------ | ------------------------------------------------- |
| FastTravelGui         | ✅      | Separates GUI, öffnet über MainMenu               |
| PanelManager          | ✅      | Integration mit PanelDebounce                     |
| TeleportToAreaRequest | ✅      | Serverevent, Ziel: CFrame-Positionswechsel        |
| Teleportziele         | ✅      | Story, Raid, Summon, Utils (Trade folgt später)   |
| Buttonstruktur        | ✅      | ImageButtons mit Beschriftung, Hover über Tooltip |

🧪 10. Refactoring & Codepflege

| Bereich                        | Status | Beschreibung                                             |
| ------------------------------ | ------ | -------------------------------------------------------- |
| PanelManager-Vereinheitlichung | ✅      | Standardisiert (Open/Close)                              |
| Scriptformatierung             | ✅      | Alle Scripts refactort (Formatblöcke, Struktur)          |
| TooltipModule                  | ✅      | Final – mit \[b], \n, \[img\:id], Attach per Function    |
| Debounce-System                | ✅      | PanelDebounce, ServerDebounce systemweit im Einsatz      |
| MapDataUtils                   | ✅      | GetStageById + RewardPreview-Hilfsfunktionen vorbereitet |

🔒 11. Persistent PlayerData (ProfileService → ProfileStore)

| Element                                | Status | Beschreibung                                  |
| -------------------------------------- | ------ | --------------------------------------------- |
| ProfileStoreWrapper                    | ✅      | Zentrales Interface für alle Data-Operationen |
| ProfileService entfernt                | 🔜     | Alte Implementierung deaktiveren              |
| PlayerDataTemplate                     | ✅      | DataTemplate inkl. Battlepass.HasPremium      |
| AutoSave & Release                     | ✅      | Implementiert im Wrapper                      |
| LegacyServices (InventoryService etc.) | 🔜     | Werden durch Wrapper ersetzt                  |

🔜 12. Nächste Schritte

* 🛠 Migrate DataSystem: Implement ProfileStoreWrapper & deprecate ProfileService
* 🔄 Refactor InventoryServerHandler zu ProfileStoreWrapper
* 🔄 Refactor ShopServerHandler zu ProfileStoreWrapper
* 🔄 Refactor QuestServerHandler inkl. ClaimAll
* 🔄 Refactor BattlepassServerHandler & BattlepassInfoProvider
* 🔄 Refactor UnitServerHandler zu ProfileStoreWrapper
* ➕ Neues Script: UpgradeServerHandler & Remotes
* ➕ Neues ModuleScript: ProgressTrackerService
* ➕ Neues ModuleScript: CodeDataModule & Config
* 🔄 Refactor CodeRedeemHandler inkl. CodeResultEvent
* 🔄 Adjust QuestClientScript an neue Remotes
* 🔄 Add Wrapper-Methode SetBattlepassPremium
* 🔧 Implement RewardPopupGui für Quest & Battlepass
* 💬 TradeSystem: später geplant
* 🧪 PvP-Arena: als langfristige Erweiterung vorgemerkt

✅ Roadmap komplett an aktuelles Projekt angepasst – alle Tasks für Migration und Weiterentwicklung eingetragen.
