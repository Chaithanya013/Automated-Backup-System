# Automated Backup System (Bash Script)

## A. Project Overview

### What does your script do?
This project is a **Bash-based Automated Backup System** that creates, verifies, and manages file backups. It automatically compresses data, generates checksums to ensure integrity, and deletes older backups based on rotation policies (daily, weekly, and monthly).

### Why is it useful?
It helps users and system administrators easily automate their backup processes, ensuring:
- Data safety and quick recovery.
- Automatic old backup cleanup to save storage space.
- Verification and email notifications to confirm success or failure.

---

## B. How to Use It

### Installation Steps
```bash
# 1. Navigate to your working directory
cd /mnt/c/Users/hp/Desktop/Git\ Bash\ Projects

# 2. Create a project folder
mkdir Automated_Backup_system && cd Automated_Backup_system

# 3. Create required files
nano backup.sh
nano backup.config

# 4. Make script executable
chmod +x backup.sh
```

### Configuration File (`backup.config`)
```bash
BACKUP_DESTINATION=./backups
EXCLUDE_PATTERNS=".git,node_modules,.cache"
DAILY_KEEP=7
WEEKLY_KEEP=4
MONTHLY_KEEP=3
EMAIL_ADDRESS="backup@local"
```

### Basic Usage Examples

**1️⃣ Create a Backup:**
```bash
./backup.sh ./data
```

**2️⃣ List Backups:**
```bash
./backup.sh --list
```

**3️⃣ Restore from a Backup:**
```bash
./backup.sh --restore ./backups/backup-2025-11-01-1030.tar.gz --to ./restore_test
```

**4️⃣ Dry Run Mode (simulate actions):**
```bash
./backup.sh --dry-run ./data
```

**5️⃣ Error Handling (non-existing folder):**
```bash
./backup.sh ./invalid_folder
```

### Command Options
| Option | Description |
|---------|-------------|
| `--list` | Lists all available backups with size & date |
| `--restore <file> --to <path>` | Restores a specific backup |
| `--dry-run` | Shows what would happen without making changes |
| `<source_folder>` | Folder to back up |

---

## C. How It Works

### 1️⃣ Backup Creation
- Uses `tar` to compress the target directory into `.tar.gz`.
- Generates a checksum (`.md5`) to verify file integrity.

### 2️⃣ Rotation Algorithm
Backups are automatically cleaned up:
- Keeps **last 7 daily**, **4 weekly**, and **3 monthly** backups.
- Deletes any older backups beyond these limits.
- Uses timestamps (`backup-YYYY-MM-DD-HHMM.tar.gz`) to identify backup age.

### 3️⃣ Verification
After creating a backup:
- The script verifies the checksum with `md5sum -c`.
- Tests archive integrity using `tar -tzf`.

### 4️⃣ Folder Structure Example
```
Automated_Backup_system/
├── backup.sh
├── backup.config
├── backup.log
├── email.txt
├── backups/
│   ├── backup-2025-11-01-1030.tar.gz
│   ├── backup-2025-11-01-1030.tar.gz.md5
│   └── ...
└── data/
    ├── file1.txt
    └── file2.txt
```

---

## D. Design Decisions

### Why this approach?
- **Bash** chosen for portability and simplicity.
- **Tar + MD5** ensures lightweight yet reliable backups.
- **Config file** makes it flexible for different users.

### Challenges Faced
- Handling multiple dates and rotation policies together.
- Managing concurrent runs (solved with lock file).
- Simulating emails in a local environment.

### Solutions
- Implemented `lock` mechanism (`/tmp/backup.lock`).
- Added `send_email()` to log messages into `email.txt`.
- Used associative arrays for smart rotation logic.

---

## E. Testing

### How Testing Was Done
A test folder (`./data`) was created with multiple files.
Different test cases were executed:

#### ✅ Creating a Backup
```bash
./backup.sh ./data
```

#### ✅ Multiple Backups (Simulated Days)
Manually edited timestamp line:
```bash
TIMESTAMP="2025-10-02-1030"
```
Then ran the script multiple times.

#### ✅ Automatic Deletion of Old Backups
After 8+ backups, old backups beyond the 7 daily limit were deleted automatically.

#### ✅ Restoring from a Backup
```bash
./backup.sh --restore ./backups/backup-2025-10-05-1030.tar.gz --to ./restore_test
```

#### ✅ Dry Run Mode
```bash
./backup.sh --dry-run ./data
```

#### ✅ Error Handling
```bash
./backup.sh ./invalid_folder
```
Output:
```
ERROR: Source folder not found: ./invalid_folder
```

#### ✅ Email Simulation
```bash
cat email.txt
```
Output Example:
```
To: backup@local
Subject: Backup Success

Backup created successfully: ./backups/backup-2025-11-04-1030.tar.gz
---
Sent at 2025-11-04 11:05:23
```

---

## F. Known Limitations

| Limitation | Description |
|-------------|--------------|
| Incremental backups | Currently supports only full backups, not incremental ones |
| Email sending | Simulated via file, no real SMTP support |
| Cross-platform | Tested mainly on Linux/WSL2 |
| Manual date testing | Requires editing timestamp manually for date simulation |

---

### 🚀 Summary
This project successfully automates the entire backup lifecycle — from creation to rotation, verification, restoration, and reporting — using pure Bash scripting. It’s lightweight, fully configurable, and ideal for personal or small server environments.

