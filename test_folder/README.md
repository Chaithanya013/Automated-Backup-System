# Demonstration Examples for Automated Backup System

This section contains summarized descriptions for each feature demonstration, supported by screenshots in your project submission.

---

### 1. Creating a Backup  
**Command:**
```bash
./backup.sh ./data
```
**Description:**  
A new backup was successfully created for the `./data` folder. The script compressed files into a `.tar.gz` archive, generated an `.md5` checksum, and verified its integrity. The log confirmed successful backup creation.

**Expected Output:**
```
SUCCESS: Backup created: ./backups/backup-YYYY-MM-DD-HHMM.tar.gz
```

---

### 2. Creating Multiple Backups Over Several Days  
**Command Example:**
```bash
TIMESTAMP="2025-11-01-1030"
./backup.sh ./data
```
(repeated with different dates)

**Description:**  
Backups were created with modified timestamps to simulate backups across multiple days. This validated the rotation system. When backups exceeded the limit, the script automatically deleted older backups to comply with retention rules.

---

### 3. Automatic Deletion of Old Backups  
**Description:**  
Once the number of backups exceeded the retention policy (7 daily, 4 weekly, 3 monthly), the system identified and removed outdated ones. The deletion events were logged:
```
INFO: Deleted old backup: backup-2025-10-01-1030.tar.gz
INFO: Deleted old backup: backup-2025-10-02-1030.tar.gz
```
This ensured efficient disk space usage and validated the smart rotation logic.

---

### 4. Restoring from a Backup  
**Command:**
```bash
./backup.sh --restore ./backups/backup-2025-10-08-1030.tar.gz --to ./restore_test
```
**Description:**  
The restore functionality extracted archived files back into a directory (`./restore_test`). Backup integrity and checksum were validated before restoring. The system confirmed successful restoration in both the log and simulated email notification.

**Expected Output:**
```
SUCCESS: Restored backup to ./restore_test
```

---

### 5. Dry Run Mode  
**Command:**
```bash
./backup.sh --dry-run ./data
```
**Description:**  
Dry-run mode simulated backup operations without performing real file changes. The script displayed actions it *would* execute:
```
Would run: tar -czf backup-2025-11-04-1030.tar.gz ...
Would delete old backup: backup-2025-10-01-1030.tar.gz
```
This feature provided a safe preview before actual backups.

---

### 6. Error Handling (Folder Doesn’t Exist)  
**Command:**
```bash
./backup.sh ./ghost_folder
```
**Description:**  
The script detected that the target folder did not exist and safely aborted without crashing. It printed an appropriate error message and simulated an email notification:
```
ERROR: Source folder not found: ./ghost_folder
```
This validated the script’s resilience and proper error handling.

---

### 🧾 Summary of Test Results
| Test Case | Status | Result |
|------------|---------|---------|
| Backup creation | ✅ | Successful |
| Multiple backups (simulated days) | ✅ | Working |
| Old backup deletion | ✅ | Confirmed in logs |
| Restore backup | ✅ | Successful |
| Dry run mode | ✅ | Simulated correctly |
| Error handling | ✅ | Graceful exit |

---

**End of Demonstration Section**  
This concludes all the required test cases and demonstrations for the Automated Backup System project.

