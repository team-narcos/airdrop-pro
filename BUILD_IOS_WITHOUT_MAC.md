# 🍎 Building iOS IPA without a Mac

Since you're on Windows, here are **3 FREE methods** to build your iOS app:

---

## ✅ Method 1: GitHub Actions (RECOMMENDED - 100% Free)

### Requirements:
- GitHub account (free)
- Push your project to GitHub

### Steps:

1. **Create GitHub Repository:**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/YOUR_USERNAME/airdrop-app.git
   git push -u origin main
   ```

2. **The workflow file is already created:** `.github/workflows/build-ios.yml`

3. **Trigger the build:**
   - Go to your GitHub repository
   - Click "Actions" tab
   - Click "Build iOS IPA" workflow
   - Click "Run workflow" button
   - Wait 10-15 minutes

4. **Download your IPA:**
   - After build completes, go to the workflow run
   - Scroll down to "Artifacts" section
   - Download "iOS-IPA" (will be a .zip file)
   - Extract to get `airdrop-app.ipa`

### Advantages:
- ✅ Completely FREE
- ✅ 2000 minutes/month free tier
- ✅ No credit card needed
- ✅ Automatic on every push
- ✅ Can trigger manually anytime

---

## ✅ Method 2: Codemagic (Free tier)

### Requirements:
- Codemagic account (free): https://codemagic.io
- GitHub/GitLab/Bitbucket repository

### Steps:

1. **Sign up at Codemagic:**
   - Go to https://codemagic.io/signup
   - Sign up with GitHub (free)

2. **Connect your repository:**
   - Push project to GitHub first
   - In Codemagic, click "Add application"
   - Select your repository
   - Choose Flutter project type

3. **The config file is ready:** `codemagic.yaml`
   - Edit line 38 to add your email
   
4. **Start build:**
   - Click "Start new build"
   - Select "ios-workflow"
   - Wait 10-15 minutes
   - Download IPA from artifacts

### Advantages:
- ✅ 500 build minutes/month free
- ✅ Easier UI than GitHub Actions
- ✅ Built specifically for Flutter
- ✅ Email notifications

---

## ✅ Method 3: AppCircle (Free tier)

### Requirements:
- AppCircle account: https://appcircle.io
- Repository (GitHub/GitLab/Bitbucket)

### Steps:

1. **Sign up:** https://appcircle.io/signup

2. **Create new build profile:**
   - Select Flutter as framework
   - Connect your repository
   - Select iOS as platform

3. **Configure build:**
   - Build configuration: Release
   - Flutter version: 3.35.6
   - Build command: `flutter build ios --release --no-codesign`

4. **Start build and download IPA**

### Advantages:
- ✅ 30 build minutes/month free
- ✅ Simple UI
- ✅ Good for testing

---

## 🚀 Quick Start (Recommended: GitHub Actions)

### Option A: If you already have GitHub repo

```bash
# Already created the workflow file for you!
git add .github/workflows/build-ios.yml
git commit -m "Add iOS build workflow"
git push

# Then go to GitHub → Actions → Run workflow
```

### Option B: If starting fresh

```bash
# 1. Initialize git
git init

# 2. Create new repo on github.com (don't add README)

# 3. Push your code
git add .
git commit -m "Initial commit with iOS build workflow"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/airdrop-app.git
git push -u origin main

# 4. Go to github.com → Your Repo → Actions → "Build iOS IPA" → Run workflow
```

---

## 📦 What You'll Get

The build will create an **unsigned IPA** file:
- **File:** `airdrop-app.ipa`
- **Size:** ~100-200 MB
- **Type:** Unsigned (for testing only)

### Can I install this IPA?

**Yes, but with limitations:**

1. **On your own iPhone:**
   - Use tools like AltStore, Sideloadly, or Xcode (requires Mac)
   - Valid for 7 days only (free Apple ID)
   
2. **TestFlight (requires Apple Developer account - $99/year):**
   - Need to sign the IPA with certificates
   - Can distribute to 10,000 testers

3. **For development/testing:**
   - The unsigned IPA works with simulators
   - Good for demonstrations

---

## 🎯 My Recommendation

**Use GitHub Actions (Method 1)** because:
1. ✅ Completely free forever
2. ✅ Most build minutes (2000/month)
3. ✅ No credit card needed
4. ✅ I've already created the workflow file
5. ✅ Just push to GitHub and click "Run workflow"

**Time to first IPA: 15 minutes** (mostly waiting for GitHub to build)

---

## 🆘 Troubleshooting

### Build fails in GitHub Actions:

**Error: "Could not find Info.plist"**
- Solution: Check `ios/Runner/Info.plist` exists

**Error: "CocoaPods not installed"**
- Solution: Already handled in workflow, shouldn't happen

**Error: "Flutter version mismatch"**
- Solution: Edit `.github/workflows/build-ios.yml` line 19, change Flutter version

### Can't push to GitHub:

```bash
# If you get authentication error, use Personal Access Token:
# 1. Go to GitHub → Settings → Developer settings → Personal access tokens
# 2. Generate new token with 'repo' permissions
# 3. Use token as password when pushing
```

---

## 📧 Need Help?

1. Check GitHub Actions logs for errors
2. Verify `pubspec.yaml` has correct iOS configuration
3. Ensure no iOS-specific plugin errors

---

## ⚡ Next Steps

After you get the IPA:
1. Test on iOS Simulator (requires Mac/Cloud Mac)
2. Or use a cloud testing service like BrowserStack
3. Or distribute via TestFlight (requires Apple Developer account)

---

**STATUS:** ✅ Android APK ready | 🔄 iOS IPA can be built via cloud (GitHub Actions recommended)
