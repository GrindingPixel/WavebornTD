# 📋 Waveborn TD – TaskBoard (Stand: 2025-07-29)

---

## 🧱 1. Projektstruktur & Rojo Setup

| Element                      | Status | Beschreibung                                     |
| ---------------------------- | ------ | ----------------------------------------------- |
| default.project.json         | ✅      | Konfiguriert, Scripts korrekt zugewiesen        |
| ModuleScript-Struktur        | ✅      | Einzigartige Module pro Funktion                |
| Rojo-Setup                   | ✅      | Projektstruktur unter src/                      |
| Script-Format                | ✅      | UTF-8 + einheitliches Line-Ending               |

---

## 🧾 2. Technische Kernsysteme

| System               | Status | Beschreibung                                        |
| ------------------- | ------ | --------------------------------------------------- |
| PanelManager         | ✅      | Panels mit OnOpen, Schließen, Debounce             |
| PanelDebounce        | ✅      | Klickschutz für schnelle Interaktionen             |
| GuiResolver          | ✅      | Einheitliche GUI-Zugriffe                          |
| ServerDebounce       | ✅      | Serverseitige Klick-/Spam-Prüfung                  |
| ProfileLoadedEvent   | ✅      | Wird bei erfolgreichem Profil-Laden gefeuert       |
| ProfileChangedEvent  | ✅      | Wird bei Änderungen wie Purchases oder BP gesendet |
| IsProfileReady Remote| ✅      | Clients prüfen Serverstatus vor Ladeaktionen       |
| ProfileSyncService   | ✅      | LiveSync von `Settings`, `TDEclipsium`, `Units`    |

---

## 🛒 3. Shop-System

| Element                | Status | Beschreibung                                         |
| ---------------------- | ------ | --------------------------------------------------- |
| ShopClientScript       | ✅      | Buttons, Limits, Live-Sync                          |
| ShopServerHandler      | ✅      | Limitierung, Validierung, Reward-Vergabe            |
| PremiumShopModule      | ✅      | Produktdaten (ProductId, Rewards, Limits)           |
| Purchases-System       | ✅      | One-Time & MaxPurchases live im Shop                |
| UI-Feedback            | ✅      | Buttons mit GLOBAL_PURCHASING_IMAGE                 |
| GetPurchases Remote    | ✅      | Liefert aktuelle Käufe beim Panel-Open              |

---

## 🧩 4. Battlepass-System

| Element                | Status | Beschreibung                                       |
| ---------------------- | ------ | -------------------------------------------------- |
| BattlepassClientScript | ✅      | UI-Aufbau, Claim-Buttons, EXP-Header, Premiumkauf  |
| BattlepassServerHandler| ✅      | ClaimFree/ClaimPremium verarbeitet Claims          |
| BattlepassInfoProvider | ✅      | Leveldaten, EXP-Anforderungen, Seed-System         |
| ProfileStoreWrapper    | ✅      | Battlepass-Verwaltung im Profil, Resets bei Seed-Wechsel |
| PlayerDataTemplate     | ✅      | Battlepass-Felder: Seed, Level, EXP, Claimed etc.  |
| Premiumkauf (DevProduct) | ✅    | Wird als DevProduct gekauft, HasPremium gesetzt     |
| LiveSync BP/Purchases  | ✅      | Premium-Status und Purchases werden korrekt synchronisiert |

---

## 📦 5. Inventory-System

| Element               | Status | Beschreibung                                           |
| --------------------- | ------ | ------------------------------------------------------ |
| GrantRewards          | ✅      | Items & Units werden korrekt ins Inventar eingefügt    |
| InventoryClientScript | ✅      | Live-Sync & Anzeige der Items                         |
| ItemDataModule        | ✅      | Icons, Namen, Metadaten                               |

---

## 🧠 6. Units-System

| Element            | Status | Beschreibung                                                                 |
| ------------------ | ------ | ---------------------------------------------------------------------------- |
| UnitInventoryGui   | ✅      | GridFrame, InfoPanel, SlotBar                                               |
| EquipSystem        | ✅      | Equip/UnEquip mit UUID, Schutz gegen mehrfaches Ausrüsten                   |
| UnitClientScript   | ✅      | Lädt Units, LiveSync, Slot-Anzeige, Equip-Status sofort erkennbar          |
| ProfileStoreWrapper| ✅      | AddUnit/RemoveUnit/GetUnits + Equip/Unequip-Logik                           |
| EquipOrder Sort    | ✅      | Ausgerüstete Units stehen im Inventory oben (Slots 1–6 vor allen anderen)  |
| EquipButtonFix     | ✅      | Equip/Unequip Buttons aktualisieren sich korrekt beim Öffnen               |
| EquipInitSync      | ✅      | EquippedSlot1–6 werden direkt beim Profil-Ready gesetzt                     |

---

## 🧩 7. Quest-System

| Element               | Status | Beschreibung                                    |
| --------------------- | ------ | ----------------------------------------------- |
| QuestClientScript     | ✅      | Claim-Buttons, UI-Updates, Fortschritt          |
| QuestServerHandler    | ✅      | ClaimAll-Event verarbeitet alle Ansprüche       |
| ProgressTrackerService| ✅      | Ersetzt altes QuestProgressService             |

---

## 🗺️ 8. Teleport-System

| Element                     | Status | Beschreibung                                                              |
| ---------------------------|--------|---------------------------------------------------------------------------|
| MapTeleportGui             | ✅     | Welten/Stages mit Rewards                                                 |
| TeleportStageHandler       | ✅     | ServerScript, empfängt Remote `TeleportStageRequest` von Lobby-Client     |
| StageTeleportService       | ✅     | Server-Modul für Match-internen Teleport (Restart, Continue, Leave, Next) |
| FastTravelGui              | ✅     | Buttons zu Story, Raid, Summon etc.                                       |

---

## ⚔️ 9. Tower-Defense Gameplay

| Element                | Status | Beschreibung                                                                 |
| ---------------------- | ------ | ---------------------------------------------------------------------------- |
| MatchServerHandler     | ✅      | Spielstart, Wellenstart, AutoWave, Seamless Restart, MatchResultLogik       |
| StartMatchScript       | ✅      | PlayButton1 für Matchstart, PlayButton2 für Folge-Wellen                     |
| WaveManager            | ✅      | Wellen-Generierung, AutoWave, Reset()-Methode eingebaut                      |
| EnemyManager           | ✅      | Gegnerverwaltung, ClearEnemies() zur Laufzeit entfernt                       |
| ShowPlayButton Remote  | ✅      | Client zeigt PlayButton2, wenn AutoWave deaktiviert ist                      |
| ShowStartButton Remote | ✅      | PlayButton1 kann vom Server erneut ausgelöst werden (z. B. bei Restart)       |
| RestartMode Toggle     | ✅      | Im Settings-Panel aktivierbar, Seamless Restart vermeidet Teleport           |
| MatchStateModule.Reset | ✅      | Setzt Player, Stage, Workspace (`Units`, `Enemies`) zurück                   |
| MatchResultAction      | ✅      | Steuerung für Buttons: Leave, Restart, Continue → verwendet StageTeleportService |
| PlacedUnitManager      | 🔁 entfällt | ClearUnits wurde direkt in MatchStateModule integriert                       |

---

## 🔄 10. Live-Sync

| Element                 | Status | Beschreibung                                                |
| ----------------------- | ------ | ----------------------------------------------------------- |
| ProfileSyncService      | ✅      | Methode `Send(key, data, player)` überträgt Settings        |
| ProfileChanged Events   | ✅      | Erkennt `RestartMode` und `AutoWaveEnabled`                 |
| SettingsClientScript    | ✅      | Sendet Toggles, zeigt aktuelle Werte bei OnOpen             |
| SetAutoWaveEnabled      | ✅      | Remote für AutoWave Umschaltung                             |
| SetSeamlessEnabled      | ✅      | Remote für RestartMode Toggle (true/false → "seamless"/"teleport") |

---

## 🔒 11. Persistent PlayerData

| Element             | Status | Beschreibung                                        |
| ------------------- | ------ | --------------------------------------------------- |
| ProfileStoreWrapper | ✅      | Verwaltet Settings + SelectedStage, Teleportziel etc. |
| PlayerDataTemplate  | ✅      | Settings-Block enthält `RestartMode`, `AutoWaveEnabled`, `Teleport.SelectedStage` |
| GetSettings Remote  | ✅      | Panel kann Profilwerte auch beim Öffnen aktiv abfragen      |

---

## ✅ 12. Abgeschlossene Tasks (Stand: 2025-07-29)

- ✅ RestartMode vollständig implementiert inkl. UI-Animation, Debounce, ServerSync
- ✅ MatchRestart mit Seamless-Logik korrekt umgesetzt (kein EnemyManager/UnitClear nötig)
- ✅ MatchResultButtons: Leave, Restart, Continue → mit StageTeleportService verdrahtet
- ✅ StageTeleportService als Modul eingeführt, ersetzt direkte Remote-Teleports im Match
- ✅ MatchServerHandler verwendet Teleport-Modul statt FireServer
- ✅ TeleportStageHandler.server.lua bleibt für Lobby-Remote `TeleportStageRequest` zuständig
- ✅ Client-Script `MainTeleportScript.client.lua` sendet korrekte Parameterstruktur (`string, number`)
- ✅ Getrennte Logik für Lobby- vs. Match-Teleport finalisiert

---

## 🔜 13. Nächste Schritte

- Stage 6 → NextMap-Fortsetzung mit `"Next"`-Button
- RewardPopupGui für Quests & Battlepass anzeigen nicht dringend
- TowerUpgrade & Sell-System fertigstellen (Refund, FX, Stats)
- TowerTargetMode (Dropdown: Nearest, First, Strongest etc.)
- StatusEffects (Burn, Freeze, Slow) über `Enemy.Status` + FX
- AirUnit-Support über neue Typen und TargetModes
- BossWave-Typen + Spezialverhalten definieren
- Countdown-Anzeige im UI ("Nächste Welle in ...")
- TooltipSystem refactoren (Traits, Rewards, Units)
- EXP & Battlepass korrekt mit Victory-Screen verrechnen


---

## 🧪 Known Issues (Live Client)

- ❌ TooltipSystem funktioniert derzeit nicht einheitlich (UI/FX) nicht dringend
- ❌ Kein RewardPopup bei Claims sichtbar nicht dringend
- ❌ EXP-Verteilung bei MatchVictory noch nicht implementiert

