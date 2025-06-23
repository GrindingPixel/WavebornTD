# 📋 Waveborn TD – TaskBoard (Stand: 2025-06-23)

---

## 🧱 1. Projektstruktur & Rojo Setup

| Element                      | Status | Beschreibung                                     |
| ---------------------------- | ------ | ------------------------------------------------ |
| default.project.json         | ✅      | Mit $className: "Script" korrekt konfiguriert   |
| Rojo src/-Struktur           | ✅      | Modules, GuiScripts, Server sauber getrennt      |
| .lua UTF-8 Format            | ✅      | Alle Dateien UTF-8 ohne BOM                      |
| ModuleScript Struktur        | ✅      | Einheitlich unter ReplicatedStorage/Modules      |
| GUI-ScreenGuis (Rojo/Studio) | ✅      | Registriert via GuiInitScript                    |
| Scriptstruktur (neu)         | ✅      | Einheitliche Blöcke: Services, Modules, GUI etc. |

---

## 🧾 2. Technische Kernsysteme

| System          | Status | Beschreibung                                             |
| --------------- | ------ | -------------------------------------------------------- |
| PanelManager    | ✅      | Öffnet/schließt Panels via CanvasGroup + OnOpen Callback |
| PanelDebounce   | ✅      | Clientseitiger Klickschutz                               |
| ServerDebounce  | ✅      | Schutz vor Server-Spam via RemoteEvents                  |
| GuiResolver     | ✅      | Zugriff per GetPanel(guiName, panelName)                 |
| TooltipModule   | ✅      | Finalisiert – mit Markup, Images, Funktionsunterstützung |
| Logging & Debug | ✅      | Alle Scripts mit print() / warn() versehen               |

---

## 🖼️ 3. GUI-Panelsystem (Client)

| Panel/GUI                       | Status | Besonderheiten                                            |
| ------------------------------- | ------ | --------------------------------------------------------- |
| BattlepassPanel                 | ✅      | EXP-Bar, LockSystem, LiveSync, dynamische Labels          |
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
| Weitere (z. B. Trade/SkillTree) | 🔜     | Noch nicht begonnen                                       |

---

## 📦 4. Units-System

| Element                           | Status | Beschreibung                                           |
| --------------------------------- | ------ | ------------------------------------------------------ |
| UnitInventoryGui                  | ✅      | Vollständige Struktur inkl. SlotBar, InfoPanel         |
| UnitClientScript                  | ✅      | Equip-Logik, Slot-Anzeige, PreviewRenderer             |
| UnitModels (ReplicatedStorage)    | ✅      | Modelle geladen & zentralisiert                        |
| UnitStatsModule                   | ✅      | InfoPanel-Werte klar getrennt                          |
| UnitAbilitiesModule               | ✅      | Passive/Active-Auflistung, dynamisch generiert         |
| UnitInfoPanelScript               | ✅      | Preview, Seitenwechsel, Stat-Parsing                   |
| EquipButton / UnEquipButton       | ✅      | Slot-Zuweisung & Entfernung inkl. UUID-Logik           |
| CameraSetup                       | ✅      | Einheitlich mit FieldOfView, Licht & PrimaryPart-Check |
| InfoPanelStats                    | ✅      | Dynamisch geladen über Frame.Name                      |
| AbilityPage                       | ✅      | UIListLayout, Auto-Inhalt via AbilitiesModule          |
| Dropdown-Menü                     | ✅      | Animiertes Menü mit Hover + Outside-Klick-Schließen    |
| UnitServerHandler                 | ✅      | Vollständig über ProfileStoreWrapper angebunden        |

---

## 🧩 5. Battlepass-System

| Element                    | Status | Beschreibung                                               |
| -------------------------- | ------ | ---------------------------------------------------------- |
| BattlepassInfoProvider     | ✅      | Dynamisch, Regenerate(), GetSeasonSeed                     |
| EXP-Bar + Levelanzeige     | ✅      | UI-gebunden, animiert, Live-Update über ProfileSync        |
| Lock-Status / Premiumcheck | ✅      | Sichtbarkeit dynamisch + Claim-Buttons                     |
| Claim-System               | ✅      | Belohnung per Event → RewardSystem                         |
| Bilder + Tooltip           | ✅      | ItemData-Verknüpfung + Iconanzeige in Buttons              |
| ItemLabel-Namen            | ✅      | FreeRewardLabel1 / PremiumRewardLabel1 korrekt gesetzt     |
| Reset bei neuem Seed       | ✅      | Seedwechsel → Reset Level/EXP/Claimed/HasPremium           |
| Infinity Mode              | ❌      | Noch nicht implementiert                                   |

---

## 📋 6. Quest-System

| Element              | Status | Beschreibung                                                |
| -------------------- | ------ | ----------------------------------------------------------- |
| QuestsGui            | ✅      | Tabs (Daily–Progress), Claim-Logik, HoverOverlay, Indicator |
| QuestClientScript    | ✅      | Refactort – ClaimAll, Fortschritt, UI aktualisiert          |
| QuestServerHandler   | ✅      | Refactort – ClaimAll + RewardEvent                          |
| QuestProgressService | 🗑️      | Entfernt – ersetzt durch ProgressTrackerService             |
| ProgressTrackerService | ✅    | Hört auf Events (EnemyKilled, etc.)                         |
| QuestClaimResult     | ✅      | Sendet Popup-Daten bei Erfolg                               |
| ClaimAllButton       | ✅      | Funktioniert, Debounce + Eventanbindung                     |

---

## 📍 7. Teleport-System

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

---

## 🧭 8. FastTravel-System

| Element               | Status | Beschreibung                                      |
| --------------------- | ------ | ------------------------------------------------- |
| FastTravelGui         | ✅      | Separates GUI, öffnet über MainMenu               |
| PanelManager          | ✅      | Integration mit PanelDebounce                     |
| TeleportToAreaRequest | ✅      | Serverevent, Ziel: CFrame-Positionswechsel        |
| Teleportziele         | ✅      | Story, Raid, Summon, Utils (Trade folgt später)   |
| Buttonstruktur        | ✅      | ImageButtons mit Beschriftung, Hover über Tooltip |

---

## 🔒 9. Persistent PlayerData (ProfileService → ProfileStore)

| Element                                | Status | Beschreibung                                                    |
| -------------------------------------- | ------ | --------------------------------------------------------------- |
| ProfileStoreWrapper                    | ✅      | Zentrales Interface für alle Data-Operationen                   |
| ProfileService entfernt                | ✅      | Alte Implementierung entfernt                                   |
| PlayerDataTemplate                     | ✅      | DataTemplate inkl. Battlepass.HasPremium, Seed, Claimed etc.    |
| AutoSave & Release                     | ✅      | Implementiert im Wrapper                                        |
| Battlepass-Seed Reset                  | ✅      | Reset bei Seed-Wechsel aktiv (inkl. Premium & Claimed)          |
| LegacyServices (InventoryService etc.) | ✅      | Entfernt / durch Wrapper ersetzt                                |
| GrantRewards Funktion                  | ✅      | Serverweiter Standard für Item-Belohnungen                      |

---

## ✅ 10. Abgeschlossene Tasks (seit 2025-06-22)

* BattlepassClientScript: Dynamische ItemLabels eingebaut (`FreeRewardLabel1` / `PremiumRewardLabel1`)
* Battlepass-Bug bei ClaimFixed (Reward wurde nicht ins Inventory geschrieben)
* RewardSystem vollständig überprüft (Quest vs Battlepass)
* GrantRewards: LiveSync & RewardStack funktionieren serverseitig
* ProfileStoreWrapper: Einheitlicher Reward-Flow inkl. Itemprüfung
* LiveSync für Battlepass/Inventory wird korrekt empfangen & angezeigt
* Battlepass zeigt wieder alle 100 Level korrekt an (Fix EXP-Handling)
* Refactor abgeschlossen: `UnitServerHandler` nutzt nun ProfileWrapper

---

## 🔜 11. Nächste Schritte

* 🔧 ClaimAllBattlepassButton vorbereiten
* 🔧 Implement RewardPopupGui für Quest & Battlepass
* 🔄 Refactor CodeRedeemHandler inkl. CodeResultEvent
* 🔄 Refactor ShopServerHandler vollständig mit Wrapper
* 💬 TradeSystem: geplant für später nach vollständigem Release
