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

- Automated Deployment (CI/CD):
  - Azure DevOps.
  - GitHub Actions.
  - BitBucket/GitLab.
 
