# PHASE 4: Backup & Restore Strategy (Enterprise-Grade)

Service: Azure SQL Database
Platform: Microsoft Azure 



### 🧠 Enterprise Reality (Why Phase 4 is Critical)

Real incidents:
- Developer ne DELETE FROM table chala diya 😐
- Wrong deployment ne data corrupt kar diya
- Region poora unavailable ho gaya

❌ Replication alone enough nahi
✅ Backups = last line of defense

<br>
<br>

### 🎯 Phase 4 Goals
- Automated backups samajhna
- Point-in-Time Restore (PITR)
- Geo-restore (region failure case)
- Restore actually perform karna

<br>
<br>

### 🔹 STEP 1: Understand Azure SQL Backup Types

Azure SQL by default backups leta hai (ye interviewer ko bolna MUST hai):

1️⃣ **Automated Backups**:
- Full backup – weekly
- Differential – daily
- Transaction log – every 5–10 minutes

2️⃣ **Retention**:
- Default: 7 days
- Can extend up to 35 days.

3️⃣ **Storage**:
- Locally redundant (LRS).
- Geo-redundant (GRS) → DR ke liye (enable this ✅).

👉 Tumne Phase 3 mein already Geo-redundant backup select kiya hai.

<br>
<br>

### 🔹 STEP 2: Verify Backup Settings (Hands-on)

Azure Portal

SQL Database → hadr-db → Backups

Check:
- Retention period
- Geo-redundant = Enabled

📸 Screenshot lena (GitHub / resume ke liye)

<br>
<br>

### 🔥 STEP 3: Point-in-Time Restore (MOST COMMON SCENARIO)

Scenario

“Data galti se delete ho gaya. Last 30 minutes ka data chahiye.”

1️⃣ **Simulate Data Loss**:
- Primary DB pe:
```
DELETE FROM health_check;
```

Confirm:
```
SELECT * FROM health_check;
```

❌ No rows

2️⃣ **Restore Database (PITR)**:

Azure Portal → SQL Database → Restore

| Setting       | Value                       |
| ------------- | --------------------------- |
| Restore point | 10–15 minutes before delete |
| New DB name   | hadr-db-restore             |
| Target server | sql-hadr-primary            |


⏳ Restore time: few minutes

3️⃣ **Verify Restored Data**:
```
SELECT * FROM health_check;
```

✅ Data back

🎉 PITR successful

<br>
<br>

### 🔥 STEP 4: Geo-Restore (REGION FAILURE SCENARIO)

Scenario:
- “Primary region poori tarah down ho gayi.”

What Geo-Restore Does:
- Uses geo-replicated backups
- Restore DB in any Azure region
- Slower than replication, but life saver

1️⃣ **Perform Geo-Restore**:

Azure Portal → SQL Database → Restore → Geo-restore

| Setting       | Value               |
| ------------- | ------------------- |
| Source        | hadr-db             |
| Target region | South India         |
| New DB        | hadr-db-geo-restore |


⏳ Restore may take longer (10–30 min)

2️⃣ **Verify**:
```
SELECT * FROM health_check;
```


✅ Data recovered even if primary region is assumed down

<br>
<br>

### 📊 RPO & RTO – Backup Perspective

| Scenario    | RPO               | RTO       |
| ----------- | ----------------- | --------- |
| PITR        | Minutes           | Minutes   |
| Geo-Restore | Up to last backup | 15–30 min |


👉 Document these values (VERY IMPORTANT)


<br>
<br>

### Phase 4 Completion Checklist
- Automated backups verified.
- Point-in-time restore tested.
- Geo-restore tested.
- RPO/RTO documented.
- Real DR scenarios covered.


At this point, tumhara project industry-grade DR architecture ban chuka hai 💪
