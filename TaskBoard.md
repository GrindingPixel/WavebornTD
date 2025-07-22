# 📋 Waveborn TD – TaskBoard (Stand: 2025-07-21)

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

| Element            | Status | Beschreibung                                     |
| ------------------ | ------ | ----------------------------------------------- |
| MapTeleportGui     | ✅      | Welten/Stages mit Rewards                       |
| TeleportStageHandler | ✅    | Verarbeitet Stage-Teleports                     |
| FastTravelGui      | ✅      | Buttons zu Story, Raid, Summon etc.             |

---

## ⚔️ 9. Tower-Defense Gameplay

| Element              | Status | Beschreibung                                                     |
| -------------------- | ------ | ---------------------------------------------------------------- |
| UnitPlacer           | ✅      | Raycast-Platzierung mit Vorschau, Highlight, Puls-Kreis, BoundingBox |
| PlaceTowerHandler    | ✅      | Serverseitige Validierung, Clone + Spawn, Collision-Check       |
| MatchServerHandler   | ✅      | Startet Waves über Remote, initialisiert MatchState             |
| StartMatchScript     | ✅      | Aktiviert Platzierung, zeigt Countdown, gibt Startgeld          |
| WaveManager          | ✅      | Startet Waves, generiert Daten, triggert Folge-Welle nach letztem Spawn |
| EnemyManager         | ✅      | Spawnt Gegner, End-Touch-Logik, HealthBar, keine Wellenkontrolle mehr |
| EnemyPath            | ✅      | Enthält Start, Ende + nummerierte Punkte, wird sortiert         |
| EnemyDamageToBase    | ✅      | Wenn Gegner „Ende“ berühren → HP-Abzug, Trigger via Part        |
| Enemy CollisionGroup | ✅      | Gegner können durch Spieler laufen via „Enemy“-Group            |
| Player CollisionGroup| ✅      | Spieler automatisch „Players“-Group zugewiesen                  |
| Units CollisionGroup | ✅      | Platzierte Türme erhalten automatisch „Units“-Gruppe            |
| DamageSystem         | ✅      | Türme greifen automatisch Gegner an, geben TDEclipsium          |
| UnitTargetingModule  | ✅      | Unterstützt Nearest, First, Strongest                           |
| CombatStatsProvider  | ✅      | Liefert Damage, Range, SPA aus UnitDataModule                   |
| CurrencySystem TD    | ✅      | TDEclipsium wird gesetzt bei Start, entfernt bei MatchEnd       |
| SetTDEclipsium Remote| ✅      | Remotesteuert Startgeld-Vergabe                                 |
| MoneyPanel           | ✅      | Zeigt TDEclipsium-Wert bei LiveSync korrekt an                  |

---

## 🔄 10. Live-Sync

| Element                 | Status | Beschreibung                                             |
| ----------------------- | ------ | ------------------------------------------------------- |
| ProfileSyncService      | ✅      | Sorgt für Updates von Inventory, Purchases, Battlepass |
| LiveSync Battlepass     | ✅      | Änderungen werden direkt im UI aktualisiert             |
| LiveSync Units          | ✅      | EquipSlots und Inventar synchron mit Client             |
| EquipSlots Sync         | ✅      | EquippedSlot1–6 werden automatisch bei Join + Equip gesetzt |
| ProfileChanged Events   | ✅      | Battlepass, Units, TDEclipsium etc. werden dynamisch aktualisiert |

---

## 🔒 11. Persistent PlayerData

| Element             | Status | Beschreibung                                    |
| ------------------- | ------ | ----------------------------------------------- |
| ProfileStoreWrapper | ✅      | Speichert alle Daten via ProfileStore           |
| PlayerDataTemplate  | ✅      | Battlepass, Purchases, Units, TDEclipsium       |
| AutoSave            | ✅      | Speichert Profile regelmäßig                    |
| MarkerSystem        | ✅      | Alle Systeme setzen Ready-Marker vor ProfilRelease |

---

## ✅ 12. Abgeschlossene Tasks (Stand: 2025-07-21)

- ✅ Platzierung prüft BoundingBox vs. WalkArea mit Blockierung
- ✅ CurrencySystem (TDEclipsium) für Match implementiert
- ✅ TDEclipsium wird korrekt gesetzt, Live-Sync funktioniert
- ✅ Gegner geben TDEclipsium + EXP, Clientanzeige aktualisiert sich direkt
- ✅ MatchEnd entfernt TDEclipsium aus Profil
- ✅ StartMatchScript migriert CurrencyDisplay + verbessert
- ✅ Remote `SetTDEclipsium` eingeführt für saubere Trennung vom WaveStart
- ✅ MoneyPanel nur sichtbar bei gültigem Wert (ProfileChanged)
- ✅ AutoWave vollständig entfernt – Wellen starten nun 5s nach dem letzten Spawn
- ✅ WaveManager kontrolliert allein den Wellenfluss
- ✅ EnemyManager wurde von Wellenverantwortung entkoppelt

---

## 🔜 13. Nächste Schritte

- RewardPopupGui fertigstellen für Quests & Battlepass
- ClaimAllButton für Battlepass implementieren
- TooltipSystem global umsetzbar machen (Traits, Rewards, Items)
- Upgrade-/Sell-System für platzierte Tower
- Match-Ende Logik (Victory / Defeat)
- Wellen-Zähler + GUI-Anzeige der aktuellen Welle
- Countdown-Anzeige „Next Wave in...“ im Client
- Region-Validierung für Platzierung (Whitelist-Zonen)
- StatusEffect-System (Burn, Slow etc.)
- AirUnit-Support (Type = Flyer)
- Boss-Type Logik (mehr HP, andere Farbe, z. B. via Type = Boss)
- Tower-Zielmodus durch Spieler änderbar (Dropdown/Buttons pro Tower)

---

## 🧪 Known Issues (Live Client)

- Stage-Auswahl im MapTeleport noch ohne Back/Close-Logik
- Kein Popup für Rewards bei Claims sichtbar
- Tooltip-System placeholderhaft oder leer

---

**Q1:** Wie sollte die Upgrade-Logik bei Türmen mit Goldkosten und Visual Feedback gestaltet werden?  
**Q2:** Soll das Tower-Zielsystem auch Immunitäten oder Fly/OnlyGround berücksichtigen?  
**Q3:** Wie könnte das StatusEffect-System effizient per Module erweitert werden?
