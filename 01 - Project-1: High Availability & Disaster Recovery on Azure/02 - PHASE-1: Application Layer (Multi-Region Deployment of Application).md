# PHASE-1: Application Layer (Multi-Region Deployment of Application)

<br>

**Phase-1 Goal**:

Phase-1 mein ek production-style stateless application deploy karna 2 Azure regions me:
- Central India → Primary.
- South India → Secondary (DR).

Is phase mein hum ek flask application ko Azure App Service par do alga-alag regions mein deploy karenge. Ek app service central india mein hogi aur dusre app service south india mein hogi, inhi dono regions ko app service mein hum flask app ko deploy karenge.

<br>

**Enterprise Thinking**:

Real companies mein:
- App stateless hoti hai.
- Config environment variables se aata hai. Lekin maine koi environment variables use nhi kiya is project mein.
- Health endpoint hota hai (LB ke liye).

Hum exact wahi follow karenge.

<br>
<br>

### STEP 1: Simple Production-Style App Banana

Hum Python Flask use kar rahe hain (lightweight + enterprise acceptable). Tum Node/.NET bhi kar sakte ho later.

<br>

**Local folder banao**:
```
ha-dr-app/
├── app.py
├── requirements.txt
└── README.md
```

```app.py```:
```
from flask import Flask
import os
import socket

app = Flask(__name__)

@app.route("/")
def home():
    return {
        "message": "HA-DR Application is running",
        "region": os.getenv("REGION_NAME", "unknown"),
        "hostname": socket.gethostname()
    }

@app.route("/health")
def health():
    return "OK", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
```

```requirements.txt```:
```
flask
gunicorn
```

Explanation:

requirements.txt mein jo bhi library mention hai vo app service mein install hogi.

Humne ```gunicorn``` library isliye install karayi hai kyuki app service mein flask app ko run karne ke liye gunicorn command ka use kiya jata hai, isliye ye library install kara rahe hain.

<br>

**Why this app design matters? (Interview points)**:

Ye ek simple app hai jisme ```/``` hit karne par message, region aur hostname ki information dikhegi, jisse humko pta lagega ki konsi app par request gyi hai.

```/health``` route simple ek ```OK 200``` response return kar rha hai, ye response front door service ko chiaye hota hai application ko health samjhne ke liye, front door service isi route ke response se pta lagayegi ki application up and running hai ya down hai.

Load Balancer / Front Door isko call karke decide karta hai app healthy hai ya nahi. Agar ```/health``` fail → traffic automatically switch ho sakta hai.

<br>
<br>

### STEP 2: Create Azure App Service – Primary Region (Central India) and Secondary Region (South India)

Ab hum azure ke Central India region aur South India region mein ek-ek app service create karenge. Is project ka complete infrastrcture main terraform ka use karke create kiya hai. Hum dono tarike az cli aur terraform se dekhenge ki app service kaise create karni hai.

<br>

### Method-1: Azure CLI Method :

**Central India App Service Creation and Deployment**

Login:
```
az login
```

Resource Group:
```
az group create \
  --name rg-ha-dr-primary \
  --location centralindia
```

App Service Plan (Linux):
```
az appservice plan create \
  --name asp-ha-dr-primary \
  --resource-group rg-ha-dr-primary \
  --location centralindia \
  --sku B1 \
  --is-linux
```

App Service Create:
```
az webapp create \
  --resource-group rg-ha-dr-primary \
  --plan asp-ha-dr-primary \
  --name ha-dr-app-primary-<unique-name> \
  --runtime "PYTHON|3.10"
```
App name globally unique hona chahiye.

Deploy:
```
az webapp up \
  --name ha-dr-app-primary-<unique-name> \
  --resource-group rg-ha-dr-primary \
  --runtime "PYTHON|3.10"
```

```az webapp up``` easy deployment method hai:
- code push.
- build.
- deploy automatically.

Test:
```
https://ha-dr-app-primary-<name>.azurewebsites.net/
https://ha-dr-app-primary-<name>.azurewebsites.net/health
```

Expected:
- Output mein region dikhna chahiye.
- ```/``` me JSON output + region.
- ```/health``` returns OK.

<br>

**Secondary Region (South India) Creation and Deployment**:

Same steps, sirf names & region change.

Same resource group mein dono app service create karenge.

App Service Plan:
```
az appservice plan create \
  --name asp-ha-dr-secondary \
  --resource-group rg-ha-dr-secondary \
  --location southindia \
  --sku B1 \
  --is-linux
```

App Service:
```
az webapp create \
  --resource-group rg-ha-dr-secondary \
  --plan asp-ha-dr-secondary \
  --name ha-dr-app-secondary-<unique-name> \
  --runtime "PYTHON|3.10"
```

Deploy:
```
az webapp up \
  --name ha-dr-app-secondary-<unique-name> \
  --resource-group rg-ha-dr-secondary \
  --runtime "PYTHON|3.10"
```

Test:
```
https://ha-dr-app-secondary-<name>.azurewebsites.net/
```

Output mein region dikhna chaiye.

<br>
<br>

### Method-2: Terraform:

**Local Folder banao**:
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

Ye uper terraform ka folder structure hai, isme maine modules folder ke ander modules create kiye hain, resource-group, app-service aur front-door ke liye. In modules ko maine globle ```main.tf``` file mein call kiya hai.

<br>

**How to Start**:
- Tumko sabse pehle ek folder banana hai ```Terraform-Scripts``` naame se jiske ander sabhi terraform script rakhni hai. Uper diya hua ek folder structure create karlo.
- Fir tumko terraform ko azure ke saath connect karna hai service principal ke secrets ki help se.
- Fir tumko ```providers.tf``` file mein azure ki initial configuration likhni hai.
- Fir tumko resource-group, app-service, module create karke ye resource azure pe create kar lene hain, fir app service pe azure devops pipelines ke throguh application deploy karni hai, fir front-door modules create karna hai aur resource azure pe create karna hai. Front-door 45 minutes ka time leta hai traffice server karne mein. 

<br>

**Authenticate Terraform with Azure**:

Terraform ko Azure ke saath authenticate service principal secret method se kiya hai:
- Create a service principal in azure app registration.
- Get Client ID, Client Secret, Subscription ID and Tenant ID from azure portal.

Ab yaha pe 2 methods hain is secret ko use karne ke liye:
- Pehla method hai ki tum direct Client ID, Client Secret, Subscription ID aur Tenant ID ko ```providers.tf``` file provider block mein likh do aur terraform khud se hi in credentials ka use karke azure ke saath authenticate kar lega, lekin ye method production mein recommended nhi hai kyuki isme method ye detail expose ho rahi hai.

- Dusra method hai ki hum ```C:\Users\puneetverma02``` location par ```.bashrc``` file banaye aur usme ye credentials environment variables ki tarah use kar le, jaise:
```
export ARM_CLIENT_ID="26d63b43-c206-47fc-a1d8-ac27698758fa"
export ARM_CLIENT_SECRET="dig8Q~KGa5~aISF8QPPKOoniXn5Nb1AngFUJKaek"
export ARM_SUBSCRIPTION_ID="65555fd5-5dc0-4bc0-a646-b01ddc552996"
export ARM_TENANT_ID="ad80d793-18f7-40c8-876e-382bf4ef9e47"
```

Is file ko save kar do. ```Terraform init``` karne par terraform khud hi azure ke saath authenticate kar lega.

Maine 2nd method ka use kiya hai is project mein, kyuki is method mein koi bhi credential expose nhi ho rha hai.

<br>

**Modules Terraform files**:

Ab tum har module ke liye terraform files ko create karo.

Resource Group:

```main.tf```:
```
resource "azurerm_resource_group" "rg" {
  name     = var.resource-group-name
  location = var.resource-group-location
}
```

```variables.tf```:
```
variable "resource-group-name" {
  type = string
}

variable "resource-group-location" {
  type = string
}
```

```outputs.tf```
```
output "resource-group-name" {
  value = azurerm_resource_group.rg.name
}

output "resource-group-location" {
  value = azurerm_resource_group.rg.location
}
```

<br>

App-Service:

```main.tf```:
```
resource "azurerm_service_plan" "app-service-plan-local" {
  name                = var.app-service-plan-name
  resource_group_name = var.app-service-resource-group-name
  location            = var.app-service-plan-location
  os_type             = "Linux"
  sku_name            = var.sku_name
}


resource "azurerm_linux_web_app" "app-service-local" {
  name                = var.app-service-name
  resource_group_name = var.app-service-resource-group-name
  location            = var.app-service-location
  service_plan_id     = azurerm_service_plan.app-service-plan-local.id

  site_config {
    always_on = false
    application_stack {
      python_version = "3.11"
    }
  }
}
```

```variables.tf```:
```
variable "app-service-plan-name" {
  type = string
}

variable "app-service-resource-group-name" {
  type = string
}

variable "app-service-location" {
  type = string
}

variable "app-service-plan-location" {
  type = string
}

variable "app-service-name" {
  type = string
}

variable "sku_name" {
  type = string
}
```

```outputs.tf```:
```
output "default_hostname" {
  value = azurerm_linux_web_app.app-service-local.default_hostname
}
```

<br>

Front-Door:

```main.tf```:
```
resource "azurerm_cdn_frontdoor_profile" "afd" {
  name = var.front-door-profile-name
  resource_group_name = var.resource_group_name
  sku_name = "Standard_AzureFrontDoor"
}

# Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "afd-endpoint" {
  name = var.frond-door-endpoint-name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id
}

# Backend Pool
resource "azurerm_cdn_frontdoor_origin_group" "afd-origin-group" {
  name = var.front-door-origin-name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id
  

  health_probe {
    interval_in_seconds = 30
    path = "/health"
    protocol = "Https"
    request_type = "GET"
  }

  load_balancing {
    sample_size = 4
    successful_samples_required = 3
  }

}

# Backend-1

resource "azurerm_cdn_frontdoor_origin" "primary-origin" {
  name = var.front-door-primary-origin-name
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.afd-origin-group.id
  host_name = var.primary-origin-hostname
  origin_host_header = var.primary-origin-host-header

  http_port = 80
  https_port = 443

  priority = 1
  weight = 1000

  certificate_name_check_enabled = false
}

# Backend-2

resource "azurerm_cdn_frontdoor_origin" "secondary-origin" {
  name = var.front-door-secondary-origin-name
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.afd-origin-group.id
  host_name = var.secondary-origin-host-name

  origin_host_header = var.secondary-origin-host-header

  http_port = 80
  https_port = 443

  priority = 2
  weight = 1000

  certificate_name_check_enabled = false

}


resource "azurerm_cdn_frontdoor_route" "route" {
  name = "route-all-traffic"
  cdn_frontdoor_endpoint_id = azurerm_cdn_frontdoor_endpoint.afd-endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.afd-origin-group.id
  cdn_frontdoor_origin_ids = [azurerm_cdn_frontdoor_origin.primary-origin.id, azurerm_cdn_frontdoor_origin.secondary-origin.id]

  supported_protocols = ["Http", "Https"]
  patterns_to_match = ["/*"]
  forwarding_protocol = "HttpsOnly"
  https_redirect_enabled = true
  link_to_default_domain = true
  enabled = true

  depends_on = [ azurerm_cdn_frontdoor_origin_group.afd-origin-group, azurerm_cdn_frontdoor_origin.primary-origin, azurerm_cdn_frontdoor_origin.secondary-origin ]
}
```
Explanation:

origin ka matlab hai backend pool, us backend pool ke ander do app service connect hain, primary origin aur secondary origin.

- Yaha depends_on isliye likha hai kyuki backend banane se pehle ye front door ka route create ho rha hai, lekin humko front door ka backend pool aur backend pehle create karni the. Isliye yaha pe depends on use kiya hai. 

```variables.tf```:
```
variable "front-door-profile-name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "frond-door-endpoint-name" {
  type = string
}

variable "front-door-origin-name" {
  type = string
}

variable "front-door-primary-origin-name" {
  type = string
}

variable "primary-origin-hostname" {
  type = string
}

variable "primary-origin-host-header" {
  type = string
}

variable "front-door-secondary-origin-name" {
  type = string 
}

variable "secondary-origin-host-name" {
  type = string
}

variable "secondary-origin-host-header" {
  type = string  
}
```

```outputs.tf```:
```
output "front-door-public-endpoint" {
  value = azurerm_cdn_frontdoor_endpoint.afd-endpoint.name
}
```

<br>

**Global Terraform Files**:

Modules ki config likhne ke baad tum global ```main.tf``` file mein modules ko call karoge aur azure pe resource create karoge.

Ab tum terraform ki global configuration likhoge.

```main.tf```:
```
module "resource-group" {
  source = "./modules/resource-group"

  resource-group-name = "mera-rg-central-india"
  resource-group-location = "Central India"
}

# This module will create App Service.
module "app-service-central-india" {

  source = "./modules/app-service"

  app-service-plan-name = "mera-app-service-plan-central-india"
  app-service-name = "mera-app-service-central-india"
  app-service-resource-group-name = module.resource-group.resource-group-name
  app-service-location = "Central India"
  app-service-plan-location = "Central India"
  sku_name = "B1"
}

# This module will create App Service.
module "app-service-south-india" {

  source = "./modules/app-service"

  app-service-plan-name = "mera-app-service-plan-south-india"
  app-service-name = "mera-app-service-south-india"
  app-service-location = "South India"
  app-service-plan-location = "South India"
  app-service-resource-group-name = module.resource-group.resource-group-name
  sku_name = "B1"
}

# This module will create Front Door.
module "front-door" {

  source = "./modules/front-door"

  front-door-profile-name = "mera-front-door"
  resource_group_name = module.resource-group.resource-group-name
  frond-door-endpoint-name = "mera-app"
  front-door-origin-name = "backend-pool"
  front-door-primary-origin-name = "central-india-app-service"
  primary-origin-hostname = module.app-service-central-india.default_hostname
  primary-origin-host-header = module.app-service-central-india.default_hostname
  front-door-secondary-origin-name = "south-india-app-service"
  secondary-origin-host-name = module.app-service-south-india.default_hostname
  secondary-origin-host-header = module.app-service-south-india.default_hostname

}


# This module will create Sql Server and Database.
module "sql-server-and-database-wit-geo-replication" {
  source = "./modules/sql-server"
  
  # Both SQL Server Resource Group Name
  resource-group-name = module.resource-group.resource-group-name.name
  
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

```provider.tf```:
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

```variables.tf```:
```
empty
```

```terraform.tfvars```:
```
empty
```

```outputs.tf```:
```
empty
```

<br>

**Run Terrfrom Commands**:

Terraform ki scripts likhne ke baad tum terraform ki commands run karoge jisse resources azure par create ho jaye.

Maine ek saath terraform ki files likhkar terraform ki command run nhi ki thi, ek ek karke resources create kiye the.

Maine kaise terraform se azure par resource banaye the:
- Pehle resource group ka module likhe aur usko global ```main.tf``` mein call karke azure pe resource group create kiya tha.
- Fir app service ka module likhke aur usko global ```main.tf``` mein call karke azure pe app service create ki thin do alag-alag regions mein.
- Fir maine Azure DevOps pipeline ki help se un app service par flask app deploy kiya tha.
- Fir front door ka module likke aur usko global ```main.tf``` mein call karke azure pe front door create kiya aur 45 minutes wait kiya, uske baad front door ki endpoint matlab public url ko use karke apna app access kiya tha.

To tum ab reource group create karlo, fir app service create karna, usne app deploy karne ke baad front door create karna.

Ye commands run karni hain:
- ```terraform init```.
- ```terrafrom plan```.
- ```terrafrom apply --auto-approve```.

Destroy karne ke liye:
- ```terrafrom destroy --auto-approve```.

<br>
<br>

### Agle phase 1.1 mein hum flask app ko app service pe deploy karna dekhenge azure pipelines ke through.
