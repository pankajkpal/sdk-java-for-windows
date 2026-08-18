# Windows SDK-Style Java Version Manager

A robust, SDKMAN!-inspired Java version manager built natively for Windows.

This tool allows you to detect existing Java/JDK installations, switch between them temporarily in the current PowerShell session, and set persistent default versions at the User or Machine scope.

> **Note:** This manager *never* downloads or installs Java automatically. It acts strictly as a manager for JDKs already present on your machine.
>
> 🤖 **AI Disclaimer:** This software and documentation were generated using Artificial Intelligence (Google Antigravity & GitHub Copilot).

---

## 🚀 Feature Set & Usage

| Command | Description |
| :--- | :--- |
| `sdk rescan java` | Discover installed JDKs across common system directories |
| `sdk list java` | List all discovered JDK installations |
| `sdk use java <id>` | Use specified JDK temporarily in current session (PowerShell & CMD) |
| `sdk default java <id> [--admin]` | Set default JDK at User scope (or Machine scope with `--admin`) |
| `sdk current java` | Show active JDK details and `JAVA_HOME` path |
| `sdk env [init\|clear]` | Manage project-specific `.sdkmanrc` file (PowerShell & CMD) |
| `sdk doctor` | Run environment diagnostics to check configuration |

---

## 💻 Command Details & Examples

### 1. Discover JDKs
```cmd
sdk rescan java
```
Scans standard Windows installation paths (e.g. `C:\Program Files\Java`, `Eclipse Adoptium`, `Zulu`, `Corretto`, `Microsoft`) for valid JDKs containing both `java.exe` and `javac.exe`.

### 2. List Installed JDKs
```cmd
sdk list java
```
Lists all discovered JDKs with their ID, version, vendor, and installation path. The active JDK in the current session is marked with `>`.

### 3. Switch Java for Current Session
```cmd
sdk use java 17.0.15-tem
```
Temporarily updates `JAVA_HOME` and `PATH` for the current PowerShell session.

### 4. Set Default Java Version
```cmd
sdk default java 25.0.2-tem
sdk default java 21.0.4-tem --admin
```
* **User Default:** Sets persistent `JAVA_HOME` and `JAVA_HOME_<major>` environment variables for the current user.
* **Machine Default (`--admin`):** Prompts for UAC Administrator elevation if needed and sets environment variables at the Machine scope.

### 5. Show Current Active Java
```cmd
sdk current java
```
Displays active `JAVA_HOME` and prints `java -version` output.

### 6. Project-Specific Environments (`.sdkmanrc`)
```cmd
sdk env init     # Creates a .sdkmanrc file in current directory with current JDK ID
sdk env          # Switches session to the JDK specified in local .sdkmanrc
sdk env clear    # Restores session to the User-level default JDK
```

### 7. Diagnostics
```cmd
sdk doctor
```
Checks profile integration, `JAVA_HOME` validity, catalog existence, and `PATH` cleanliness.

---

## 📦 Installation

### Option 1: One-Liner Install (Recommended)

Open **PowerShell** and run:

```powershell
irm https://raw.githubusercontent.com/pankajkpal/sdk-java-for-windows/main/install-online.ps1 | iex
```

This downloads everything, installs to `C:\Tools\WindowsSdkJava`, and configures your PATH and PowerShell profile automatically.

### Option 2: Download the Installer

1. Go to the [**Releases**](https://github.com/pankajkpal/sdk-java-for-windows/releases) page.
2. Download the latest `WindowsSdkJava-Setup-x.x.x.exe`.
3. Run the installer — choose **"Install for all users"** (requires Admin) or **"Just for me"**.
4. Restart your terminal.

### Option 3: Manual Install (Clone & Run)

1. **Clone** the repository:
   ```powershell
   git clone https://github.com/pankajkpal/sdk-java-for-windows.git
   cd sdk-java-for-windows
   ```
2. **Run the install script**:
   ```powershell
   # For Current User (Default):
   .\install.ps1

   # For Machine-Wide Installation (Requires Admin):
   .\install.ps1 -Admin
   ```
3. **Restart your terminal** to refresh PATH and profile bindings.

### After Installation

Open a **new terminal** (PowerShell or Command Prompt) and initialize:

```powershell
sdk rescan java
sdk list java
```

---

## 🗑️ Uninstallation

**If installed via the EXE installer:**
- Open **Settings → Apps & Features**, find **"Windows SDK Java Manager"**, and click **Uninstall**.
- Or run `Uninstall.exe` from the installation directory.

**If installed via one-liner or manual install:**

Open PowerShell in the repository folder and run:
```powershell
# For Current User:
.\uninstall.ps1

# For Machine-Wide Uninstallation:
.\uninstall.ps1 -Admin
```

---

## 🔧 Building the Installer (For Contributors)

To build the NSIS installer locally:

1. **Install NSIS** (any of these methods):
   ```powershell
   winget install NSIS.NSIS    # or
   choco install nsis -y       # or
   scoop install nsis
   ```
2. **Run the build script**:
   ```powershell
   cd installer
   .\build.ps1 -Version "1.0.0"
   ```
3. The installer EXE will be generated in the `installer\` directory.

> **Note:** When you push a version tag (e.g., `git tag v1.0.0 && git push --tags`), GitHub Actions automatically builds the installer and publishes it to the [Releases](https://github.com/pankajkpal/sdk-java-for-windows/releases) page.