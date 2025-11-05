# 🧠 Automated Backup System (Bash Script)

## 📋 Project Overview

The **Automated Backup System** is a Bash-based tool that automatically creates, verifies, rotates, and manages backups of important files or folders. It ensures data safety by compressing files, checking integrity, cleaning up old backups, and logging every step for full transparency.

This script functions like a smart, automated version of “copy and paste” — it remembers what it backed up, verifies it’s intact, and deletes old ones when space runs low.

---

## 🚀 What It Does

### ✅ **Part 1: Create Backups (The Main Job)**
- Takes a source folder as input.
- Creates a `.tar.gz` compressed archive named with a timestamp.
- Generates a checksum (`.md5`) to verify backup integrity.
- Skips unnecessary files/folders defined in `backup.config` (e.g. `.git`, `node_modules`, `.cache`).
- Logs every step to `backup.log`.

**Example Command:**
```bash
./backup.sh ./data
```

**Generated Files:**
```
./backups/backup-2025-11-04-1030.tar.gz
./backups/backup-2025-11-04-1030.tar.gz.md5
```

---

### ✅ **Part 2: Delete Old Backups (Keep Things Clean)**

The script automatically deletes older backups to save disk space.

**Rotation Rules:**
- Keep **7 daily backups** (one for each of the last 7 days)
- Keep **4 weekly backups** (one for each of the last 4 weeks)
- Keep **3 monthly backups** (one for each of the last 3 months)

**Example:**
```
Daily: Nov 3, Nov 2, Nov 1, Oct 31, Oct 30, Oct 29, Oct 28
Weekly: Oct 27, Oct 20, Oct 13, Oct 6
Monthly: Oct 1, Sep 1, Aug 1
```

Old backups beyond these are deleted automatically, with log entries like:
```
[2025-11-04 10:30:15] INFO: Deleted old backup: backup-2025-10-02-1030.tar.gz
```

---

### ✅ **Part 3: Check If Backups Are Good (Verification)**
After creating a backup, the script:
1. Recalculates its checksum and compares it with the saved `.md5` file.
2. Tests extracting a sample file to confirm the archive isn’t corrupted.
3. Logs `SUCCESS` or `FAILED` accordingly.

**Example Log:**
```
[2025-11-04 10:32:10] INFO: Checksum verified successfully
[2025-11-04 10:32:11] INFO: Backup integrity check passed
```

---

### ✅ **Part 4: Make It Smart (Advanced Features)**

#### A. Configuration File (`backup.config`)
Stores all adjustable settings in one place:
```bash
BACKUP_DESTINATION=./backups
EXCLUDE_PATTERNS=".git,node_modules,.cache"
DAILY_KEEP=7
WEEKLY_KEEP=4
MONTHLY_KEEP=3
EMAIL_ADDRESS=backup@local
EMAIL_SIM=./email.txt
```

#### B. Logging
Logs all activity in `backup.log`:
```
[2025-11-04 10:33:22] INFO: Starting backup of ./data
[2025-11-04 10:33:23] SUCCESS: Backup created: backup-2025-11-04-1030.tar.gz
[2025-11-04 10:33:24] INFO: Deleted old backup: backup-2025-10-01-1030.tar.gz
```

#### C. Dry Run Mode
Preview what will happen — no files are created or deleted.
```bash
./backup.sh --dry-run ./data
```
Output:
```
Would run: tar -czf backup-2025-11-04-1030.tar.gz ...
Would delete: backup-2025-10-01-1030.tar.gz
```

#### D. Prevent Multiple Runs
Uses a lock file (`/tmp/backup.lock`) to prevent two backups running at once. Deleted automatically when finished.

---

## 🌟 Extra Features (Bonus Points)

| Feature | Description | Example |
|----------|--------------|----------|
| **Restore** | Restores data from a backup | `./backup.sh --restore backup-2025-11-04-1030.tar.gz --to ./restore_test` |
| **List Backups** | Lists all backups with sizes | `./backup.sh --list` |
| **Disk Space Check** | Ensures enough disk space exists before backup | Auto check before backup creation |
| **Email Notification (Simulated)** | Writes results to `email.txt` | On success/failure, writes message with timestamp |

---

## ⚠️ Error Handling

Your script gracefully handles these situations:

| Error | Cause | Message |
|--------|--------|----------|
| Missing folder | Source not found | `ERROR: Source folder not found` |
| Permission denied | No read access | `ERROR: Cannot read folder, permission denied` |
| No disk space | Destination full | `ERROR: Not enough disk space for backup` |
| Missing config | Config file missing | `ERROR: Config file not found` |
| Backup running | Lock file present | `ERROR: Lock file exists: another backup is running` |

---

## 🧪 Testing Demonstrations

| Test Case | Command | Expected Result |
|------------|----------|----------------|
| **Create a backup** | `./backup.sh ./data` | Backup created successfully |
| **Multiple backups (simulated days)** | Run script with different timestamps | Rotation triggers automatically |
| **Auto deletion** | Observe logs | Shows deleted old backups |
| **Restore** | `./backup.sh --restore backup-2025-10-08-1030.tar.gz --to ./restore_test` | Files restored successfully |
| **Dry run** | `./backup.sh --dry-run ./data` | Logs what would happen |
| **Error handling** | `./backup.sh ./ghost_folder` | Shows error message |

---

## 🧠 How It Works

### 🔄 Rotation Algorithm
1. List all `.tar.gz` backups in the destination.
2. Sort them by date (newest first).
3. Keep the latest 7 unique days.
4. Keep the latest 4 unique weeks.
5. Keep the latest 3 unique months.
6. Delete everything older.

### 🧮 Checksum Verification
Uses `md5sum` to verify integrity:
```bash
md5sum -c backup-2025-11-04-1030.tar.gz.md5
```
If verification fails, it’s logged as an error.

### 📂 Folder Structure
```
Automated_Backup_System/
├── backup.sh
├── backup.config
├── backup.log
├── email.txt
├── backups/
│   ├── backup-2025-11-04-1030.tar.gz
│   ├── backup-2025-11-04-1030.tar.gz.md5
├── data/
│   ├── file1.txt
│   ├── file2.txt
└── restore_test/
```

---

## 💡 Design Decisions
- **Bash** chosen for portability and simplicity.
- **Lock file** prevents race conditions.
- **MD5 checksum** ensures file integrity.
- **Config file** allows easy customization.
- **Rotation logic** balances storage efficiency and data safety.

**Challenges solved:**
- Handling date parsing and sorting.
- Simulating weekly/monthly grouping.
- Safe deletion and recovery testing.

---

## 🧾 Example Output Log
```
[2025-11-04 10:45:12] INFO: Acquired lock: /tmp/backup.lock
[2025-11-04 10:45:13] INFO: Starting backup of ./data
[2025-11-04 10:45:14] INFO: Checksum verified successfully
[2025-11-04 10:45:14] INFO: Backup integrity check passed
[2025-11-04 10:45:15] SUCCESS: Backup created: ./backups/backup-2025-11-04-1030.tar.gz
[2025-11-04 10:45:15] INFO: Deleted old backup: backup-2025-10-01-1030.tar.gz
[2025-11-04 10:45:16] INFO: All tasks completed successfully.
```

---

## ⚠️ Known Limitations
- No incremental backups (full backups only).
- Email notifications are simulated, not sent.
- Date-based rotation assumes consistent filename format.
- Weekly/monthly grouping depends on system locale date output.

---

## 🧪 Example Commands Summary

| Task | Command |
|------|----------|
| Create backup | `./backup.sh ./data` |
| Simulate multiple days | Modify `TIMESTAMP="2025-10-01-1030"` in script |
| List backups | `./backup.sh --list` |
| Restore backup | `./backup.sh --restore ./backups/backup-2025-10-08-1030.tar.gz --to ./restore_test` |
| Dry run | `./backup.sh --dry-run ./data` |
| Error test | `./backup.sh ./ghost_folder` |

---

## 🏁 Conclusion
This **Automated Backup System** demonstrates practical DevOps automation concepts:
- File backup and verification
- Rotation and cleanup
- Logging and error handling
- Config-driven customization

It’s a complete, self-contained, real-world backup solution built entirely with **Bash scripting**.

---

### 🧑‍💻 Developer

**Name:** Venuthurla Siva Chaithanya  
**Email:**  chaithanyav.0203@gmail.com
**GitHub:** [@Chaithanya013](https://github.com/Chaithanya013)


