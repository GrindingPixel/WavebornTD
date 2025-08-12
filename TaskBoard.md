# 📋 Waveborn TD – TaskBoard (Stand: 2025-08-12)

---

## 🧱 1. Projektstruktur & Rojo Setup

| Element                      | Status | Beschreibung                                     |
| ---------------------------- | ------ | ----------------------------------------------- |
| default.project.json         | ✅      | Konfiguriert, Scripts korrekt zugewiesen        |
| story_X.project.json         | ✅      | Story-spezifische `.project.json` Templates mit modularer GUI-Einbindung |
| ModuleScript-Struktur        | ✅      | Einzigartige Module pro Funktion                |
| Rojo-Setup                   | ✅      | Projektstruktur unter `src/`                    |

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
| ProfileSyncService   | ✅      | LiveSync von `Settings`, `Eclipsium`, `TDEclipsium`, `Units` |
| ProfileReadyService  | ✅      | Blockiert GUI-Init bis Profil geladen, Integration mit MoneyLobbyGui und anderen Lobby-GUIs |
| GetProfile Remote    | ✅      | RemoteFunction für atomaren Profil-Snapshot (Eclipsium, Gems) |

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
| LiveSync Scrolls      | ✅      | SummonScroll-Bestand wird hier bei Änderungen aktualisiert |

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
| QuestDebugScript      | ✅      | P-Taste simuliert Fortschritt im Dev-Modus      |
| VictoryRewardService  | 🆕      | Modul für EXP- und Battlepass-EXP-Vergabe bei Victory, Livesync an Client |

---

## 🗺️ 8. Teleport-System

| Element                     | Status | Beschreibung                                                              |
| ---------------------------|--------|---------------------------------------------------------------------------|
| MapTeleportGui             | ✅     | GUI für Map-Auswahl & Stage-Wechsel                                       |
| TeleportStageHandler       | ✅     | ServerScript, verarbeitet `TeleportStageRequest`                          |
| StageTeleportService       | ✅     | Zentraler Service für Match-interne Teleports                             |
| FastTravelGui              | ✅     | Verlinkung zu Story, Raid, Summon                                         |
| TeleportPortalHandler      | ✅     | Erweiterung: `"ReturnToSummon"`-Command für CloseButton SummonPanel       |

---

## ⚔️ 9. Tower-Defense Gameplay

| Element                | Status | Beschreibung                                                                 |
| ---------------------- | ------ | ---------------------------------------------------------------------------- |
| MatchServerHandler     | ✅      | Spielstart, Restart, Continue, Victory/Defeat, AutoWave                     |
| StartMatchScript       | ✅      | PlayButton1 für Start, PlayButton2 für NextWave                             |
| WaveManager            | ✅      | Harte Abbruchsicherung bei `Defeat`, AutoWave-Spawn nur nach Spawnende      |
| EnemyManager           | ✅      | Multi-Path-Support (EnemyPathX), Auto-Damage, ReachedEnd-Fix                |
| ShowPlayButton Remote  | ✅      | PlayButton2 wird clientseitig angezeigt                                     |
| ShowStartButton Remote | ✅      | Startbutton kann serverseitig neu gesendet werden                           |
| RestartMode Toggle     | ✅      | Seamless Restart (ohne Teleport) oder Teleport-Variante per Setting        |
| MatchStateModule       | ✅      | `IsMatchOver()` hinzugefügt, Reset-Versorgung erweitert                     |
| MatchResultAction      | ✅      | Buttons: Leave, Restart, Continue, Next                                     |
| Currency-Sync          | ✅      | GetProfile RemoteFunction liefert Eclipsium & Gems zuverlässig beim Join   |
| VictoryFix             | ✅      | `HealthChanged` statt `Died`, inkl. `VictoryProcessed`                      |
| SpawnTimingFix         | ✅      | Victory nur geprüft, wenn alle Gegner gespawnt sind                         |
| SeamlessResetFix       | ✅      | `EnemyManager:Reset()` + WaveManager:SetAutoWaveEnabled                     |
| MultiWaveSpawnFix      | ✅      | `WaveManager` bricht SpawnQueue sofort bei MatchEnd ab                      |

---

## 🎯 10. Summon-System

| Element                    | Status     | Beschreibung                                                                 |
| -------------------------- | ---------- | --------------------------------------------------------------------------- |
| SummonClientScript         | ✅          | Öffnet Panel bei Touch SummonCircle, Buttons für Single/Multi Summon        |
| SummonPreviewModule        | ✅          | Zeigt 1× 5★ + 2× 4★ Units im GUI-Preview                                    |
| SummonServiceModule        | ✅          | Verarbeitet Summons, fügt Units ins Inventar, prüft & bucht Scrolls ab      |
| SummonPoolModule           | ✅          | Dynamische Poolgenerierung, stündliche Rotation, enthält Kostendefinition   |
| SummonRemoteHandler        | ✅          | Leitet Requests, liefert Pool an Client (GetSummonPool)                     |
| SpriteAnimator             | ✅          | Animierter GUI-Hintergrund (SummonOverlay)                                  |
| TeleportReturn Integration | ✅          | CloseButton kann `"ReturnToSummon"`-Teleport auslösen                       |
| Kamera & RenderFix         | ✅          | Ausrichtung, Transparenz, Schattenfix für Preview-Modelle                   |
| Scroll-Anzeige             | ✅          | Live-Anzeige `SummonsLeft` im SummonGui                                     |

---

## 🔄 11. Live-Sync

| Element                 | Status | Beschreibung                                                |
| ----------------------- | ------ | ----------------------------------------------------------- |
| ProfileSyncService      | ✅      | `Send(player, key, data)` für alle Änderungen               |
| ProfileChanged Events   | ✅      | Events für Settings, Units, Eclipsium, TDEclipsium, Inventory|
| SettingsClientScript    | ✅      | Aktive Einstellungen abrufen & setzen                       |
| SetAutoWaveEnabled      | ✅      | Remote zur Umschaltung                                      |
| SetSeamlessEnabled      | ✅      | Umschaltung RestartMode                                     |

---

## 🔒 12. Persistent PlayerData

| Element             | Status | Beschreibung                                        |
| ------------------- | ------ | --------------------------------------------------- |
| ProfileStoreWrapper | ✅      | Settings, TeleportData, Units, Inventory (inkl. typed Inventory-System), Currency-Methoden |
| PlayerDataTemplate  | ✅      | Settings enthalten: RestartMode, AutoWave, StageId  |
| GetSettings Remote  | ✅      | Client kann aktiven Status abfragen                 |

---

## ✅ 13. Abgeschlossene Tasks (Stand: 2025-08-12)

- ✅ Multi-EnemyPathX Support mit globalem Ende-Punkt
- ✅ Hard-Abbruch bei MatchEnd integriert (SpawnStop, AutoWaveCancel, DamageBlock)
- ✅ MatchStateModule:IsMatchOver eingeführt
- ✅ WaveManager Spawn-Schleifen durch MatchEnd sicher beendet
- ✅ `EnemyManager:SpawnEnemy` prüft Matchstatus
- ✅ Touch-Events blockieren bei `matchEnded = true`
- ✅ Summon-GUI funktionsfähig mit animiertem Hintergrund und Preview-Units
- ✅ Teleport `"ReturnToSummon"` in CloseButton integriert
- ✅ Kamera- und Renderfix für Preview-Models
- ✅ Summon-Kostenprüfung & Inventarabbuchung für `SummonScroll_Common`
- ✅ Live-Anzeige der Scroll-Anzahl im SummonPanel (`SummonsLeft`)
- ✅ ProfileReadyService blockiert GUI-Init bis Profil geladen
- ✅ GetProfile RemoteFunction implementiert und im Client eingebunden
- ✅ Currency-Anzeige in MoneyLobbyGui zeigt Werte zuverlässig ab erstem Join

---

## 🔜 14. Nächste Schritte (not now)

- [ ] EXP & Battlepass korrekt mit Victory-Screen verrechnen (VictoryRewardService → MatchServerHandler)
- [ ] TooltipSystem refactoren (Traits, Rewards, Units)
- [ ] RewardPopupGui für Quests & Battlepass anzeigen
- [ ] TowerUpgrade & Sell-System fertigstellen
- [ ] TowerTargetMode (Dropdown)
- [ ] StatusEffects (Burn, Freeze, Slow)
- [ ] AirUnit-Support
- [ ] BossWave-Typen + Spezialverhalten
- [ ] Countdown-Anzeige im UI
- [ ] Garantiesystem / Pity für Summons
- [ ] RateUp-Hervorhebung im Summon-Preview
- [ ] Erweiterter GetProfile-Snapshot für alle UI-Elemente

---

## 🧪 Known Issues (Live Client) (not now)

- ❌ TooltipSystem uneinheitlich (UI/FX)
- ❌ Kein RewardPopup bei QuestClaim sichtbar
- ❌ EXP-/BPEXP-Verteilung bei Victory noch nicht integriert
- ⚠️ GUI-Sync via Rojo kann Assets verlieren (SlotImage etc.)
- ❌ Preview-Slots leer, wenn `GetSummonPool` nicht antwortet
