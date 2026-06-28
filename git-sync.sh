#!/bin/bash

# Git Commit & Sync Script - /git-sync.sh
# Syncs local repository with remote and optionally triggers Cloud CI/CD

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Abyss Chat git sync...${NC}"

# Stage all changes
echo -e "${BLUE}Staging changes...${NC}"
git add .

commit_message="Auto-update : Fixes "
# Commit changes
echo -e "${BLUE}Committing changes...${NC}"
read -p "Enter commit message: " commit_message
git commit -m "$commit_message" || echo "No changes to commit"

# Fetch latest changes from remote (this also fetches the latest tags)
echo -e "${BLUE}Fetching from remote...${NC}"
git fetch origin

# Pull latest changes to current branch
echo -e "${BLUE}Pulling changes...${NC}"
git pull origin "$(git rev-parse --abbrev-ref HEAD)"

# Push local commits to remote
echo -e "${BLUE}Pushing changes...${NC}"
git push origin "$(git rev-parse --abbrev-ref HEAD)"

echo -e "${GREEN}Git sync completed successfully!${NC}"
echo ""

# ==========================================
# 🚀 CLOUD PIPELINE TRIGGER
# ==========================================
echo -e "${YELLOW}--- Release Manager ---${NC}"
read -p "Do you want to trigger a Cloud Release for these changes? (y/n): " trigger_release

if [[ "$trigger_release" == "y" || "$trigger_release" == "Y" ]]; then
    read -p "Enter version tag (e.g., v1.0.0 or v0.0.0 for testing): " version_tag
    
    echo -e "${BLUE}Preparing tag $version_tag...${NC}"
    
    # Check if the tag already exists (we fetched earlier, so local knowledge is up-to-date)
    if git rev-parse -q --verify "refs/tags/$version_tag" >/dev/null; then
        echo -e "${RED}Warning: Tag '$version_tag' already exists!${NC}"
        read -p "Can I remove it and replace it with the current code? (y/n): " replace_tag
        
        if [[ "$replace_tag" == "y" || "$replace_tag" == "Y" ]]; then
            echo -e "${YELLOW}Deleting old tag '$version_tag'...${NC}"
            git tag -d "$version_tag" 2>/dev/null || true
            git push origin --delete "$version_tag" 2>/dev/null || true
        else
            echo -e "${BLUE}Release aborted to protect the existing tag. Have a great day!${NC}"
            exit 0
        fi
    fi
    
    # Create the brand new tag on the current code
    echo -e "${BLUE}Tagging current code as $version_tag...${NC}"
    git tag "$version_tag"
    
    # Push the new tag to GitHub to wake up the CI/CD servers
    git push origin "$version_tag"
    
    echo -e "${GREEN}Boom! Release tag pushed.${NC}"
    echo -e "${GREEN}The GitHub Cloud Servers are now compiling your apps!${NC}"
else
    echo -e "${BLUE}Skipping release. Have a great day!${NC}"
fi

# ==========================================
# 🌐 GITHUB PAGES WEB DEPLOY
# ==========================================
echo -e "${YELLOW}--- Web Deploy (GitHub Pages) ---${NC}"
read -p "Do you want to deploy the Web PWA to GitHub Pages? (y/n): " deploy_web

if [[ "$deploy_web" == "y" || "$deploy_web" == "Y" ]]; then
    # 1. Capture the remote URL of your repo so we know where to push
    REMOTE_URL=$(git config --get remote.origin.url)
    
    echo -e "${BLUE}Preparing Flutter Web Deployment...${NC}"
    
    # Optional Build Step
    read -p "Do you want to compile a fresh web build? (y/n): " web_build
    if [[ "$web_build" == "y" || "$web_build" == "Y" ]]; then
        echo -e "${BLUE}Cleaning build cache and Compiling for Web (JavaScript)...${NC}"
        flutter clean
        flutter pub get
        # CRITICAL: The base-href MUST match your GitHub repository name! 
        flutter build web --release --base-href "/abyss_chat/"
    fi

    echo -e "${BLUE}Pushing compiled web app to 'gh-pages' branch...${NC}"
    
    # 2. Go into the compiled web folder
    cd build/web
    
    # 3. Create a temporary git repo just for these compiled files
    rm -rf .git # <--- THE FIX: Nuke any leftover git history to prevent crashes
    git init
    git checkout -b gh-pages
    git add .
    git commit -m "Auto-Deploy Web PWA"
    
    # 4. Force push ONLY this folder to the gh-pages branch on GitHub
    git push -f $REMOTE_URL gh-pages
    
    # 5. Clean up and return to the main project folder
    rm -rf .git
    cd ../..
    
    echo -e "${GREEN}Web deployment pushed! Your PWA will be live shortly.${NC}"
else
    echo -e "${BLUE}Skipping Web Deploy.${NC}"
fi
