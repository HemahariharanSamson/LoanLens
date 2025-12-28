# GitHub Setup Instructions

Follow these steps to push your LoanLens app to GitHub.

## Step 1: Create a GitHub Repository

1. Go to [GitHub](https://github.com) and sign in
2. Click the **"+"** icon in the top right corner
3. Select **"New repository"**
4. Fill in the details:
   - **Repository name**: `LoanLens` (or your preferred name)
   - **Description**: "Offline-first Flutter app for tracking and analyzing loans"
   - **Visibility**: Choose Public or Private
   - **DO NOT** initialize with README, .gitignore, or license (we already have these)
5. Click **"Create repository"**

## Step 2: Add Remote and Push

After creating the repository, GitHub will show you commands. Use these commands in your terminal:

### Option A: If you haven't pushed anything yet (Recommended)

```bash
cd D:\hhh\apps\LoanTracker

# Add your GitHub repository as remote (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/LoanLens.git

# Rename main branch if needed (GitHub uses 'main' by default)
git branch -M main

# Push code and tags to GitHub
git push -u origin main
git push origin v1.0.0
```

### Option B: If you prefer SSH

```bash
cd D:\hhh\apps\LoanTracker

# Add remote using SSH (replace YOUR_USERNAME with your GitHub username)
git remote add origin git@github.com:YOUR_USERNAME/LoanLens.git

# Rename main branch if needed
git branch -M main

# Push code and tags
git push -u origin main
git push origin v1.0.0
```

## Step 3: Verify

1. Go to your GitHub repository page
2. You should see all your files
3. Check the "Releases" section - you should see v1.0.0 tag

## Step 4: Create a Release (Optional but Recommended)

1. Go to your repository on GitHub
2. Click on **"Releases"** (right sidebar)
3. Click **"Create a new release"**
4. Select tag: **v1.0.0**
5. Release title: **"LoanLens v1.0.0 - Initial Release"**
6. Description:
   ```
   ## 🎉 Initial Release
   
   First stable release of LoanLens - Offline-first loan tracking app.
   
   ### Features
   - Loan management (CRUD)
   - Past payments support
   - Early closure functionality
   - Analytics dashboard with charts
   - Local notifications
   - 100% offline functionality
   ```
7. Click **"Publish release"**

## Troubleshooting

### If you get "remote origin already exists"

```bash
# Remove existing remote
git remote remove origin

# Add your remote again
git remote add origin https://github.com/YOUR_USERNAME/LoanLens.git
```

### If you get authentication errors

**For HTTPS:**
- GitHub now requires Personal Access Token instead of password
- Generate token: GitHub → Settings → Developer settings → Personal access tokens → Generate new token
- Use token as password when prompted

**For SSH:**
- Set up SSH keys: https://docs.github.com/en/authentication/connecting-to-github-with-ssh

### If branch name is different

```bash
# Check current branch name
git branch

# If it's 'master', rename to 'main'
git branch -M main

# Then push
git push -u origin main
```

## Future Updates

After making changes to your code:

```bash
# Stage changes
git add .

# Commit changes
git commit -m "Your commit message"

# Push to GitHub
git push

# Create new version tag (when releasing new version)
git tag -a v1.1.0 -m "Version 1.1.0 - New features"
git push origin v1.1.0
```

---

**Need Help?** Check GitHub documentation: https://docs.github.com

