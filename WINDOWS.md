# Installing Paperclip on Windows

## Installation

### 1. Enable Developer Mode

Go to **Settings** → **System** → **For Developers** and toggle **Developer Mode** on.

### 2. Allow PowerShell scripts

Open **PowerShell** and run:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

### 3. Install Node.js

Download and install the **LTS** version from https://nodejs.org. Use the default settings in the installer.

Close and reopen PowerShell after installing so it picks up the new `node` and `npm` commands.

### 4. Install Claude Code

In PowerShell, run:

```powershell
npm install -g @anthropic-ai/claude-code
```

Then log in:

```powershell
claude login
```

This opens a browser window — follow the instructions to authenticate.

### 5. Install and set up Paperclip

In PowerShell, run:

```powershell
npx paperclipai onboard
```

Follow the on-screen instructions to complete the setup.

### 5b. Set up with an existing company export

If you have an exported company file and want to import it instead of starting fresh:

1. Run the onboard step above to get Paperclip installed and running.
2. Open http://localhost:3100 in your browser.
3. Import the company file through the UI.

---

## Starting Paperclip after a restart

Open **PowerShell** and run:

```powershell
npx paperclipai start
```

Then open http://localhost:3100 in your browser.

---

## Useful concepts

If you're new to AI agents, here are some key things to know.

### What is an agent?

An agent is an AI that can do work on its own. Instead of just answering a question, it can read files, write code, search the web, and take actions step by step to complete a task. In Paperclip, agents carry out tasks you assign to them.

### How to communicate with agents

Write clear, specific instructions — like you would in an email to a colleague. For example:

- **Too vague:** "Fix the website"
- **Better:** "The contact form on the About page doesn't send emails. Look at the form handler and fix it."

You don't need to use any special syntax or programming language. Just write in plain language. The more context you give, the better the result.

### Skills

A skill is a reusable set of instructions that tells an agent how to perform a specific type of task. Think of it like a template — instead of explaining the same process every time, you define it once as a skill and the agent can use it repeatedly. For example, a skill could describe how to write a blog post in your company's tone of voice, or how to review a document following a specific checklist.

To create a skill, you can simply ask Paperclip to make one for you. For example:

> "Create a skill called 'Spotify Weekly Releases' that searches for the latest new album and single releases on Spotify this week, summarizes them in a short list with artist name, title, and release date, and writes the summary in Swedish."

Once the skill exists, you can run it any time with a short prompt like:

> "Run the Spotify Weekly Releases skill for this week."

This way you don't have to re-explain the task every time — the skill remembers how to do it.

### Prompts vs instructions

- **Prompt:** What you type when you give an agent a task. This is the specific thing you want done right now.
- **Instructions:** Background information that the agent always has access to, like company guidelines, tone of voice, or standard processes. These are configured in Paperclip and apply to every task automatically.

### Tokens and context

Agents read and generate text in units called **tokens** (roughly one token per word). Each agent has a **context window** — a limit on how much text it can process at once. If a task involves very long documents, the agent may need to work through them in parts.

### Language — Swedish or English?

AI agents understand both Swedish and English well. You can write your prompts and instructions in whichever language you prefer — the agent will respond in the same language.

However, a few tips:

- **Write prompts in the language you want the output in.** If you want a Swedish result, write your prompt in Swedish. If you write in English, the agent will typically respond in English.
- **Instructions and skills** should also be written in the language you want the agent to use. If your company's output should be in Swedish, write your skills and company instructions in Swedish.
- **Be explicit when needed.** If you mix languages or want to be sure, you can always add "Svara på svenska" or "Skriv resultatet på svenska" to your prompt.
- **Technical terms** can be kept in English if that feels more natural (e.g. "release", "playlist"). The agent handles mixed language fine.
