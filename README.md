# 🏠 Renomate

En modern, komplett plattform för hantering av renoveringsprojekt. Perfekt för husägare som vill ha full kontroll över sina byggprojekt med ett professionellt verktyg.

📖 **Ny här?** Börja med [SNABBSTART.md](./SNABBSTART.md) för snabb installation!

## ✨ Funktioner

### 🏗️ Projekthantering
- ✅ Skapa och hantera flera renoveringsprojekt
- ✅ Organisera projekt i rum och områden
- ✅ Spåra projektstatus och framsteg
- ✅ Översiktlig dashboard med nyckeltal

### 📋 Uppgiftshantering
- ✅ Skapa uppgifter för varje rum/projekt
- ✅ Markera uppgifter som klara
- ✅ Prioritera och organisera arbetsflöde
- ✅ Detaljerad uppgiftsinformation med beskrivningar

### 📐 Space Planner / Floor Map
- ✅ Rita och designa rumsplaner visuellt
- ✅ 3D preview av dina planer
- ✅ Mät och dimensionera rum
- ✅ Lägg till möbler och inredning från symbolbibliotek
- ✅ Snap-to-grid och smart snapping
- ✅ Undo/Redo funktionalitet
- ✅ Elevation view för väggvyer
- ✅ Export och spara planer

### 💰 Budgethantering
- ✅ Budgetkalkylator per rum/projekt
- ✅ Spåra kostnader och utgifter
- ✅ Kostnadscentra för olika kategorier
- ✅ Visuell budgetöversikt

### 🛒 Material- & Inköpshantering
- ✅ Materiallista per rum
- ✅ Skapa inköpsförfrågningar
- ✅ Spåra materialstatus
- ✅ Godkänn/avvisa inköp

### 👥 Teamsamarbete
- ✅ Bjud in teammedlemmar via e-post
- ✅ Rollbaserad åtkomst
- ✅ Dela projekt med entreprenörer och familj
- ✅ Realtidssamarbete

### 🌍 Flerspråksstöd (i18n)
- ✅ Svenska (sv)
- ✅ Engelska (en)
- ✅ Tyska (de)
- ✅ Spanska (es)
- ✅ Franska (fr)
- ✅ Automatisk språkdetektering
- ✅ Användarspecifik språkinställning

### 🎨 Modern UI/UX
- ✅ Responsiv design (mobil, tablet, desktop)
- ✅ Dark mode stöd
- ✅ Elegant Shadcn UI-komponenter
- ✅ Smooth animationer och transitions
- ✅ Tillgänglig och användarvänlig

### 🔐 Autentisering & Säkerhet
- ✅ Säker användarautentisering via Supabase
- ✅ Row Level Security (RLS)
- ✅ Privata projekt per användare
- ✅ Delningsfunktionalitet med behörighetskontroll

## 🚀 Snabbstart

### Installation

1. **Klona projektet och installera beroenden:**
```bash
cd /Users/calpa/Desktop/Renomate
npm install
```

2. **Konfigurera Supabase (se nedan)**

3. **Starta utvecklingsservern:**
```bash
npm run dev
```

4. **Öppna webbläsaren:**
   Gå till [http://localhost:5173](http://localhost:5173)

## 🗄️ Supabase Setup

📖 **Vill du förstå vad Supabase är?** Läs [SUPABASE_FORKLARING.md](./SUPABASE_FORKLARING.md)

### 1. Skapa Supabase-projekt
1. Gå till [Supabase](https://app.supabase.com) och skapa ett nytt projekt
2. Vänta tills projektet är klart (tar några minuter)

### 2. Skapa databastabeller
1. Öppna SQL Editor i Supabase Dashboard
2. Kör migrations från `supabase/migrations/`
3. Detta skapar alla nödvändiga tabeller:
   - `profiles` - Användarprofiler
   - `projects` - Renoveringsprojekt
   - `project_members` - Teammedlemskap
   - `rooms` - Rum per projekt
   - `tasks` - Uppgifter per rum
   - `materials` - Material per rum
   - `purchase_requests` - Inköpsförfrågningar
   - `floor_plans` - Ritningar och planer

### 3. Konfigurera miljövariabler
Din `.env.local` är redan konfigurerad men om du behöver uppdatera:

```env
VITE_SUPABASE_URL=https://ditt-projekt.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=ditt-anon-key
```

### 4. Aktivera Authentication
1. Gå till Authentication → Settings i Supabase Dashboard
2. Aktivera Email provider
3. Konfigurera eventuella OAuth providers (Google, GitHub, etc.)

## 📦 Byggkommandon

```bash
# Utveckling
npm run dev

# Bygga för produktion
npm run build

# Bygga för utveckling
npm run build:dev

# Förhandsgranska produktionsbygg
npm run preview

# Linting
npm run lint
```

## 🛠️ Teknologi Stack

### Frontend
- **React 18.3** - UI-ramverk
- **TypeScript** - Typsäkerhet
- **Vite 5** - Build tool & dev server
- **React Router 6** - Routing
- **TailwindCSS 3** - Styling
- **Shadcn UI** - UI-komponentbibliotek
- **Lucide React** - Ikoner

### State Management & Data
- **TanStack Query (React Query)** - Server state management
- **Zustand** - Client state management
- **React Hook Form** - Formulärhantering
- **Zod** - Schema validation

### Backend & Database
- **Supabase** - Backend-as-a-Service
  - PostgreSQL databas
  - Autentisering
  - Row Level Security
  - Realtime subscriptions
  - Edge Functions

### Internationalisering
- **i18next** - i18n-ramverk
- **react-i18next** - React-integration
- **i18next-browser-languagedetector** - Språkdetektering

### Visualisering & Canvas
- **Fabric.js** - Canvas manipulation för floor planner
- **React Three Fiber** - 3D rendering
- **@react-three/drei** - 3D helpers

### UI Components
- **Radix UI** - Headless UI-komponenter
- **Recharts** - Diagram och grafer
- **Sonner** - Toast notifications
- **cmdk** - Command palette
- **date-fns** - Datumhantering

## 📁 Projektstruktur

```
Renomate/
├── src/
│   ├── components/
│   │   ├── ui/              # Shadcn UI-komponenter
│   │   ├── floormap/        # Floor planner komponenter
│   │   ├── project/         # Projektspecifika komponenter
│   │   ├── AppHeader.tsx    # Huvudnavigering
│   │   ├── Footer.tsx       # Sidfot
│   │   └── LanguageSelector.tsx
│   ├── pages/               # Route-sidor
│   │   ├── Index.tsx        # Startsida
│   │   ├── Auth.tsx         # Inloggning/registrering
│   │   ├── Projects.tsx     # Projektlista
│   │   ├── ProjectDetail.tsx # Projektdetaljer
│   │   ├── Profile.tsx      # Användarprofil
│   │   └── ...
│   ├── hooks/               # Custom React hooks
│   ├── integrations/        # Externa integrationer
│   │   └── supabase/        # Supabase-klient och typer
│   ├── i18n/                # Internationalisering
│   │   ├── config.ts
│   │   └── locales/         # Översättningar
│   ├── lib/                 # Utility-funktioner
│   ├── App.tsx              # Huvudapp-komponent
│   └── main.tsx             # Entry point
├── public/                  # Statiska filer
├── supabase/
│   ├── migrations/          # Databasmigrationer
│   └── functions/           # Edge Functions
└── ...config files
```

## 🚀 Publicera på GitHub Pages

📖 **Se den detaljerade guiden:** [GITHUB_SETUP.md](./GITHUB_SETUP.md)

Projektet är konfigurerat för automatisk deployment till GitHub Pages:

1. Skapa repository på GitHub
2. Pusha koden
3. Aktivera GitHub Pages i Settings
4. Lägg till Supabase secrets
5. Vänta på automatisk deployment

## 🤝 Bidra

Bidrag är välkomna! Öppna gärna issues eller pull requests.

## 📄 Licens

Detta projekt är licensierat under MIT-licensen.

## 🔗 Länkar

- [Supabase Documentation](https://supabase.com/docs)
- [React Documentation](https://react.dev)
- [TailwindCSS Documentation](https://tailwindcss.com)
- [Shadcn UI](https://ui.shadcn.com)

---

**Skapad med ❤️ för att göra renoveringar enklare**
