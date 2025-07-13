# 📋 Waveborn TD – TaskBoard (Stand: 2025-07-09)

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
| ProfileSyncService      | ✅      | Sorgt für Updates von Inventory, Purchases, Battlepass |
| LiveSync Battlepass     | ✅      | Änderungen werden direkt im UI aktualisiert         |
| LiveSync Purchases      | ✅      | Shop-Buttons sperren sich nach Kauf-Limit           |
| ProfileChanged Events   | ✅      | Battlepass, Purchases, Units etc. aktualisieren dynamisch |
| EquipSlots Sync         | ✅      | EquippedSlot1–6 werden automatisch bei Join + Equip gesetzt |

---

## 🔒 10. Persistent PlayerData

| Element             | Status | Beschreibung                                    |
| ------------------- | ------ | ----------------------------------------------- |
| ProfileStoreWrapper | ✅      | Speichert alle Daten via ProfileStore           |
| PlayerDataTemplate  | ✅      | Battlepass, Purchases, Units                    |
| AutoSave            | ✅      | Speichert Profile regelmäßig                   |
| MarkerSystem        | ✅      | Alle Systeme setzen Ready-Marker vor ProfilRelease |

---

## ✅ 11. Abgeschlossene Tasks (Stand: 2025-07-09)

- EquipSystem blockiert jetzt mehrfaches Ausrüsten derselben UUID
- EquipSlots werden direkt beim Join korrekt gesetzt (EquippedSlot1–6)
- Equip-Button im Inventory zeigt jetzt korrekt UNEQUIP, wenn Unit bereits aktiv
- UnitClientScript aktualisiert mit neuer `isUnitEquipped()`-Logik
- Unequip-Funktion über leeren Equip-Call ("" als UUID) umgesetzt
- Inventory zeigt immer zuerst die ausgerüsteten Units (Slots 1–6)
- ProfileWrapper:EquipUnit() vollständig überarbeitet (inkl. Slot-Reset, UUID-Prüfung)
- Join-Bug gefixt: Equip-Slots und Buttons sind beim Öffnen direkt korrekt
- Kein mehrfaches LoadUnits mehr nötig

---

## 🔜 12. Nächste Schritte

- RewardPopupGui fertigstellen für Quests & Battlepass
- ClaimAllButton für Battlepass implementieren
- Globales TooltipSystem (z. B. für Traits, Rewards, Quests, Items)
- TradeSystem nach Release der Kernelemente entwickeln

---

## 🧪 Known Issues (Live Client)

- Shop CancelBuy: UI bleibt sichtbar bei Abbruch
- Equip von Units wird manchmal visuell nicht aktualisiert (nur bei sehr hoher Latenz)
- Stage-Auswahl im MapTeleport noch ohne Back/Close-Logik
- Kein Popup für Rewards bei Claims sichtbar
- Tooltip-System placeholderhaft oder leer
