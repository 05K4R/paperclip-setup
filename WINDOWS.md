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

### 4. Install and set up Paperclip

In PowerShell, run:

```powershell
npx paperclipai onboard
```

Follow the on-screen instructions to complete the setup.

---

## Starting Paperclip after a restart

Open **PowerShell** and run:

```powershell
npx paperclipai start
```

Then open http://localhost:3100 in your browser.
