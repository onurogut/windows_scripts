# Windows Scripts Repository

This repository contains automated PowerShell scripts for Windows systems.

## 📌 signoff_users.ps1 - Automatic Session Sign-off Script

This PowerShell script detects user sessions that have been disconnected for a specified timeout period and automatically logs them off. You can specify users to exclude from this process and log all operations for tracking purposes.

---

## 📋 Features

✔ **Disconnected User Tracking:** Identifies users who have been disconnected for the specified duration.  
✔ **Excluded Users:** Allows predefined users to be excluded from the process.  
✔ **Automatic Session Termination:** Automatically logs off users whose sessions exceed the timeout limit.  
✔ **HTML Logging:** Stores session termination logs in a detailed HTML file.  

---

## 💻 Installation & Usage

### 1️⃣ Clone the Repository:
```powershell
git clone https://github.com/user/windows_scripts.git
cd windows_scripts
```

### 2️⃣ Set PowerShell Execution Policy:
```powershell
Set-ExecutionPolicy Unrestricted -Scope Process
```

### 3️⃣ Run the Script:
```powershell
.\signoff_users.ps1
```

---

## ⚙️ Configuration

You can modify the following parameters within the script:

- **`$sessionTimeoutMinutes`** → The session timeout period (in minutes).
- **`$excludedUsers`** → List of users to be excluded from the process.
- **`$logFolder`** → Directory where the HTML log files will be stored.

---

## 📄 Log File

- Logs are stored in the `C:\signoff_logs` directory in **HTML format**.
- Daily log files are created as `signoff_edilen_YYYY-MM-DD.html`.
- Logs are recorded in **INFO, WARNING, ERROR, and DEBUG** levels for detailed tracking.

---

## 🛠 Requirements

✅ Windows operating system  
✅ PowerShell 5.1 or later  

---

