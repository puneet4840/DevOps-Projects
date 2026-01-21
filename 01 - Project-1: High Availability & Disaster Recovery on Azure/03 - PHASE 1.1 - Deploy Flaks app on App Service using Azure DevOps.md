# PHASE 1.1: Deploy Flask Application on Azure App Services

Is phase mein hum Azure ki App Services par flask app ko deploy karenge, azure devops pipelines ke through.

<br>
<br>

### Pehle Samjho App Service ke Basics

App Service ek PaaS model hai. Iska matlab hai ki aapko niche di gayi cheezon ki chinta nahi karni:
- Windows ya Linux OS update karna.
- Python ya Framework install karna.
- Security patches lagana.

Aapka kaam sirf Code likhna aur use Deploy karna hai. Azure baaki sab sambhaal leta hai.

<br>

**App Service Plan**:

App Service ke saath hamesha ek App Service Plan hota hai.
- **App Service**: Ye aapka software/code hai.
- **App Service Plan**: Ye wo hardware (CPU, RAM) hai jispar aapka code chalta hai. App Service Plan ka matlab hai ki apna code run karne ke liye CPU aur Memory choose karna ki kitne confguration pe apko apni app run karni hai. Supoose apne 2cpu and 4GB RAM wala service plan liya, to aap ispe jitne chahe app (app service) run run kar sakte hain, kyuki apko app service plan ke liye pay karna hai.

<br>

**App Service Kaise Kaam Karti Hai**:

Jab aap Azure par App Service banate hain, to Azure ek empty container ya virtual machine setup karta hai. Lekin use ye nahi pata hota ki aapka code kaise chalana hai. Iske liye wo do cheezon par depend karta hai:
- **Deployment Center**: Wo jagah jahan se aap apna code bhejte hain (Azure DevOps, GitHub, Local Git, ya Zip file).
- **Startup Command**: Azure automatically detect kar leta hai ki ye Python app hai. Wo ek Gunicorn (production-grade server) ka use karta hai aapki app ko run karne ke liye.

Jab app app service create karte hain to create karte time apse puchta hai ki konsa OS environment chiaye, To wha do options hote hain:
- Linux.
- Windows.

To aap apne application ke according OS choose kar lete ho. Jaise maine is flask app ke liye Linux OS choose kiya tha.

To aap Linux os ke saath app service create karte ho to Azure ek vm create kar deta hai. Ab azure ne VM create to kar di lekin hum apne application ka kya kare jo app service pe run ho jaye.

<br>

**App Service mein kaha pe code upload karna hota hai**:

To yaha pe Azure ek folder create kar deta hai jisme humko apna application upload hota hai. Vo folder hota hai: ```/home/site/wwwroot```.

Is location par humko apne application ka code upload karna hota hai. Ya to tum apne code ko simple ek zip file mein daalke is ```/home/site/wwwroot``` location par upload kardo. Ya fir bine zip banaye apne code ki files us location par upload kardo. Agar aap zip folder us location par upload karte ho to azure us zip folder ko extract karke apke code ko wahi rakh deta hai.

<br>

**App Service mein application kaise upload kare**:

App Service mein ek option hota hai **Deployment Center**, isi option mein jake apko application, app service mein deploy karni hoti hai.

App Service mein application deploy karne ke multiple methods hote hain, jo Manual Deployment aur Automated Deployment (CI/CD) mein divide hote hain:

- Manual Deployment Method:
  - Local Git Deployment.
  - FTP Deployment.
  - Azure CLI Deployment.
  - VSCode Deployment.
  - Kudu File Manager.

- Automated Deployment (CI/CD):
  - Azure DevOps.
  - GitHub Actions.
  - BitBucket/GitLab.
 
<br>
<br>

### Manual Deployment

**Local Git Deployment**:

Is methoed mein aap App Service ke "Deployment Center" mein jaakar aap apne Local Git repo ko connect kar sakte hain. Aapko ek remote URL milta hai, aur aap ```git push azure main``` command se code deploy kar sakte hain.

<br>

**FTP Deployment**:

Is method mein hum ek third party file transfer tool jaise WinSCP se app service ki ```/site/wwwroot/``` location par connect karte hain aur files ko zip format ya normal files ko ```/site/wwwroot/```location par upload kar dete hain.

Aap FileZilla ya WinSCP jaise tools ka use karke files ko direct App Service ke /site/wwwroot folder mein upload kar sakte hain.

Steps:
- Portal → App Service → Deployment Center → FTPS credentials.
- Tumhe milenge:
  - FTP/FTPS host.
  - username.
  - password.
  - Use FileZilla / WinSCP.
  - Connect and upload files here: ```/site/wwwroot/```.
 
Files ko upload karne ke baad tumko app service mein ek startup command deni padti hai. Bina startup command ke apka app run nhi hoga. 

Startup Commnad:
```
gunicorn --bind=0.0.0.0:8000 app:app
```
Ye startup command flask app ke liye hai. Jisme hum gunicorn library se 8000 port par bind kar rhe hain. Ye ```app:app``` apko code se dekh kar likhna hai. 

Code: ```app.py```
```
app = Flask(__name__)
```

Ek ```aap``` apki python file ka naam hota hai aur dusra ```aap``` flask ka object hota hai.

<br>

**Azure CLI Deployment**:

Is method mein hum azure cli ke help se application ko app service pe deploy karte hain.

Agar aap pehle se bane hue resources (App Service Plan/RG) ka use karna chahte hain, toh ye method sahi hai.

Step A: Login aur Resource Check:

Sabse pehle login karein:
```
az login
```

Step B: Zip File Create Karein:

Azure CLI ke zariye deploy karne ke liye aapko apne code ki zip file banani hogi.

Step C: Zip Deploy Command:

Ab niche di gayi command se zip file ko existing App Service par push karein:
```
az webapp deployment source config-zip \
    --resource-group YourResourceGroup \
    --name YourAppServiceName \
    --src deploy.zip
```

Flask Specific Configurations:

Agar aapka main file ka naam ```app.py``` hai aur Flask object ka naam ```app``` hai, toh aapko startup command set karni hogi (Gunicorn use karte hue):
```
az webapp config set \
    --resource-group YourResourceGroup \
    --name YourAppServiceName \
    --startup-file "gunicorn --bind=0.0.0.0 --timeout 600 app:app"
```


Environment Variables:

Agar aapka app ```FLASK_ENV``` ya koi Database connection string use karta hai:
```
az webapp config appsettings set \
    --resource-group YourResourceGroup \
    --name YourAppServiceName \
    --settings FLASK_ENV=production DB_URL=your_db_url
```

In steps se apki application azure app service pe run ho jayegi.

<br>

**VSCode Deployment**:

Agar aap VS Code use kar rahe hain, to "Azure App Service" extension install karein.

Azure icon par click karein.

Apni App Service dhoondein.

Right-click karke "Deploy to Web App" select karein. Ye saara code apne aap pack karke upload kar dega.

<br>

**Kudu File Manager**:

Kudu (Scm) ek bahut hi powerful tool hai jo Azure App Service ke saath inbuilt aata hai. Iska File Manager (Debug Console) aapko apne App Service ke backend file system ka direct access deta hai, bina kisi FTP ya SSH tool ki zaroorat ke.

Steps to use:
- Azure Portal → App Service open karo.
- Left menu me search karo:
  - Advanced Tools.
- Click Go.

Ab Kudu open hoga.

- Kudu me:
  - Debug console.
  - Choose: SSH (Linux app).
- Ab top menu me: Site → wwwroot.
- Now tum exact folder pe pahuch gaye: ```/home/site/wwwroot```.
- Yaha tum:
  - ```app.py``` upload kar sakte ho.
  - ```requirements.txt``` upload kar sakte ho.
  - folder create kar sakte ho.
  - delete/rename kar sakte ho.
 
Upload kaise karte hain?
- Kudu UI me drag and drop upload option aata hai (ya upload button, depending UI).

Yaha se apki application app service mein upload ho jayegi, aur run ho jayegi.

Kudu mein file edit karna sirf temporary testing ke liye achha hai. Agar aapne Kudu mein koi change kiya aur phir Azure DevOps ya CLI se dubara deploy kiya, toh Kudu wale changes override (mita diye) ho jayenge. Isliye hamesha final code apne main repository (GitHub/DevOps) mein hi rakhein.

<br>
<br>

## Automated Deployment (CI/CD):

Ab hum dekhenge ki Azure DevOps ki pipeline ke through hum app service pe apni flask application kaise deploy kar sakte hain.

Maine is project mein application ka code Azure Repos par push kiya tha aur usi se Build pipeline banai thi.

**Azure Repos**:
```
HA-DR-App
|- app.py
|- requirements.py
```

<br>

### Build Pipeline:

```azure-pipelines.yml```:
```
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

stages:
- stage: Build
  displayName: 'Build Stage'
  jobs:
  - job: Build
    steps:
    - task: UsePythonVersion@0
      inputs:
        versionSpec: '3.x'
        addToPath: true
        architecture: 'x64'
    - task: Bash@3
      displayName: Setting up python env
      inputs:
        targetType: 'inline'
        script: |
          # Write your commands here
          
          python -m venv antenv
          source antenv/bin/activate
        workingDirectory: '$(Build.BinariesDirectory)'

    - task: Bash@3
      displayName: Installing Libraries
      inputs:
        targetType: 'inline'
        script: |
          # Write your commands here
      
          ls -la
          pip install -r requirements.txt
        workingDirectory: '$(Build.SourcesDirectory)/HA-DR-App'

    - task: ArchiveFiles@2
      displayName: Archiving python into Zip
      inputs:
        rootFolderOrFile: '$(Build.SourcesDirectory)/HA-DR-App'
        includeRootFolder: false
        archiveType: 'zip'
        archiveFile: '$(Build.ArtifactStagingDirectory)/$(Build.BuildId).zip'
        replaceExistingArchive: true

    - task: PublishBuildArtifacts@1
      displayName: Publishing Artifacts
      inputs:
        PathtoPublish: '$(Build.ArtifactStagingDirectory)'
        ArtifactName: 'drop'
        publishLocation: 'Container'
```

Ab is YAMl pipeline ko step-by-step samjhte hain:

**Task-1: UsePythonVersion@0**:
```
task: UsePythonVersion@0
      inputs:
        versionSpec: '3.x'
        addToPath: true
        architecture: 'x64'
```

Is task mein hum agent par ek particular python version use karna chate hain. Is task se partiular python version use hoga aur path mein add ho jayega, jisse kahi bhi python command likhne par vo run hogi.

<br>

**Task-2: Setting up python env**:
```
task: Bash@3
      displayName: Setting up python env
      inputs:
        targetType: 'inline'
        script: |
          # Write your commands here
          
          python -m venv antenv
          source antenv/bin/activate
        workingDirectory: '$(Build.BinariesDirectory)'
```

Is task mein hum agent par ek python ka virtual environment create kar rahe hain.

Python mein Virtual Environment (venv) ek aisa "isolated" (alag-thalag) folder hota hai jisme aap ek specific project ki saari libraries aur dependencies ko install karte hain.

Sochiye aap do projects par kaam kar rahe hain:
- Project A: Purana project hai, jisme Flask ka version 1.0 chahiye.
- Project B: Naya project hai, jisme Flask ka latest version 3.0 chahiye.

Agar aap venv use nahi karenge, to aap computer mein ek hi version rakh payenge. Ek ko update karenge to doosra project crash ho jayega. Dependency Conflict se bachne ke liye venv zaroori hai.

Jab aap venv activate karte hain:
- Ye aapke PATH ko change kar deta hai taaki python command chalane par venv wala folder use ho.
- Aap jo bhi library install karte hain (pip install), wo sirf us folder ke andar jati hai.

To uper task mein humne ek ```antenv``` virtual environment yani ek alag folder banaya hai, usko activate kiya hai jisse python ki koi bhi library install karne par vo usi folder mein install ho, fir working directory bhi mention kari hai jaha pe ye inline script run hogi.

<br>

**Task-3: Installing Libraries**
```
task: Bash@3
      displayName: Installing Libraries
      inputs:
        targetType: 'inline'
        script: |
          # Write your commands here
      
          ls -la
          pip install -r requirements.txt
        workingDirectory: '$(Build.SourcesDirectory)/HA-DR-App'
```

Is task mein hum requirements.txt file ke ander jo bhi libraries hain unko agent par install kar rahe hain.

<br>

**Task-4: Archiving python into Zip**
```
task: ArchiveFiles@2
      displayName: Archiving python into Zip
      inputs:
        rootFolderOrFile: '$(Build.SourcesDirectory)/HA-DR-App'
        includeRootFolder: false
        archiveType: 'zip'
        archiveFile: '$(Build.ArtifactStagingDirectory)/$(Build.BuildId).zip'
        replaceExistingArchive: true
```

Humko pta hai ki app service par code ko zip ke form mein upload karna hota hai aur app service khud se usko wahi extract kar deti hai, to is task mein hum apne code ko zip file mein convert kar rahe hain.

Humne apna code Azure Repo mein rakha hai, to azure ki pipeline khud se us repo ko agent ki ```$(Build.SourcesDirectory)``` par clone karti hai, humne repo ke ander ek folder create kiya hua hai ```HA-DR-App``` naam se. To ```rootFolderOrFile: '$(Build.SourcesDirectory)/HA-DR-App'``` mein application ka code hoga, usko ye task zip folder mein convert kar dega, fir us zip folder ko is ```archiveFile: '$(Build.ArtifactStagingDirectory)/$(Build.BuildId).zip'``` location aur naam se artifact mein store kar dega.

<br>

**Task-5: Publishing Artifacts**:
```
task: PublishBuildArtifacts@1
      displayName: Publishing Artifacts
      inputs:
        PathtoPublish: '$(Build.ArtifactStagingDirectory)'
        ArtifactName: 'drop'
        publishLocation: 'Container'
```

Is task mein zip folder is ```PathtoPublish: '$(Build.ArtifactStagingDirectory)'``` location par store ho jayega, jisko hum release pipeline mein use karke app service pe deploy karenge.

<br>
<br>

**Create a Service Connection**:

Ab hum azure devops mein ek service connection create karenge jo azure devops ko azure ke app service ko access karne dega.

Iske liye humko azure mein app registration mein ek secret create karna hoga. Fir Azure DevOps mein us secret ko use karke ek service connection use karna hoga.

<br>
<br>

### Release Pipeline:

<img src="https://drive.google.com/uc?export=view&id=1d3eLKIH8LlD3-GlkPsp7p7PQfmCvrKYB" height=450 weight=450>

Ye humari release pipeline hai, Jisme humne pehle artifact ko select kar liya hai, ye vo artifact jisko build pipeline ki last stage pe humne artifact storage mein store karaya tha.

Fir humne do stages banai hain:
- Stage-1: Deploy code on Central Inda App Service.
- Stage-2: Deploy code on South India App Service.

Ek stage Central India region mein bane hue app service par flask app deploy kar rhi hai. Wahi dusri stage South India region mein bane hue app service par flask app deploy kar rhi hai.

Ye dono stage simple zip file ko ```/home/site/wwwroot``` location par zip ko upload kar rhi hain.

<br>

**Stage-1: Deploy code on Central Inda App Service**:

<img src="https://drive.google.com/uc?export=view&id=1_Jy67XWRyR1HWhhBnNg9KwwyB5khh15U" height=450 weight=450>

<br>

**Stage-2: Deploy code on South India App Service**:

<img src="https://drive.google.com/uc?export=view&id=1k-H_N4elQmfy5tPH7iC_kIB6gosn-_ML" height=450 weight=450>
