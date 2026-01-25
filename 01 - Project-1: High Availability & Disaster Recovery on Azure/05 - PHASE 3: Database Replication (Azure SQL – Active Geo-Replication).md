# PHASE 3: Database Replication (Azure SQL – Active Geo-Replication)

Is phase mein hum Azure par Sql Server aur Sql Database create karenge, isme central india region mein primary database host hoga aur isi database ka ek geo-replication south india region mein host hoga.

Matlab ye hai ki Sabse pehle Central India region mein ek sql server create hoga, us sql server ke ander ek database create hoga geo-replication type ka. Fir se South India region mein ek sql server create hota aur iske ander primary database ka replication database create hoga. Jisme primary region aur secondary region mein same data hoga.

Last mein DR Drill bhi karenge jisme hum primary database ko manual failover karenge, jisse secondary region wala database primary ho jata aur read, write requests bhi usi pe jaati hain, aur primary region wala database secondary ban jata hai jo sirf readable hota hai, jiska matlab hai ki secondary database se data sir read kar sakte hain.

Geo-Replication ka matlab hai ki database ki copy ek dusri geographic location (region) mein create kar dena. Jisme primary aur secondary databases mein data same rehta hai.

<br>

### Phase 3 Goal
- Primary DB in Central India.
- Geo Replica in South India.
- Readable secondary.
- Manual failover drill.
- RPO measurement.


Maine ye project complate karke test kiya hua hai, Maine ye complete infrastructure Terraform ke through create kiya tha.

<br>
<br>

### Infrastruce Creation

<br>

### STEP 1: Primary Azure SQL Setup (Central India):

A) Create SQL Server:

Azure Portal → SQL servers → Create

| Setting     | Value            |
| ----------- | ---------------- |
| Server name | sql-hadr-primary |
| Region      | Central India    |
| Auth        | SQL auth         |
| Admin user  | sqladmin         |
| Password    | Strong password  |


B) Create Database:

Azure Portal → SQL databases → Create

| Setting           | Value                   |
| ----------------- | ----------------------- |
| DB Name           | hadr-db                 |
| Server            | sql-hadr-primary        |
| Compute           | Basic / General Purpose |
| Backup redundancy | Geo-redundant           |


C) Networking:
- Allow Azure services.
- Allow your IP.
 
<br>
<br>

### STEP 2: Create Secondary Replica (South India):

Azure Portal:
- SQL Database → hadr-db → Replicas → Create replica.

| Setting        | Value              |
| -------------- | ------------------ |
| Replica server | New                |
| Server name    | sql-hadr-secondary |
| Region         | South India        |
| Compute        | Same or lower      |
| Readable       | Yes                |

Replication setup takes few minutes.

<br>
<br>

### STEP 3: Verify Replication:

Azure Portal → SQL DB → Replicas

You should see:
```
Primary → Central India
Secondary → South India (Readable)
Replication status: Healthy
```

<br>
<br>

### STEP 4: Application Connection Strategy (VERY IMPORTANT):

Ye step aapke application ko database ke saath connect karne ke liye hai. Agar apka koi application hai to ye step follow kariye. Is step ka matlab hai ki apko application ke code mein database ke connection ke liye database ki configuration hardcode nhi karni hai balki usko dynamic rakhna hai.

Enterprise Rule:
- App should NOT hardcode region.
- App should know role (Primary / Secondary).

For now:
- App uses Primary DB connection.
- On DB failover → update connection string.

<br>
<br>

### STEP 5: Test Data Replication (Hands-On):

A) Connect to Primary DB:

Humko primary db se connect karna hoga aur usme ye niche waali command run karni hogi.

Use Azure Query Editor or SSMS.
```
CREATE TABLE health_check (
    id INT PRIMARY KEY,
    message VARCHAR(50)
);

INSERT INTO health_check VALUES (1, 'Primary DB Active');
```

B) Read from Secondary.

Ab humko seconday database se connect karna hoga aur usme data read karne ki query run karni hai.

Connect to Secondary DB (Read-only):
```
SELECT * FROM health_check;
```

Data visible = replication working ✅.

<br>
<br>

### STEP 6: Manual Failover Test (DR Drill):

Ab humko manual failover karke DR Drill karni hai, iska matlab hai ki humko database pe jaake manual failover karna hai, jisse hoga ye ki prmiary db secondary ho jayega aur secondary db primary ho jayega.

Azure Portal:
- SQL DB → Replicas → Select Secondary → Failover.

What happens:
- Secondary becomes Primary.
- Old Primary becomes Secondary.

It takes ~30–60 seconds.


**Verify After Failover**:
```
INSERT INTO health_check VALUES (2, 'Failover Successful');
```
Read again → Data present

🎉 DB Failover Successful.

<br>
<br>

### Measure RPO (CRITICAL):

RPO (Recovery Point Objective) iska matlab hai ki disaster ke time kitna data loss ho sakta hai. 

RPO wo maximum time period hota hai jiska data kisi outage ke waqt loss ho sakta hai.

RPO ek Business Target hota hai. Jab aap project banate hain, toh client ya company kehti hai: "Agar disaster hua, toh hum maximum 5 second tak ka data khone ko taiyar hain." Ye 5 second aapka RPO Target ban gaya.

Azure SQL Geo-replication ke liye, Microsoft typically < 5 seconds ka RPO target karti hai, kyunki data continuous replicate hota rehta hai.

Pehle **Data Lag samjho**:
- Data lag ka matlab hai ki primary database se secondary database mein data copy hone mein kitna time laga. Isko data lag bolte hain.
- Data Lag (jisey technical language mein Replication Lag kehte hain) wo "deeri" ya "gap" hai jo Primary database aur Secondary database ke beech mein hoti hai.

Chunki aap Azure SQL Geo-Replication use kar rahe hain, toh ye Asynchronous hota hai. Iska matlab hai ki data pehle Primary par likha jata hai aur uske thodi der baad Secondary par copy hota hai.

Data Lag Ko Example Se Samjhein:

Maan lijiye aap Central India (Primary) aur South India (Secondary) mein kaam kar rahe hain:
- Step 1 (T=0 sec): Aapne Flask app se ek entry ki: Name: "Rahul". Ye Central India DB mein turant save ho gayi.
- Step 2 (T=0.5 sec): Azure ka background process is entry ko South India bhejne ki koshish karta hai.
- Step 3 (T=2.0 sec): Ye entry South India DB mein save ho jati hai.

Yahan jo 2 seconds ka gap aaya, wahi Data Lag hai.

Ab samjho ki RPO kya hota hai:
- Agar aapka RPO 1 ghanta hai, toh iska matlab hai ki agar abhi system crash hua, toh pichle 1 ghante ka kaam (data) chala jayega, lekin usse purana data safe rahega.
- Agar aapne Primary mein record dala aur wo 2 second baad Secondary mein dikha, toh aapka Current Lag 2 second hai.
- Agar disaster theek isi waqt ho jaye, toh aapka Data Loss wahi 2 second ka hoga jo abhi tak secondary par nahi pahuncha tha. 
- RPO ka talluq Failover mein lagne waale time se nahi hota. Iska talluq sirf us Gap se hota hai jo replication ki wajah se reh gaya.

Example:
- Maan lijiye 10:00:00 AM par Primary database crash hua.
- Lekin replication lag ki wajah se Secondary ke paas sirf 09:59:55 AM tak ka hi data tha.
- Toh ye jo 5 seconds ka data hai jo kabhi Secondary tak pahunch hi nahi paya, ye aapka RPO (Data Loss) hai.


**Scenario**:

Aapka Primary Database Central India mein hai aur Secondary South India mein. Aapka Replication Lag 2 seconds ka hai.

RPO: 

Disaster ke waqt kitna data loss hua ye RPO hota hai. Example: ```Time 10:00:00 AM```: Ek customer ne aapki Flask app par order place kiya. Ye data Central India DB mein save ho gaya.

Time 10:00:01 AM: Central India ka poora region crash ho gaya (Disaster!). Kyuki replication lag 2 seconds ka tha, toh ye order abhi tak South India DB mein copy nahi ho paya tha.

RPO Result: Aapne wo 1 order loose kar diya. Toh aapka RPO hua 2 seconds.

How to measure:
- Insert record in primary.
- Immediately read from secondary.
- Measure delay.

Typical result:
- RPO ≈ 1–5 seconds.


<br>

**RTO (Recovery Time Objective)**

Defination: Disaster ke baad system ko wapas "Up & Running" karne mein kitna time laga.

Example:
- Time 10:00:01 AM: Central India crash hua. Aapki app chalna band ho gayi (Downtime start).
- Time 10:00:05 AM: Aapko alert mila. Aapne Azure Portal login kiya.
- Time 10:01:00 AM: Aapne 'Forced Failover' button dabaya Central India ko primary banane ke liye.
- Time 10:01:10 AM: Failover complete hua aur Central India DB active ho gaya.
- Time 10:01:20 AM: Aapne Flask App ki connection string update ki ya Traffic Manager/Front Door ne traffic divert kiya. App wapas live ho gayi.

RTO Result: 10:00:01 se 10:01:20 tak, yani total 1 minute 19 seconds lagay system ko wapas lane mein. Ye aapka RTO hai.

<br>

**Ab ek aur scenario dekho**:

Scenario:

Suppose jaise data lag 2 seconds hai, Primary Central India hai aur Secondary South India.

10:00 par user ne order place kiya aur data central india mein save ho gya, 10:01 par disaster ho gya, Manual failover karne mein 1:30 yaani 90 seconds ka time laga jisme South India primary ban gya tha. TO yaha RPO kaise niklega ye dekho.

Timeline Breakdown:
- 10:00:00 AM: Order place hua aur Central India (Primary) mein save ho gaya.
- 10:00:00 - 10:00:02 AM: Kyunki Data Lag 2 seconds hai, toh ye data abhi raste mein hai, South India tak pahuncha nahi hai.
- 10:00:01 AM: Disaster ho gaya! Central India poora down ho gaya.
- 10:01:31 AM: Aapne manual failover kiya aur 1.5 minute (90 seconds) baad South India (Secondary) ab New Primary ban gaya.

Aapka RPO (Data Loss) Kitna Hoga?

Aapka RPO sirf 2 seconds hoga. 

Kyun? RPO ka talluq sirf us data se hai jo replication lag ki wajah se Secondary tak nahi pahunch paya.
- Aapne order 10:00:00 par diya.
- Disaster 10:00:01 par hua (Yani sirf 1 second ka gap).
- Kyunki lag 2 seconds tha, toh ye 1 second pehle wala order South India mein nahi pahunch paya tha.
- Result: Wo 1 order jo Central mein tha par South mein nahi gaya, wo hamesha ke liye kho gaya. Ye loss sirf un 2 seconds ke gap ka hai.

Aapka RTO (Downtime) Kitna Hoga?

Aapka RTO 1 minute 31 seconds hoga.

Kyun? RTO wo time hai jab se disaster hua (10:00:01) aur jab tak aapka system wapas up hua (10:01:31).
- In 90 seconds ke dauran aapki Flask app "Database connection error" dikha rahi hogi.
- Is 1.5 minute ke gap mein kisi naye user ne koi order place nahi kiya hoga kyunki site band thi. Isliye ye 90 seconds RPO (data loss) mein count nahi hote, ye Downtime mein count hote hain.

Ek Zaroori Baat: Data Lag vs. Failover Time

Aapko confusion ho rahi hai ki "failover hone mein jo 1.5 minute lage, kya wo bhi RPO hai?"

Jawab hai: Nahi
- RPO (2 sec): Ye wo data hai jo "Primary ke paas tha par Secondary ke paas nahi tha" (Past data loss).
- RTO (90 sec): Ye wo time hai jab "Kisi ke paas bhi data likhne ki jagah nahi thi" kyunki system down tha (Service loss).

**Pro Tip**: Agar aap Auto-Failover Groups use karte, toh ye 1.5 minute (RTO) kam hokar shayad 30-40 seconds reh jata, kyunki Azure khud hi detect karke switch kar deta.

<br>

**Phase 3 Completion Checklist**:
- Primary & secondary DB.
- Active geo-replication.
- Readable secondary.
- Failover tested.
- RPO measured.

<br>
<br>
<br>

## Terraform Scripts to implement Geo-Replication Azure DB

Maine ye sql servers aur databases banane ke liye terraform scripts ka use kiya tha.

Folder Struture:
```
my-project/
├── ha-dr-app/
    ├── app.py
    └── requirements.txt

└── Terraform-Scripts/
    ├── modules/
        ├── resource-group
            ├── main.tf
            ├── variables.tf
            └── outputs.tf
        ├── app-service
            ├── main.tf
            ├── variables.tf
            └── outputs.tf
        └── front-door
            ├── main.tf
            ├── variables.tf
            └── outputs.tf
    ├── main.tf
    ├── providers.tf
    ├── variables.tf
    ├── terraform.tfvars
    └── outputs.tf
```

Ye jo tum uper folder strucrture dekh rahe ho ye fornt-door tak ke resources create kar rha hai. Kyuki maine pehle application level par DR implement kiya tha, Database DR ka concept iske baad implement kiya tha.

To us time par maine ek problem face ki thi ki, meri global ```main.tf``` mein resource group, app service, front door ye create karne ke block likhe hua the, lekin mujhe ye infra create nhi karna tha mujhe bs sql infra create karna tha, to problem ye thi ki existing terraform scripts mein mai kaise sql infra create karne ki script likhu ki sirf sql infra hi create ho baaki jaise resource group, app service aur front door ye infra create na ho.

To yaha pe maine terraform scripts mein module level ek sql-server karke ek folder create kiya tha jisme terraform ko initialize kiya tha matlab us sql-server folder ke ander fir se ek alag global ```main.tf``` file thi aur nayi state file create hui thi, iska matlab ye folder global terraform scripts ke ander ek alaga seperate terraform scripts hain sql infra ke liye jinka global terrafrom files se koi lena dena nhi hai.

After Folder Structure:
```
my-project/
├── ha-dr-app/
    ├── app.py
    └── requirements.txt

└── Terraform-Scripts/
    ├── modules/
        ├── resource-group
            ├── main.tf
            ├── variables.tf
            └── outputs.tf
        ├── app-service
            ├── main.tf
            ├── variables.tf
            └── outputs.tf
        └── front-door
            ├── main.tf
            ├── variables.tf
            └── outputs.tf
    ├── sql-env/
        ├── modules/
            ├── resource-group
                ├── main.tf
                ├── outputs.tf
                └── variables.tf
            └── sql-server
                ├── main.tf
                ├── outputs.tf
                └── variables.tf
        ├── main.tf
        ├── providers.tf
        ├── variables.tf
        └── terraform.tfvars
    ├── main.tf
    ├── providers.tf
    ├── variables.tf
    ├── terraform.tfvars
    └── outputs.tf
```

Ye ```sql-env``` ek alag terraform ki scritps hain jo sirf sql infra create kar rahi hain.

Phle maine modules likhe resource groups aur sql-server. Ab ek ek chiz yaha pe resource group module likhne ki jarurat nhi thi kyuki us time par already resource group azure pe bana hua tha to maine global ```main.tf``` mein data source block use karke resource group ki information azure se fetch kar li thi, na maine global ```main.tf``` file mein resource group module ko call kiya hai, haan resource group module files create isliye kar di kyu aagar ek alag resoure group banana pad gya to bana sake.

<br>

**modules/resource-group**:

main.tf:
```
resource "azurerm_resource_group" "rg" {
  name     = var.resource-group-name
  location = var.resource-group-location
}
```

variables.tf
```
variable "resource-group-name" {
  type = string
}

variable "resource-group-location" {
  type = string
}
```

outputs.tf:
```
output "resource-group-name" {
  value = azurerm_resource_group.rg.name
}

output "resource-group-location" {
  value = azurerm_resource_group.rg.location
}
```

**modules/sql-server**:

main.tf:
```
# Primary SQL Server (Central India)
resource "azurerm_mssql_server" "sql-server-primary" {
  name = var.primary-sql-server-name
  resource_group_name = var.resource-group-name
  location = var.primary-sql-server-location
  version = "12.0"
  administrator_login = var.primary-admin-login
  administrator_login_password = var.primary-admin-password
}

# Secondary SQL Server (South India)
resource "azurerm_mssql_server" "sql-server-secondary" {
  name = var.secondary-sql-server-name
  resource_group_name = var.resource-group-name
  location = var.secondary-sql-server-location
  version = "12.0"
  administrator_login = var.secondary-admin-login
  administrator_login_password = var.secondary-admin-password
}


# Primary Database

resource "azurerm_mssql_database" "primary-db" {
  name = var.primary-db-name
  server_id = azurerm_mssql_server.sql-server-primary.id
  sku_name = "S1"
}

# Secondary Database

resource "azurerm_mssql_database" "secondary-db" {
  name = var.secondary-db-name
  server_id = azurerm_mssql_server.sql-server-secondary.id
  creation_source_database_id = azurerm_mssql_database.primary-db.id
  create_mode = "Secondary"
  sku_name = "S1"
}
```

Explanation:
- ```create_mode = "Secondary"```: Ye line sabse important hai. Isi se Terraform ko pata chalta hai ki naya khali database nahi banana hai, balki primary database ka replica banana hai.

variables.tf:
```

variable "primary-sql-server-name" {
  type = string
}

variable "resource-group-name" {
  type = string
}

variable "primary-sql-server-location" {
  type = string
}

variable "primary-admin-login" {
  type = string
}

variable "primary-admin-password" {
  type = string
}

variable "secondary-sql-server-name" {
  type = string
}

variable "secondary-sql-server-location" {
  type = string
}

variable "secondary-admin-login" {
  type = string
}

variable "secondary-admin-password" {
  type = string
}

variable "primary-db-name" {
  type = string
}

variable "secondary-db-name" {
  type = string
}
```

outputs.tf:
```

output "primary-sql-server-name" {
  value = azurerm_mssql_server.sql-server-primary.name
}

output "secondary-sql-server-name" {
  value = azurerm_mssql_server.sql-server-secondary.name
}

output "primary-db-name" {
  value = azurerm_mssql_database.primary-db.name
}

output "secondary-db-name" {
  value = azurerm_mssql_database.secondary-db.name
}
```


**sql-env/main.tf**:
```
data "azurerm_resource_group" "resource-group" {
  name = "mera-rg-central-india"
}

# This module will create Sql Server and Database.
module "sql-server-and-database-wit-geo-replication" {
  source = "./modules/sql-server"
  
  # Both SQL Server Resource Group Name
  resource-group-name = data.azurerm_resource_group.resource-group.name
  
  # Primary SQL Server
  primary-sql-server-name = "sql-server-primary"
  primary-sql-server-location = "Central India"
  primary-admin-login = "puneet"
  primary-admin-password = "welcome@123"

  # Secondary SQL Server
  secondary-sql-server-name = "sql-server-secondary"
  secondary-sql-server-location = "South India"
  secondary-admin-login = "puneet"
  secondary-admin-password = "welcome@123"

  # Primary DB
  primary-db-name = "primary-database"

  # Secondary DB
  secondary-db-name = "secondary-database"
}
```

**sql-env/providers.tf**:
```
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }
}


provider "azurerm" {
  #resource_provider_registrations = "none" # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.

  
  features {}
}
```

**sql-env/variables**:
```
empty
```

**sql-env/terraform.tfvars**:
```
empty
```


<br>

 ### Run commands

 terraform init.

 terraform plan.

 terraform apply --auto-approve.

 To Destroy:

 terraform destroy --auto-approve.

 <br>
 <br>

 ## PHASE 4: Backup & Restore Strategy (Enterprise-Grade)

 Aage next slide mein hu **PHASE 4: Backup & Restore Strategy (Enterprise-Grade)** dekhenge.
