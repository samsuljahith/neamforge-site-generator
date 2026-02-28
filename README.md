# 🔨 NeamForge Static Site Generator

**An AI agent that reads a JSON spec and autonomously builds a complete, validated static website — powered by the Neam programming language.**

---

## 📌 What Is This Project?

This project is an **autonomous static website generator** built using the **Forge Agent** architecture from the **Neam programming language**. You give it a JSON file describing your website (pages, theme, content), and it **iteratively generates every HTML page and CSS file** through an automated build-verify loop — validating each file before moving on, and creating a git commit at every checkpoint.

It runs **100% locally** using Ollama (no paid APIs), and produces a ready-to-deploy static site from a single JSON specification.

---

## 🌍 Real-World Problem It Solves

### The Problem

Creating static websites is one of the most common development tasks, yet it remains surprisingly painful:

- **Non-developers** (freelancers, small business owners, designers) need websites but can't code HTML/CSS. Website builders like Wix/Squarespace cost **$15–$50/month** and produce bloated, slow sites.
- **Developers** spend hours writing repetitive boilerplate — doctype declarations, meta tags, responsive CSS, navigation, footers — for every page. A 5-page website easily takes **8–16 hours** of manual work.
- **AI code generators** (ChatGPT, Copilot) can write HTML, but they generate one file at a time with **no consistency** between pages — different styles, broken navigation, missing meta tags.
- **No quality assurance** — generated code often has missing doctypes, broken links, non-responsive layouts, and accessibility issues that only surface after deployment.

### How This Project Solves It

The NeamForge Site Generator takes a fundamentally different approach — it uses an **iterative build-verify loop** where every generated file is validated before proceeding:

| Problem | Our Solution |
|---|---|
| Non-developers can't code | **JSON spec** — describe your site in plain structured data, no HTML knowledge needed |
| Hours of repetitive boilerplate | **AI generates everything** — complete HTML5, responsive CSS, navigation, footers |
| Inconsistent multi-page output | **Shared stylesheet + plan** — agent follows a task plan ensuring all pages match |
| No quality assurance | **Verify callback** — validates DOCTYPE, meta tags, structure, responsiveness after every file |
| Can't track what happened | **Git checkpoints** — every verified task creates a git commit, full audit trail |
| Expensive cloud APIs | **Ollama + llama3.1** — runs 100% free on local hardware |
| No recovery from errors | **Retry loop** — verify callback sends feedback, agent fixes issues automatically |
| One-off generation | **Spec-driven** — change the JSON, regenerate. Ship 2 example specs included |

The result: you write a ~100 line JSON spec, run one command, and get a **complete, validated, multi-page static website** with full git history showing how it was built — in minutes, for $0.

---

## 🎯 What I Built

### Core Agent (`site_generator.neam` — 358 lines)

A single Neam source file that defines the complete generation pipeline:

**1. Six Purpose-Built Skills**

| Skill | What It Does | Why It's Needed |
|---|---|---|
| `write_file` | Write HTML/CSS/JS files to output directory | Core generation — creates all site files |
| `read_file` | Read existing files for review/editing | Enables iteration — agent can check and fix its own work |
| `list_files` | List all generated files | Progress tracking — agent knows what exists |
| `validate_html` | Check HTML for DOCTYPE, meta tags, structure | Quality gate — catches 8 common HTML issues |
| `validate_css` | Check CSS for valid rule blocks, minimum size | Quality gate — ensures CSS isn't empty/broken |
| `read_site_spec` | Load and parse the site specification JSON | Entry point — reads what to generate |

**2. HTML Validation (8 Checks)**

The `validate_html` skill checks every generated page for:
1. `<!DOCTYPE html>` declaration present
2. `<html>` tag exists
3. `<head>` section exists
4. `<title>` tag exists
5. `<body>` tag exists
6. `</html>` closing tag present
7. `<meta charset>` for character encoding
8. `<meta name="viewport">` for mobile responsiveness

**3. Verify Callback (`verify_site`)**

The core of the Forge pattern — called after every iteration:

```
verify_site(output) {
  1. Check if plan.txt exists → Retry("create the plan first")
  2. Count completed tasks in progress.jsonl
  3. If all tasks done:
     - Find all .html files in output/
     - Validate each has <html> tag and minimum length
     - Check CSS files exist
     - All valid? → Done("Site generation complete!")
     - Issues found? → Retry("fix these: ...")
  4. If tasks remain → Retry("Progress: 3/7. Continue next task.")
}
```

This creates a self-correcting loop: the agent generates → verify checks → if issues, agent gets feedback and fixes → verify again → eventually all tasks pass.

**4. Forge Agent Configuration**
```neam
forge agent site_generator {
  provider:    "ollama"
  model:       "llama3.1"
  temperature: 0.4
  verify:      verify_site           // callback after each iteration
  checkpoint:  "git"                 // commit per verified task
  loop: {
    max_iterations: 30               // generous for multi-page sites
    max_cost:       0.0              // Ollama is free!
    max_tokens:     1000000
  }
}
```

Key Forge concepts:
- **Fresh context per iteration** — no accumulated history (unlike Claw), agent gets clean context each time
- **Plan file** — one task per line, agent creates this in iteration 1
- **Progress file** — JSONL log of completed tasks
- **Learnings file** — JSONL log of agent insights during generation
- **VerifyResult** — `Done(message)`, `Retry(feedback)`, or `Abort(reason)`

**5. Two Trait Implementations**
- **Sandboxable** — strict mode: no network access, workspace-only filesystem, only `mkdir`/`find`/`ls` commands allowed, 1GB memory cap
- **Monitorable** — detects when agent gets stuck (no progress in 5 iterations triggers alert)

### Site Specifications

**Default: CloudPeak Studios (Agency Portfolio)**
- 5 content pages: Home (hero + features + stats), Services (4 service cards), Portfolio (6 project cards with tags), About (story + team + values), Contact (info + form)
- Complete theme config: colors, fonts, border radius
- Navigation, footer with social links, copyright
- ~150 lines of JSON

**Example: DevBrew Blog (Developer Blog)**
- 3 content pages: Home (hero + topics), Articles (3 article cards), About
- Different theme (green palette, serif headings)
- Simpler structure, demonstrates spec flexibility
- ~80 lines of JSON

### Docker Setup

- **Dockerfile** — multi-stage build with git installed (for checkpoints)
- **docker-compose.yml** — Ollama + Forge agent + Nginx preview server
- **nginx.conf** — serves generated site at `localhost:3000` with proper routing and caching
- **run.sh** — one-command local runner with pre-flight checks

---

## 🏗️ Architecture

### Build-Verify Loop

```
                    ┌─────────────────────────────────────────────┐
                    │              FORGE LOOP                      │
                    │                                             │
  site-spec.json   │  ┌──────────┐    ┌──────────────────────┐  │
  ────────────────▶│  │ Iteration│    │    🦙 Ollama         │  │
                    │  │    1     │───▶│    llama3.1          │  │
                    │  │ (Plan)   │    │  Generate next task   │  │
                    │  └──────────┘    └──────────┬───────────┘  │
                    │                             │              │
                    │                   ┌─────────▼──────────┐   │
                    │                   │      Skills        │   │
                    │                   │  write / validate  │   │
                    │                   └─────────┬──────────┘   │
                    │                             │              │
                    │                   ┌─────────▼──────────┐   │
                    │            ┌──────│   verify_site()    │   │
                    │            │      └──────┬─────────────┘   │
                    │            │             │                 │
                    │     Retry(feedback)    Done!               │
                    │            │             │                 │
                    │            ▼             ▼                 │
                    │     ┌──────────┐  ┌──────────────┐        │
                    │     │ Next     │  │ Git Commit   │        │
                    │     │Iteration │  │ + Complete   │        │
                    │     └──────────┘  └──────────────┘        │
                    └─────────────────────────────────────────────┘
```

### Iteration Breakdown (Typical 7-Page Site)

| Iteration | What Happens | Verify Result |
|---|---|---|
| 1 | Read `site-spec.json`, create `plan.txt` with 7 tasks | Retry("0/7 tasks done") |
| 2 | Generate `css/style.css` (shared responsive stylesheet) | Retry("1/7 done") → git commit |
| 3 | Generate `index.html` (home page with hero, features, stats) | Retry("2/7 done") → git commit |
| 4 | Generate `services.html` | Retry("3/7 done") → git commit |
| 5 | Generate `portfolio.html` | Retry("4/7 done") → git commit |
| 6 | Generate `about.html` | Retry("5/7 done") → git commit |
| 7 | Generate `contact.html` | Retry("6/7 done") → git commit |
| 8 | Generate `404.html` | All tasks done → final validation |
| 9+ | Fix any validation issues (missing meta tags, etc.) | Retry with specific feedback |
| Final | All HTML validated, CSS exists | **Done!** → git commit |

### Generated Output Structure

```
workspace/
├── site-spec.json            # Input specification
├── plan.txt                  # Auto-generated task list
├── progress.jsonl            # Completed task log
├── learnings.jsonl           # Agent insights
├── .git/                     # Full generation history
└── output/                   # THE GENERATED WEBSITE
    ├── index.html            # Home page
    ├── services.html         # Services page
    ├── portfolio.html        # Portfolio page
    ├── about.html            # About page
    ├── contact.html          # Contact page
    ├── 404.html              # Error page
    └── css/
        └── style.css         # Shared responsive stylesheet
```

---

## 💡 How The Forge Pattern Differs From Claw

Understanding why this project uses a **Forge Agent** instead of a **Claw Agent** is key:

| Aspect | Claw Agent (Project 1) | Forge Agent (This Project) |
|---|---|---|
| **Purpose** | Ongoing conversation | Complete a build task |
| **Context** | Accumulates history across turns | Fresh context every iteration |
| **Session** | Persistent (JSONL, compaction) | None — each iteration is independent |
| **Channels** | CLI, HTTP (for user interaction) | None — runs autonomously |
| **Verify** | Not available (would cause compile error) | Required — the core mechanism |
| **Checkpoint** | Not available | Git commits per verified task |
| **Loop** | Runs until user stops talking | Runs until Done/Abort/budget exhausted |
| **Memory** | Semantic memory persists across sessions | Learnings file, plan file |
| **Use Case** | Support bot, assistant, chatbot | Code generator, builder, pipeline |

The Forge pattern is purpose-built for **tasks with a defined end state** — in our case, "all pages generated and validated."

---

## 🚀 Quick Start

### Option A: Docker (Recommended — Fully Reproducible)

```bash
git clone https://github.com/YOUR_USERNAME/neamforge-site-generator.git
cd neamforge-site-generator

# Build and run (Ollama + Forge + Preview server)
docker compose up --build

# First run pulls llama3.1 (~4.7 GB) — takes 5-10 minutes
# Agent starts generating automatically. Watch the terminal for progress.

# Once complete, preview the site:
# Open http://localhost:3000

# Generate a different site:
docker compose run \
  -v ./examples/devbrew-blog.json:/home/neam/site-spec.json \
  site-generator
```

### Option B: Local (Shell Script)

```bash
git clone https://github.com/YOUR_USERNAME/neamforge-site-generator.git
cd neamforge-site-generator

# Ensure Ollama is running
ollama serve &
ollama pull llama3.1

# Generate with default spec (CloudPeak Studios)
chmod +x run.sh
./run.sh

# OR generate with a different spec
./run.sh examples/devbrew-blog.json

# Preview the result
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

# Run
neam-forge --agent site_generator.neamb --name site_generator --workspace ./workspace --verbose
```

---

## 📸 Viewing Generation History (Git Checkpoints)

Since the agent uses `checkpoint: "git"`, every verified task is a git commit:

```bash
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

# See what was generated in a specific step
git show 9e2b5f7

# Diff between any two steps
git diff 3a8d1c4 9e2b5f7

# Rollback to a previous state
git checkout 6d4c8a1
```

This is a powerful feature for **debugging**, **auditing**, and **understanding the agent's decision-making process**.

---

## 🎨 Creating Your Own Site Spec

Create a JSON file following this structure:

```json
{
  "site_name": "My Website",
  "tagline": "A short description",
  "theme": {
    "primary_color": "#3B82F6",
    "secondary_color": "#8B5CF6",
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
        { "type": "hero", "headline": "Welcome!", "subheadline": "..." },
        { "type": "features", "title": "Why Us", "items": [...] }
      ]
    }
  ],
  "footer": { "copyright": "© 2026 My Website" }
}
```

### Supported Section Types

| Section Type | Description | Key Fields |
|---|---|---|
| `hero` | Full-width banner with CTA | headline, subheadline, cta_text, cta_link |
| `features` | Grid of icon cards | title, items: [{icon, title, description}] |
| `stats` | Number showcase row | items: [{number, label}] |
| `page_header` | Page title + subtitle | title, subtitle |
| `cards` | Content card grid | items: [{title, description, price}] |
| `project_grid` | Portfolio cards with tags | items: [{title, category, description, tags}] |
| `text_block` | Paragraph content | content (string) |
| `team` | Team member cards | title, members: [{name, role}] |
| `values` | Value proposition list | title, items: [{title, description}] |
| `contact_info` | Contact details | email, phone, address, hours |
| `contact_form` | HTML form | fields: ["name", "email", ...] |

Then run:
```bash
./run.sh my-custom-spec.json
```

---

## 📁 Project Structure

```
neamforge-site-generator/
├── site_generator.neam       # Complete agent source (358 lines)
│                               ├── 6 skill definitions
│                               ├── verify_site() callback
│                               ├── Forge agent declaration
│                               ├── 2 trait implementations
│                               └── Entry point
├── site-spec.json            # Default spec (CloudPeak Studios — 5 pages)
├── examples/
│   └── devbrew-blog.json     # Alternative spec (DevBrew Blog — 3 pages)
├── run.sh                    # One-command local runner with pre-flight checks
├── docker-compose.yml        # Ollama + Forge + Nginx preview
├── Dockerfile                # Multi-stage build with git
├── nginx.conf                # Preview server config
├── .env.example              # Environment template
├── .gitignore
└── README.md
```

---

## 🧠 Neam Language Concepts Demonstrated

| Neam Concept | What It Is | Where Used |
|---|---|---|
| `forge agent` | Iterative build-verify agent type | Main agent declaration |
| `verify` callback | Function called after each iteration | `verify_site()` — progress check + HTML validation |
| `Done(message)` | Signal that the task is complete | When all pages validated |
| `Retry(feedback)` | Signal to try again with feedback | When tasks remain or issues found |
| `Abort(reason)` | Signal to stop permanently | Available for critical failures |
| `checkpoint: "git"` | Git commit per verified task | Full generation audit trail |
| `loop` config | Iteration/cost/token limits | max_iterations: 30, max_cost: 0.0 |
| `skill` with `params` shorthand | Agent-callable tools | 6 skills: write, read, list, validate, spec |
| `workspace` | Persistent file storage | Generated site output + tracking files |
| `workspace_read`/`write` | Native workspace I/O | File generation and reading |
| `exec()` | Shell command execution | `mkdir -p`, `find` for file listing |
| `file_read_string()` | Raw file reading | Verify callback reads generated HTML |
| `json_parse`/`json_stringify` | JSON handling | Site spec parsing |
| `impl Sandboxable` | Security sandbox config | No network, workspace-only, safe commands only |
| `impl Monitorable` | Anomaly detection | Stuck detection (5 iterations without progress) |
| `plan.txt` | One task per line | Created by agent in iteration 1 |
| `progress.jsonl` | Completed task log | Updated after each task |
| `learnings.jsonl` | Agent insight log | Written when agent discovers useful patterns |

---

## 🔄 Loop Outcomes

The Forge loop terminates in one of four ways:

| Outcome | When It Happens | Exit Code |
|---|---|---|
| ✅ **Completed** | `verify_site()` returns `Done(...)` — all pages valid | 0 |
| ⏱️ **MaxIterations** | Hit 30 iteration limit without completing | 1 |
| 🚫 **Aborted** | `verify_site()` returns `Abort(...)` — unrecoverable error | 1 |
| 💸 **BudgetExhausted** | Token limit (1M) reached | 1 |

Since we use Ollama (free), `max_cost: 0.0` means cost-based termination never triggers.

---

## ⚙️ Configuration Reference

| Parameter | Value | Why |
|---|---|---|
| `provider` | `ollama` | Free, local, no API keys |
| `model` | `llama3.1` | Best open model for structured code generation |
| `temperature` | `0.4` | Slightly creative for varied HTML/CSS output |
| `max_iterations` | `30` | Generous for 5–10 page sites plus fix iterations |
| `max_cost` | `0.0` | Ollama is free — no cost tracking needed |
| `max_tokens` | `1000000` | ~1M tokens for full site generation |
| `checkpoint` | `"git"` | Full audit trail of generation steps |

---

## 📄 License

MIT License

---

## 🙏 Acknowledgments

- **Neam Language** — [neam-lang/neam](https://github.com/neam-lang/neam)
- **Ollama** — [ollama.com](https://ollama.com) for free local LLM inference
- **Mentor** — Praveen Govindaraj for project guidance
