# 🏠 Renomate

Ett projektledarverktyg för hemrenovering där du kan skapa byggprojekt och hantera uppgifter.

📖 **Ny här?** Börja med [SNABBSTART.md](./SNABBSTART.md) för snabb installation!

## Funktioner

- ✅ Skapa nya byggprojekt med namn och beskrivning
- ✅ Lägga till uppgifter till varje projekt
- ✅ Markera uppgifter som klara
- ✅ Ta bort projekt och uppgifter
- ✅ Se framsteg för varje projekt
- ✅ Data sparas i Supabase-databas (med fallback till localStorage)

## Installation

1. Installera beroenden:
```bash
npm install
```

2. Starta utvecklingsservern:
```bash
npm run dev
```

3. Öppna webbläsaren och gå till den URL som visas (vanligtvis http://localhost:5173)

## Bygga för produktion

```bash
npm run build
```

De byggda filerna kommer att finnas i `dist/` mappen.

## Teknologi

- React 18
- Vite
- Modern CSS med gradients och animations
- Supabase för datalagring
- LocalStorage som fallback

## Publicera på GitHub Pages

📖 **Se den detaljerade guiden:** [GITHUB_SETUP.md](./GITHUB_SETUP.md)

Projektet är konfigurerat för automatisk deployment till GitHub Pages. Efter att du har pushat koden till GitHub kommer appen automatiskt att byggas och deployas varje gång du gör ändringar.

**Snabbstart:**
1. Skapa repository på GitHub
2. Pusha koden (se GITHUB_SETUP.md)
3. Aktivera GitHub Pages i Settings
4. Lägg till Supabase secrets (viktigt!)
5. Vänta på automatisk deployment

**Viktigt:** `.cursor/mcp.json` är redan ignorerad i `.gitignore` för att skydda din Supabase access token.

## Supabase Setup

📖 **Vill du förstå vad Supabase är?** Läs [SUPABASE_FORKLARING.md](./SUPABASE_FORKLARING.md)

Projektet är nu integrerat med Supabase för datalagring. Följ dessa steg för att sätta upp:

### 1. Skapa Supabase-projekt

1. Gå till [Supabase](https://app.supabase.com) och skapa ett nytt projekt
2. Vänta tills projektet är klart (det tar några minuter)

### 2. Skapa databastabeller

1. Öppna SQL Editor i Supabase Dashboard
2. Kör SQL-schemat från `supabase/schema.sql`:
   - Detta skapar `projects` och `tasks` tabellerna
   - Sätter upp Row Level Security policies
   - Skapar index för bättre prestanda

### 3. Konfigurera miljövariabler

1. Kopiera `.env.example` till `.env`:
```bash
cp .env.example .env
```

2. Hämta dina Supabase-uppgifter:
   - Gå till Project Settings → API i Supabase Dashboard
   - Kopiera `Project URL` och `anon public` key

3. Uppdatera `.env` med dina värden:
```env
VITE_SUPABASE_URL=https://ditt-projekt.supabase.co
VITE_SUPABASE_ANON_KEY=ditt-anon-key
```

### 4. Installera beroenden och starta

```bash
npm install
npm run dev
```

### Fallback till localStorage

Om Supabase inte är konfigurerad eller om det uppstår fel, kommer applikationen automatiskt att använda localStorage som fallback. Detta gör att appen fungerar även utan Supabase-konfiguration.

### MCP Integration

Projektet är också konfigurerat för Supabase MCP (Model Context Protocol) i `.cursor/mcp.json`. Detta gör att du kan använda Supabase-funktioner direkt via Cursor AI.
