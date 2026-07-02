# 🌐 Web Deployment Branch (`gh-pages`)

This branch contains the compiled, production-ready web build of the application.
Go to [North-Abyss/abyss_chat](https://github.com/North-Abyss/abyss_chat) for the source code.

> [!WARNING]
> **Do not edit files in this branch manually.** 
> This branch is automatically generated and forcefully updated by the deployment scripts. Any manual changes made here will be permanently overwritten on the next deployment.

## 🚀 Live Preview
The web version of this application is automatically hosted via GitHub Pages. 
You can view the live application here: **[Insert GitHub Pages URL]**

## 🛠️ How it works
1. The source code resides in the `main` branch.
2. The deployment script (e.g., `flutter build web`) compiles the application.
3. The contents of the `build/web/` directory are forcefully pushed to this `gh-pages` branch.
4. GitHub Pages serves the static files directly from this branch.

---
*For the actual source code, please switch to the `main` branch.*