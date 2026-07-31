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

## 📦 Installation & Uninstallation

### Installation Steps

1. **Open PowerShell** (Windows PowerShell 5.1 or PowerShell Core 7+).
2. **Navigate** to the repository folder:
   ```powershell
   cd c:\path\to\sdk-java-for-windows
   ```
3. **Run the installation script**:
   * **For Current User (Default):**
     ```powershell
     .\install.ps1
     ```
   * **For Machine-Wide Installation (Requires Admin):**
     ```powershell
     .\install.ps1 -Admin
     ```
4. **Restart your Terminal** (PowerShell or Command Prompt) to refresh PATH and profile bindings.
5. **Initialize your Java catalog**:
   ```powershell
   sdk rescan java
   sdk list java
   ```

---

### Uninstallation Steps

Open PowerShell in the repository folder and run:
* **For Current User:**
  ```powershell
  .\uninstall.ps1
  ```
* **For Machine-Wide Uninstallation:**
  ```powershell
  .\uninstall.ps1 -Admin
  ```