# 📋 Waveborn TD – TaskBoard (Stand: 2025-08-01)

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
| GuiResolver          | ✅      | Einheitliche GUI-Zugriffe, PlaceId-basiertes Panel-Blocking |
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
| BattlepassClientScript | ✅      | UI-Aufbau, Claim-Buttons, EXP-Anzeige, Premiumkauf |
| BattlepassServerHandler| ✅      | ClaimFree/ClaimPremium verarbeitet Claims          |
| BattlepassInfoProvider | ✅      | Leveldaten, EXP-Anforderungen, Seed-System         |
| ProfileStoreWrapper    | ✅      | Verwaltung im Profil, Resets bei Seed-Wechsel      |
| PlayerDataTemplate     | ✅      | Battlepass-Datenstruktur inkl. Claimed/Level/Exp   |
| Premiumkauf (DevProduct) | ✅    | DevProduct aktiviert HasPremium                    |
| LiveSync BP/Purchases  | ✅      | Synchronisation bei Kauf und Statusänderung        |

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
| EquipSystem        | ✅      | Equip/UnEquip mit UUID, Schutz gegen Mehrfachausrüstung                     |
| UnitClientScript   | ✅      | Lädt Units, zeigt Equip-Status und Slots an                                 |
| ProfileStoreWrapper| ✅      | Add/Remove/Equip/Unequip inkl. Validierung                                  |
| EquipOrder Sort    | ✅      | Ausgerüstete Slots 1–6 oben in Liste                                        |
| EquipButtonFix     | ✅      | Buttons aktualisieren sich zuverlässig beim Öffnen                         |
| EquipInitSync      | ✅      | Initialstatus für Equip-Slots wird beim Profil-Load gesetzt                 |

---

## 🧩 7. Quest-System

| Element               | Status | Beschreibung                                    |
| --------------------- | ------ | ----------------------------------------------- |
| QuestClientScript     | ✅      | Fortschritt, Claim-Buttons, UI-Sync             |
| QuestServerHandler    | ✅      | ClaimAll verarbeitet Quests                     |
| ProgressTrackerService| ✅      | Einheitliches Tracking aller Questarten         |

---

## 🗺️ 8. Teleport-System

| Element                     | Status | Beschreibung                                                              |
| ---------------------------|--------|---------------------------------------------------------------------------|
| MapTeleportGui             | ✅     | GUI für Map-Auswahl & Stage-Wechsel                                       |
| TeleportStageHandler       | ✅     | ServerScript, verarbeitet `TeleportStageRequest`                          |
| StageTeleportService       | ✅     | Zentraler Service für Match-interne Teleports                             |
| FastTravelGui              | ✅     | Verlinkung zu Story, Raid, Summon                                         |

---

## ⚔️ 9. Tower-Defense Gameplay

| Element                | Status | Beschreibung                                                                 |
| ---------------------- | ------ | ---------------------------------------------------------------------------- |
| MatchServerHandler     | ✅      | Spielstart, Restart, Continue, Victory/Defeat, AutoWave                     |
| StartMatchScript       | ✅      | PlayButton1 für Start, PlayButton2 für NextWave                             |
| WaveManager            | ✅      | EnemyTracking, Victory/Defeat-Check, AutoWave, Spawn-Timing Fix             |
| EnemyManager           | ✅      | Gegnerbewegung, Pathing, BaseDamage, Reset bei Restart                      |
| ShowPlayButton Remote  | ✅      | PlayButton2 wird clientseitig angezeigt                                     |
| ShowStartButton Remote | ✅      | Startbutton kann serverseitig neu gesendet werden                           |
| RestartMode Toggle     | ✅      | Seamless Restart (ohne Teleport) oder Teleport-Variante per Setting        |
| MatchStateModule       | ✅      | Sieg/Niederlage-Logik, Cleanup, RewardDispatch                              |
| MatchResultAction      | ✅      | Buttons: Leave, Restart, Continue, Next                                     |
| TDEclipsium-Sync       | ✅      | Direktes Update und LiveSync beim Start                                     |
| VictoryFix             | ✅      | `humanoid.Died` ersetzt durch `HealthChanged + VictoryProcessed`            |
| SpawnTimingFix         | ✅      | Victory wird erst geprüft wenn `SpawnedEnemies == EnemiesToSpawn`          |
| SeamlessResetFix       | ✅      | `EnemyManager:Reset()` setzt `baseHP` und `matchLost` zurück                |

---

## 🔄 10. Live-Sync

| Element                 | Status | Beschreibung                                                |
| ----------------------- | ------ | ----------------------------------------------------------- |
| ProfileSyncService      | ✅      | `Send(player, key, data)` für alle Änderungen               |
| ProfileChanged Events   | ✅      | Events für Settings, Units, TDEclipsium                     |
| SettingsClientScript    | ✅      | Aktive Einstellungen abrufen & setzen                       |
| SetAutoWaveEnabled      | ✅      | Remote zur Umschaltung                                      |
| SetSeamlessEnabled      | ✅      | Umschaltung RestartMode                                     |

---

## 🔒 11. Persistent PlayerData

| Element             | Status | Beschreibung                                        |
| ------------------- | ------ | --------------------------------------------------- |
| ProfileStoreWrapper | ✅      | Settings, TeleportData, Units, Inventory            |
| PlayerDataTemplate  | ✅      | Settings enthalten: RestartMode, AutoWave, StageId  |
| GetSettings Remote  | ✅      | Client kann aktiven Status abfragen                 |

---

## ✅ 12. Abgeschlossene Tasks (Stand: 2025-08-01)

- ✅ VictoryTrigger durch SpawnTiming abgesichert (`SpawnedEnemies`, `EnemiesToSpawn`)
- ✅ DefeatFix beim Seamless Restart (Reset von `baseHP` + `matchLost`)
- ✅ MatchResultGui zeigt Rewards nur bei Victory
- ✅ Client & Server wurden gegen Doppel-Victory und verfrühte Checks abgesichert
- ✅ DamageSystem reduziert AliveEnemies + ruft `CheckVictoryCondition()` bei direktem Kill
- ✅ Reward-Logik für MatchVictory vollständig sichtbar (ProfileSync, MatchEndedEvent)

---

## 🔜 13. Nächste Schritte

- [ ] EXP & Battlepass korrekt mit Victory-Screen verrechnen
- [ ] TooltipSystem refactoren (Traits, Rewards, Units)
- [ ] RewardPopupGui für Quests & Battlepass anzeigen (optional)
- [ ] TowerUpgrade & Sell-System fertigstellen (Refund, FX, Stats)
- [ ] TowerTargetMode (Dropdown: Nearest, First, Strongest etc.)
- [ ] StatusEffects (Burn, Freeze, Slow) über `Enemy.Status` + FX
- [ ] AirUnit-Support über neue Typen und TargetModes
- [ ] BossWave-Typen + Spezialverhalten definieren
- [ ] Countdown-Anzeige im UI ("Nächste Welle in ...")

---

## 🧪 Known Issues (Live Client)

- ❌ TooltipSystem funktioniert derzeit nicht einheitlich (UI/FX)
- ❌ Kein RewardPopup bei QuestClaim sichtbar
- ❌ EXP-/BPEXP-Verteilung bei Victory noch nicht integriert
