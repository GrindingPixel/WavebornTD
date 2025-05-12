local NewsModule = {}

NewsModule.NewsData = {
	NewsItem1 = {
		title = "Waveborn TD - Closed Beta Start",
		body = "Die Closed Beta beginnt jetzt! Sei dabei und sammle exklusive Belohnungen.",
		image = ""
	},
	NewsItem2 = {
		title = "Waveborn TD - Release 1.0",
		body = "Die Vollversion ist da mit neuen Maps, Einheiten und mehr!✔️",
		image = ""
	},
	NewsItem3 = {
		title = "Waveborn TD - mongo",
		body = "Die Open Beta wurde gestartet – lade deine Freunde ein!/n",
		image = "rbxassetid://130155373081470"
	}
}

return NewsModule


--[[

📖 WAVE TD - NEWSMODULE FORMAT GUIDE

Dieser Guide erklärt dir alle wichtigen Tricks & Möglichkeiten, wie du die News-Texte gestalten kannst.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 1️⃣ Zeilenumbrüche

Roblox **unterstützt KEINE `/n`**, aber **`\n` funktioniert** innerhalb von Strings.

🔹 Beispiel:
body = "Willkommen zur Beta!\n\n- Neue Maps\n- Neue Units"

Ergebnis:
Willkommen zur Beta!

- Neue Maps
- Neue Units

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 2️⃣ Aufzählungen & Listen

Du kannst **Unicode-Symbole** für schöne Listen nutzen:

- ➔ `•` (Bullet)
- ➔ `-` (Minus)
- ➔ `⭐` (Sterne)
- ➔ `✔️` (Checkmark)
- ➔ `❌` (X)

🔹 Beispiel:
body = "Änderungen:\n• Neue Tower\n• Neue Maps\n✔️ Bugfixes"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 3️⃣ Emojis & Symbole

Du kannst alle **Unicode-Emojis** verwenden (die Roblox erlaubt).  
➡️ Aber: **Nicht alle Emojis werden auf allen Geräten angezeigt!**

🔹 Beispiel:
body = "🔥 Hotfix Update\n🎯 Neue Event-Bosse\n🏆 Belohnungen"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 4️⃣ Einfache Texttricks

➡️ Roblox **unterstützt KEINE:**
- Kein HTML (z.B. <b> <i>)
- Kein Markdown (z.B. **bold** oder _italic_)
- Keine Farbcodes innerhalb des Textes

‼️ **Wenn du Farbe willst, musst du mehrere Labels nutzen** (z.B. Titel & Body in unterschiedlichen Farben).

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 5️⃣ LANGE Texte & Automatischer Umbruch

Wenn du viel Text hast:
- Stelle im `NewsBody` sicher:
  ➔ `TextWrapped = true`
  ➔ `TextYAlignment = Top`
  ➔ und ggf. die Größe so anpassen, dass der Text komplett sichtbar ist.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 6️⃣ Bilder einfügen (ImageLabels)

➡️ **Roblox TextLabels unterstützen KEINE Bilder inline!**  
Das heißt: Du kannst keine Bilder **innerhalb des Textes** anzeigen lassen.

⭐ **Lösung:**
- Baue **neben das NewsBody-Label** ein oder mehrere **ImageLabels**.
- Im `NewsModule` fügst du z.B. einen neuen Key `image` ein:

Beispiel:

NewsItem1 = {
    title = "Beta Release",
    body = "Willkommen zur Open Beta!\nSichere dir exklusive Belohnungen.",
    image = "rbxassetid://123456789"  -- Dein Thumbnail / Screenshot
}

➡️ Im Script kannst du dann folgendes tun:
```lua
if newsData.image then
    NewsImage.Image = newsData.image
    NewsImage.Visible = true
else
    NewsImage.Visible = false
end
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 7️⃣ Farben & Styles (Workaround)

Willst du mehrere Farben? Dann kannst du mehrere Labels stapeln.
Beispiel:

Ein Label für Titel (z.B. Neonblau)

Ein Label für Body (z.B. Weiß)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 8️⃣ Mehrere Absätze (Spacing)

Wenn du Abstand brauchst, nutze mehrere \n:

body = "Patch Notes:\n\n\n- Fix 1\n- Fix 2"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ FAZIT:
Was geht:
✔️ Zeilenumbrüche (\n)
✔️ Unicode-Symbole & Emojis
✔️ Bilder über separate ImageLabels
✔️ Einfache Farbtrennung durch mehrere Labels

Was NICHT geht:
🚫 HTML
🚫 Markdown
🚫 Inline-Farben oder Inline-Bilder

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔥 BONUS: Beispiel für dein `NewsModule`

Hier ist ein Beispiel, wie du das dann nutzen kannst:

```lua
local NewsModule = {}

NewsModule.NewsData = {
    NewsItem1 = {
        title = "🔥 Waveborn TD - Closed Beta Start",
        body = "Willkommen zur Closed Beta!\n\nFeatures:\n• 5 neue Maps\n• 3 neue Units\n\n🏆 Exklusive Belohnungen warten!",
        image = "rbxassetid://1234567890"
    },
    NewsItem2 = {
        title = "⚔️ Großes Balancing-Update",
        body = "Wir haben alle Tower neu gebalanced!\n\nÄnderungen:\n✔️ Tower A: +20% DMG\n✔️ Tower B: -10% Kosten\n\nDanke für euer Feedback!",
        image = "rbxassetid://0987654321"
    }
}

return NewsModule


--]]