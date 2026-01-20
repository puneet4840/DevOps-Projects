# Overview of Project: High Availability and Disaster Recovery on Azure (Enterprise Style)

Ye ek High Availability aur Disaster Recovery ka project hai. Jisme hum python flask application ko azure ke infra par highly available aur disaster recovery rakhenge.

Humare paas ek python (flask) ka ek application hoga jo url hit karne par region name, hostname ki information dega, ```/health``` hit karne par 200 OK response dega.

Is app ko hum Azure App Service par deploy karenge central india aur south india do alag-alag regions mein. Load balance karne ke liye hum dono app service ko Azure Front Door ke backend mein rakhenge jisse ek app service stop hone par, traffic dusre app service par redirect ho jayega.

Fir hum Azure SQL Databases banyenge Geo-Replication method se, jisme ek db central india region mein hoga aur dusra db south india region mein hoga. 

Dono DR drill karenge. DR drill ka matlab hai ek app stop karke traffic dusre app par bhejenge, ese hi primary db ko failover karke dekhenge. 

Fir primary db ko point-in-time restore karke data restore karenge.

Ye hi humara project hai.

<br>

**Platform**: Microsoft Azure.

**Tech**: Python Flask, Azure App Service (Linux), Azure Front Door, Azure SQL (Geo-Replication + Backup & Restore).

**Architecture Style**: Multi-Region Stateless App + Global Traffic Routing + Geo-replicated Database + Backup Strategy.

<br>
<br>

### Project Overview (High Level)

**Project ka purpose kya hai?**:

Real world me companies ko downtime avoid karna hota hai. Agar kisi region mein outage ho jaye jaise (data center issue, network fail, region down), tab bhi application globally chalti rehni chahiye.

Is project me hum:
- App ko 2 regions me deploy karenge (Central India & South India).
- Global entry point banayenge (Front Door).
- Auto failover test karenge (DR Drill).
- Database replication setup karenge.
- Database backup + restore practically perform karenge.

Ye project multiple Phases mein hoga:
- PHASE 1: Application Layer (Multi-Region Deployment).
- PHASE 2: Global Traffic Routing with Azure Front Door.
- PHASE 3: Database Replication (Azure SQL – Active Geo-Replication).
- PHASE 4: Backup & Restore Strategy (Enterprise-Grade).
- PHASE 5: Automated Failover Testing & DR Drill (Enterprise Level).

Maine is project ko phase wise implement kiya tha, aur hum ek-ek karke in phases ko dekhenge.

<br>
<br>

## Core Concepts (Basic to Enterprise Thinking)

**HA (High Availability) kya hota hai?**:
- High Availability ka matlab:
  - System ya application har time up and running rahe.
  - Single server ya single region fail hone pe bhi app available ho.
 
High Availability ka matlab hota hai system ko aise design karna ki wo almost always available rahe, aur kisi ek failure se service down na ho.

HA ka focus hota hai:
- downtime avoid karna.
- failure ke time automatic continue karna.


Example:

Tumhara app do regions mein chal rha hai: Central India aur South India.

Central India app stop:
- Front Door probes fail detect karega.
- Traffic South India app pe shift.

User ko:
- same URL milta hai.
- service still available.

Ye HA behavior hai.

<br>

**DR (Disaster Recovery) kya hota hai?**:

Disaster Recovery (DR) ka matlab hota hai:
- Agar koi bada incident / disaster ho jaye (region down, data corruption, cyber attack, outage), to system ko jaldi se wapis restore karna aur service resume karna.

DR ka focus hota hai:
- System ko wapas kaise laayen.
- Data ko kaise recover karein.
- Outage time ko minimize kaise karein.

Disaster = fire, flood, earthquake, Azure region outage, DB corruption, ransomware, etc.

Example:

Tumhara app do regions mein chal rha hai: Central India aur South India.

Central India region down (bada disaster).
- App service + DB down.
- South India me full setup ready.
- Traffic South India pe.
- DB geo replication se data safe.

Ye DR behavior hai.

<br>

**DR ka “main goal” kya hota hai?**

DR ke 2 famous terms hoti hain:

**RTO** – Recovery Time Objective:
- Disaster hone ke baad kitne time me system wapas chalna chahiye?

Example:
- RTO = 5 minutes.
- matlab outage max 5 minutes.

**RPO** – Recovery Point Objective:
- Data loss max kitna tolerate kar sakte ho? Matlab ki maximum kitna data loss ho sakta hai.

Example:
- RPO = 1 minute
- matlab disaster hua to max 1 minute ka data loss allowed.

DR plan banate time RTO/RPO sabse important hote hain.


<br>
<br>

### Tumhara project HA hai ya DR?

Tumhara project actually **HA** + **DR** dono hai.

**HA part**:
- primary down hone par request automatically secondary pe shift.
- user ka downtime minimal.

**DR part**:
- secondary region me full application + database available.
- region-level disaster me service continue.

<br>
<br>

### HA aur DR me difference kya hai?

| Feature  | High Availability (HA)              | Disaster Recovery (DR)                    |
| -------- | ----------------------------------- | ----------------------------------------- |
| Focus    | downtime avoid                      | disaster ke baad restore                  |
| Scope    | small failures (VM down, app crash) | big failures (region down, DB corruption) |
| Location | mostly same region                  | usually different region                  |
| Goal     | continuous availability             | recovery + continuity                     |
| Example  | load balancer + 2 instances         | geo-replication + secondary region        |

<br>
<br>

### Disaster Recovery Strategies

DR strategies mainly 4 categories me hoti hain:
- Active-Active DR.
- Active-Passive DR.
- Warm Standby.
- Cold Standby.

<br>

**1 - Active-Active DR (Hot)**:

Active-Active DR mein dono primary aur secondary regions mein app live running hota hai aur 50% 50% load balancing se traffic live distribute hota hai.

Active-Active means:
- Dono regions/sites actively traffic serve karte hain.
- traffic split hota hai.
- primary region fail → secomdary remaining region takes full load.

- Ye highest availability DR strategy hai. Isme Primary + secondary both live running hote hain production mein.
- Traffic live distribute hota hai.
- If one region fails → other continues automatically.

No standby concept.

Both sites active.

Example:
- 2 regions me app services fully live.
- DB multi-master / distributed DB (Cosmos DB etc.).
- Front Door load balances between both.

Traffic:
- 50% Central.
- 50% South.

Failover:
- 100% South.

RTO: Near-zero.

RPO: Near-Zero.

<br>

**2 - Active-Passive DR (Warm)**:

Active-Passive DR strategy mein 2 regions mein Primary aur Secondary mein app live running hota hai lekin traffic sirf primary region par hi jata hai, failover hone par traffic secondary region par jata hai.

Active-Passive ka matlab:
- Ek region (serving traffic).
- Dusra region (ready but not serving traffic normally).

Isme secondary region me full environment running hota hai. Disaster aaya traffic secondary region par shift.

Example:
- Tumhara project Active-Passive DR par based hai, jisme primary region mein app service par traffic jata hai, lekin disaster hone par matlab primary app service stop hone par traffic secondary par shift hota jata hai.

Traffic:
- 100% Central India.
- 0% South India.

Diasaster(Failover).

- 0% Central India.
- 100% South India.


RTO: Low (minutes).

RPO: Very low (seconds/minutes).

<br>

**3 - Warm DR**:

Warm DR strategy mein primary region full production par chal rha hota hai lekin secondary region mein minimal components ready rehte hain.

Secondary region full production scale pe run nahi hota.

Disaster aaya → remaining resources spin up karke full scale banate ho.

Example:

Secondary region me:
- SQL server + minimal DB replica.
- Storage replication.
- App infrastructure templates ready (Terraform/ARM).

Disaster aaya:
- App services scale up.
- Front Door switch.

RTO: Medium (minutes to hours).

RPO: Low to medium (depends on replication).

<br>

**Cold DR**:

Cold DR ka matlab:
- Primary site pe system running hota hai.
- Regular backups liye ja rahe hain (app + DB backups).
- Disaster aaya → backup se dusre region mein system restore karte hain.

Secondary site pe koi live system nahi hota.

RTO: High (hours to days).

RPO: Depends on backup frequency (1 hour, 24 hours etc.).

