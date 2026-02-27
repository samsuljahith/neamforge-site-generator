# 🔨 NeamForge Static Site Generator

A **Forge Agent** built with [Neam](https://github.com/neam-lang/neam) that takes a JSON site specification and iteratively generates a complete, production-quality static website through an automated build-verify loop.

> Built as an end-to-end demonstration of NeamForge capabilities including the verify callback, checkpoint system, iterative generation, workspace management, and trait implementations.

---

## ✨ Features

| Feature | Implementation |
|---|---|
| **Spec-Driven Generation** | Define your site in a JSON file — agent builds it automatically |
| **Build-Verify Loop** | Each page is generated then validated before proceeding |
| **Git Checkpoints** | Every verified task creates a git commit — full history of generation |
| **HTML Validation** | Skills that check DOCTYPE, meta tags, structure, responsiveness |
| **Multi-Page Support** | Handles any number of pages with shared navigation and styling |
| **Responsive CSS** | Mobile-first approach with media queries |
| **Example Specs** | Includes 2 ready-to-use site specs (agency portfolio + dev blog) |
| **Preview Server** | Built-in Nginx config for instant local preview |
| **100% Local** | Ollama + llama3.1 — no API keys, no cloud costs |
| **Reproducible** | Docker Compose or shell script — clone and run |

---

## 📁 Project Structure

```
neamforge-site-generator/
├── site_generator.neam       # Main Neam source — forge agent, skills, verify callback
├── site-spec.json            # Default site spec (CloudPeak Studios — agency portfolio)
├── examples/
│   └── devbrew-blog.json     # Alternative spec (DevBrew — developer blog)
├── run.sh                    # One-command local runner (compile + execute)
├── docker-compose.yml        # Docker setup: Ollama + Forge + Nginx preview
├── Dockerfile                # Multi-stage build with git for checkpoints
├── nginx.conf                # Preview server config
├── .env.example              # Environment variable template
├── .gitignore
└── README.md
```

### Generated Output (after running)

```
workspace/
├── site-spec.json            # Copy of the input spec
├── plan.txt                  # Auto-generated task plan (one task per line)
├── progress.jsonl            # Completed task log
├── learnings.jsonl           # Agent learnings during generation
├── .git/                     # Git history of each checkpoint
└── output/                   # ← THE GENERATED WEBSITE
    ├── index.html
    ├── services.html
    ├── portfolio.html
    ├── about.html
    ├── contact.html
    ├── 404.html
    └── css/
        └── style.css
```

---

## 🚀 Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) & Docker Compose
- **OR** local install of:
  - [Neam compiler & runtime](https://github.com/neam-lang/neam) (`neamc`, `neam-forge`)
  - [Ollama](https://ollama.com/) (for local LLM)
  - Git

### Option A: Docker (Recommended — Fully Reproducible)

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USERNAME/neamforge-site-generator.git
cd neamforge-site-generator

# 2. Start everything (Ollama + Forge + Preview server)
docker compose up --build

# First run pulls llama3.1 (~4.7 GB). Subsequent runs are fast.
# The forge agent will start generating the site automatically.

# 3. Watch the generation progress in the terminal output.
#    Each verified task is logged with iteration number.

# 4. Once complete, preview the site:
#    Open http://localhost:3000 in your browser

# 5. To generate a DIFFERENT site:
docker compose run -v ./examples/devbrew-blog.json:/home/neam/site-spec.json site-generator
```

### Option B: Local (Shell Script)

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USERNAME/neamforge-site-generator.git
cd neamforge-site-generator

# 2. Ensure Ollama is running with the model
ollama serve &
ollama pull llama3.1

# 3. Run with the default spec
chmod +x run.sh
./run.sh

# OR run with a custom spec
./run.sh examples/devbrew-blog.json

# 4. Preview the generated site
cd workspace/output
python3 -m http.server 3000
# Open http://localhost:3000
```

### Option C: Manual Steps

```bash
# Compile
neamc site_generator.neam -o site_generator.neamb

# Setup workspace
mkdir -p workspace/output
cp site-spec.json workspace/site-spec.json
cd workspace && git init && git config user.email "forge@neam" && git config user.name "NeamForge" && cd ..

# Run forge
neam-forge --agent site_generator.neamb --name site_generator --workspace ./workspace --verbose
```

---

## 📝 How It Works

The Forge Agent follows a strict **build-verify loop**:

```
┌──────────────────────────────────────────────────────┐
│                  FORGE LOOP                          │
│                                                      │
│  ┌─────────┐    ┌──────────┐    ┌────────────────┐  │
│  │  Read    │───▶│ Generate │───▶│    Verify      │  │
│  │  Plan    │    │ Next Task│    │   Callback     │  │
│  └─────────┘    └──────────┘    └───────┬────────┘  │
│       ▲                                  │           │
│       │              ┌───────────────────┤           │
│       │              ▼                   ▼           │
│       │        ┌──────────┐       ┌──────────┐      │
│       │        │  Retry   │       │   Done   │      │
│       └────────│(feedback)│       │(complete)│      │
│                └──────────┘       └──────────┘      │
│                                                      │
│  Each verified task → git commit (checkpoint)        │
└──────────────────────────────────────────────────────┘
```

### Iteration Breakdown

| Iteration | Action |
|---|---|
| 1 | Read `site-spec.json`, create `plan.txt` with one task per line |
| 2 | Generate `css/style.css` (shared stylesheet based on theme config) |
| 3 | Generate `index.html` (home page with hero, features, stats) |
| 4 | Generate `services.html` |
| 5 | Generate `portfolio.html` |
| 6 | Generate `about.html` |
| 7 | Generate `contact.html` |
| 8 | Generate `404.html` |
| 9+ | Fix any validation issues found by the verify callback |
| Final | All files validated → `Done("Site generation complete!")` |

---

## 🎨 Creating Your Own Site Spec

Create a JSON file following this structure:

```json
{
  "site_name": "My Site",
  "tagline": "A cool website",
  "theme": {
    "primary_color": "#3B82F6",
    "background": "#FFFFFF",
    "text_color": "#1F2937",
    "font_heading": "Georgia, serif",
    "font_body": "system-ui, sans-serif"
  },
  "navigation": [
    { "label": "Home", "href": "index.html" },
    { "label": "About", "href": "about.html" }
  ],
  "pages": [
    {
      "slug": "index",
      "title": "Home",
      "sections": [
        {
          "type": "hero",
          "headline": "Welcome!",
          "subheadline": "This is my site."
        }
      ]
    }
  ],
  "footer": {
    "copyright": "© 2026 My Site"
  }
}
```

### Supported Section Types

| Type | Description |
|---|---|
| `hero` | Full-width hero with headline, subheadline, CTA button |
| `features` | Grid of icon + title + description cards |
| `stats` | Row of number + label pairs |
| `page_header` | Page title with subtitle |
| `cards` | Grid of content cards |
| `project_grid` | Portfolio-style project cards with tags |
| `text_block` | Paragraph content |
| `team` | Team member cards |
| `values` | Value proposition cards |
| `contact_info` | Contact details display |
| `contact_form` | HTML form (mailto: for static sites) |

---

## 🏗️ Neam Concepts Demonstrated

| Concept | Where in Code |
|---|---|
| `forge agent` declaration | `site_generator.neam` main block |
| `verify` callback function | `verify_site()` — returns Done/Retry/Abort |
| `checkpoint: "git"` | Git commit per verified task |
| `loop` config (max_iterations, cost, tokens) | Agent config block |
| `skill` with `params` shorthand | `write_file`, `validate_html`, etc. |
| `workspace_read` / `workspace_write` | Inside skill implementations |
| `exec()` for shell commands | File listing, directory creation |
| `impl Sandboxable` trait | Filesystem + network restrictions |
| `impl Monitorable` trait | Progress anomaly detection |
| VerifyResult: `Done`, `Retry`, `Abort` | verify_site callback return values |
| Plan file (one task per line) | Auto-generated by agent in iteration 1 |
| Progress tracking (JSONL) | `progress.jsonl` updated per task |
| Learnings (JSONL) | `learnings.jsonl` for agent insights |

---

## 📊 Viewing Generation History

Since the agent uses `checkpoint: "git"`, you can view the entire generation history:

```bash
# View commit log
cd workspace
git log --oneline

# Example output:
# a3f2d1c Verified: Generate 404.html
# 8b1e4a9 Verified: Generate contact.html
# 2c7f6d3 Verified: Generate about.html
# f1a9b2e Verified: Generate portfolio.html
# 6d4c8a1 Verified: Generate services.html
# 9e2b5f7 Verified: Generate index.html
# 3a8d1c4 Verified: Generate css/style.css
# 7f6e2b9 Verified: Create plan from site-spec.json

# View what changed in a specific step
git show 9e2b5f7

# Diff between two steps
git diff 3a8d1c4 9e2b5f7
```

---

## 🔧 Configuration

| Parameter | Default | Description |
|---|---|---|
| `model` | `llama3.1` | Change to any Ollama model |
| `temperature` | `0.4` | Higher = more creative HTML/CSS |
| `max_iterations` | `30` | Generous limit for large sites |
| `max_cost` | `0.0` | Ollama is free |
| `checkpoint` | `"git"` | `"git"`, `"snapshot"`, or `"none"` |

---

## 📄 License

MIT License — see [LICENSE](LICENSE).

---

## 🙏 Acknowledgments

- **Neam Language** — [neam-lang/neam](https://github.com/neam-lang/neam)
- **Ollama** — [ollama.com](https://ollama.com)
- Built as an internship project demonstrating NeamForge agent capabilities.
