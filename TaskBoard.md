# 📋 Waveborn TD – TaskBoard (Stand: 2025-07-13)

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
| MatchServerHandler   | ✅      | Startet Waves über Remote, validiert Requests                   |
| StartMatchScript     | ✅      | Aktiviert Platzierung via Event, startet Countdown              |
| WaveManager          | ✅      | Definiert Waves, Delay & Spawns via EnemyManager                |
| EnemyManager         | ✅      | Spawnt Gegner mit Wegpunktlogik + DamageToBase                  |
| EnemyPath (Folder)   | ✅      | Wird korrekt gelesen, sortiert und verwendet                    |
| UnitModels           | ✅      | Vorschau + echte Platzierung nutzen dieselbe Quelle             |
| WalkArea-Blocking    | ✅      | Ghost wird rot, wenn BoundingBox WalkArea berührt               |
| PlacementCircle      | ✅      | Animierter Mesh-Kreis unter Ghost, wird via Assets geladen      |
| PlacementFilter      | ✅      | Raycast ignoriert Workspace.Units und WalkArea                  |

---

## 🔄 10. Live-Sync

| Element                 | Status | Beschreibung                                             |
| ----------------------- | ------ | ------------------------------------------------------- |
| ProfileSyncService      | ✅      | Sorgt für Updates von Inventory, Purchases, Battlepass |
| LiveSync Battlepass     | ✅      | Änderungen werden direkt im UI aktualisiert             |
| LiveSync Units          | ✅      | EquipSlots und Inventar synchron mit Client             |
| EquipSlots Sync         | ✅      | EquippedSlot1–6 werden automatisch bei Join + Equip gesetzt |
| ProfileChanged Events   | ✅      | Battlepass, Purchases, Units etc. aktualisieren dynamisch |

---

## 🔒 11. Persistent PlayerData

| Element             | Status | Beschreibung                                    |
| ------------------- | ------ | ----------------------------------------------- |
| ProfileStoreWrapper | ✅      | Speichert alle Daten via ProfileStore           |
| PlayerDataTemplate  | ✅      | Battlepass, Purchases, Units                    |
| AutoSave            | ✅      | Speichert Profile regelmäßig                    |
| MarkerSystem        | ✅      | Alle Systeme setzen Ready-Marker vor ProfilRelease |

---

## ✅ 12. Abgeschlossene Tasks (Stand: 2025-07-13)

- ✅ Platzierung prüft BoundingBox vs. WalkArea mit Blockierung
- ✅ PlacementCircle (MeshPart) wird unter GhostModel erstellt & gepulst
- ✅ Highlight-Farbe wird per Tween (Lerp) zwischen grün/rot animiert
- ✅ Raycast nutzt `Exclude` statt `Blacklist`, inkl. Units und Ghost
- ✅ Fehler „Modell fliegt zur Kamera“ dauerhaft behoben
- ✅ Unit-Modelle & Platzierungslogik jetzt in allen Maps funktionsfähig
- ✅ Workspace.Units als Blockierzone im Raycast & Platzierungsprüfung integriert

---

## 🔜 13. Nächste Schritte

- RewardPopupGui fertigstellen für Quests & Battlepass
- ClaimAllButton für Battlepass implementieren
- TooltipSystem global umsetzbar machen (Traits, Rewards, Items)
- Upgrade-/Sell-System für platzierte Tower
- Match-Ende Logik (Victory / Defeat)
- Wellen-Zähler + nächste Wave Trigger (Auto/Manuell)
- Region-Validierung für Platzierung (Whitelist-Zonen)
- DamageSystem für Tower/Units

---

## 🧪 Known Issues (Live Client)

- Stage-Auswahl im MapTeleport noch ohne Back/Close-Logik
- Kein Popup für Rewards bei Claims sichtbar
- Tooltip-System placeholderhaft oder leer

---

**Q1:** Wie könnte das Damage-System für platzierte Units aufgebaut sein?  
**Q2:** Wie strukturieren wir die Upgrades & Tower-Stats (z. B. Damage, Range, SPA)?  
**Q3:** Welche Events und UI-Komponenten braucht das Match-Ende (Victory/Defeat)?
