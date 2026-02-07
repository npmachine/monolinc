# Monolinc

**Monolinc** is a next-generation communication platform for the AI era. It connects users, AI, and various platforms (Web, Mobile, Desktop) into a single, unified flow, aiming for a boundary-free Interface.

## Tech Stack

### Core & Backend
- **Language:** Elixir 1.19+
- **Framework:** Phoenix Framework 1.8+
- **Real-time Engine:** Phoenix LiveView
- **Database:** SQLite3 (via Ecto)
  - *Configuration:* `WAL` mode enabled, `synchronous = normal`
  - *Structure:* Maintain a single-file DB structure

### Frontend & UI
- **Styling:** Tailwind CSS 4.x
- **Component Library:** DaisyUI 5
- **Icons:** Heroicons (via Phoenix components)

### Cross-Platform Strategy (One Codebase)
- **Web:** Standard Phoenix LiveView (Responsive, PWA Support)
- **Desktop (Win/Mac/Linux):** Tauri v2 (Wrap the LiveView web app)
- **Mobile (iOS/Android):** PWA (Progressive Web App)
