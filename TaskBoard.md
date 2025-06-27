# 📋 Waveborn TD – TaskBoard (Stand: 2025-06-27)

---

## 🧱 1. Projektstruktur & Rojo Setup

| Element                      | Status | Beschreibung                                     |
| ---------------------------- | ------ | ----------------------------------------------- |
| default.project.json         | ✅      | Konfiguriert, Scripts korrekt zugewiesen        |
| ModuleScript-Struktur        | ✅      | Einzigartige Module pro Funktion                |
| Rojo-Setup                   | ✅      | Projektstruktur unter src/                      |
| Script-Format                | ✅      | Alle Dateien UTF-8, einheitliches Line-Ending   |

---

## 🧾 2. Technische Kernsysteme

| System          | Status | Beschreibung                                        |
| --------------- | ------ | --------------------------------------------------- |
| PanelManager    | ✅      | Panels mit OnOpen, Schließen, Debounce             |
| PanelDebounce   | ✅      | Klickschutz für schnelle Interaktionen             |
| GuiResolver     | ✅      | Einheitliche GUI-Zugriffe                          |
| ServerDebounce  | ✅      | Serverseitige Klick-/Spam-Prüfung                  |
| ProfileLoadedEvent | ✅   | Wird bei erfolgreichem Profil-Laden gefeuert       |
| ProfileChangedEvent | ✅  | Wird bei Änderungen wie Purchases oder BP gesendet |

---

## 🛒 3. Shop-System

| Element                | Status | Beschreibung                                         |
| ---------------------- | ------ | --------------------------------------------------- |
| ShopClientScript       | ✅      | Buttons, Limits, Live-Sync                          |
| ShopServerHandler      | ✅      | Limitierung, Validierung, Reward-Vergabe            |
| PremiumShopModule      | ✅      | Produktdaten (ProductId, Rewards, Limits)           |
| Purchases-System       | ✅      | One-Time & MaxPurchases live im Shop                |
| UI-Feedback            | ✅      | Buttons mit GLOBAL_PURCHASING_IMAGE                 |
| GetPurchases Remote    | ✅      | Liefert aktuelle Käufe beim Panel-Open für sofortige UI-Sperre |

---

## 🧩 4. Battlepass-System

| Element                | Status | Beschreibung                                       |
| ---------------------- | ------ | -------------------------------------------------- |
| BattlepassClientScript | ✅      | UI-Aufbau, Claim-Buttons, EXP-Header, Premiumkauf  |
| BattlepassServerHandler| ✅      | ClaimFree/ClaimPremium verarbeitet Claims          |
| BattlepassInfoProvider | ✅      | Leveldaten, EXP-Anforderungen, Seed-System         |
| ProfileStoreWrapper    | ✅      | Battlepass-Verwaltung im Profil, Resets bei Seed-Wechsel |
| PlayerDataTemplate     | ✅      | Battlepass-Felder: Seed, Level, EXP, Claimed etc.  |
| Premiumkauf (DevProduct) | ✅    | BattlepassPremium wird als DevProduct gekauft und setzt HasPremium |
| LiveSync BP/Purchases  | ✅      | Premium-Status und Purchases werden korrekt synchronisiert |

---

## 📦 5. Inventory-System

| Element               | Status | Beschreibung                                           |
| --------------------- | ------ | ------------------------------------------------------ |
| GrantRewards          | ✅      | Items & Units werden korrekt ins Inventar eingefügt    |
| InventoryClientScript | ✅      | Live-Sync & Anzeige der Items                         |
| ItemDataModule        | ✅      | Icons, Namen und Metadaten                           |

---

## 🧠 6. Units-System

| Element            | Status | Beschreibung                                      |
| ------------------ | ------ | ------------------------------------------------- |
| UnitInventoryGui   | ✅      | GridFrame, InfoPanel, SlotBar                     |
| EquipSystem        | ✅      | Equip/UnEquip mit UUID                           |
| UnitServerHandler  | ✅      | Entfernt – durch ProfileWrapper ersetzt          |
| ProfileStoreWrapper| ✅      | AddUnit/RemoveUnit/GetUnits                      |

---

## 📋 7. Quest-System

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

## 🔄 9. Live-Sync

| Element                 | Status | Beschreibung                                         |
| ----------------------- | ------ | --------------------------------------------------- |
| ProfileSyncService      | ✅      | Sorgt für Updates von Inventory, Purchases, Battlepass|
| LiveSync Battlepass     | ✅      | Änderungen werden direkt im UI aktualisiert         |
| LiveSync Purchases      | ✅      | Shop-Buttons sperren sich nach Kauf-Limit           |
| BattlepassClient        | ✅      | Premium-Status wird nach Kauf oder Claim sofort im UI angezeigt |

---

## 🔒 10. Persistent PlayerData

| Element             | Status | Beschreibung                                    |
| ------------------- | ------ | ----------------------------------------------- |
| ProfileStoreWrapper | ✅      | Speichert alle Daten via ProfileStore           |
| PlayerDataTemplate  | ✅      | Neue Battlepass-Struktur & Purchases            |
| AutoSave            | ✅      | Speichert Profile regelmäßig                   |

---

## ✅ 11. Abgeschlossene Tasks (Stand: 2025-06-27)

- Shop-System vollständig refactort mit Limits und One-Time-Produkten
- PremiumShopModule erstellt & integriert
- Battlepass-System zurück auf Einzelpass konsolidiert
- BattlepassClientScript refactort: UI, Claims, Premiumkauf, direkte Premium-Sync beim Öffnen
- BattlepassServerHandler aktualisiert für Einzelpass inkl. Premium-Status-Verwaltung
- ProfileWrapper: neue Methoden für Battlepass-Reset und Shop-Sync
- LiveSync für Purchases und Battlepass implementiert
- PlayerDataTemplate auf Battlepass & Purchases aktualisiert
- GetPurchases-Remote für sofortige UI-Aktualisierung beim Panel-Open hinzugefügt
- BattlepassPremium-Kauf als DevProduct umgesetzt, nicht mehr als Gamepass
- Kauf-Status wird jetzt korrekt bei Seed-Wechsel zurückgesetzt
- BattlepassClientScript prüft beim Öffnen Panel-Status live und aktualisiert korrekt
- StatusLabel des BattlepassClientScripts wird nach Claims oder Käufen direkt aktualisiert

---

## 🔜 12. Nächste Schritte

- RewardPopupGui fertigstellen für Quests & Battlepass
- ClaimAllButton für Battlepass implementieren
- CodesPanel refactorn (inkl. CodeRedeemHandler)
- TradeSystem nach Release der Kernelemente entwickeln
