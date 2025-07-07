# GitHub Pages Deployment Guide

This guide will help you deploy your Flutter web app to GitHub Pages.

## Prerequisites

1. Your Flutter project is pushed to a GitHub repository
2. You have admin access to the repository

## Setup Steps

### 1. Enable GitHub Pages

1. Go to your GitHub repository
2. Click on **Settings** tab
3. Scroll down to **Pages** section in the left sidebar
4. Under **Source**, select **Deploy from a branch**
5. Choose **gh-pages** branch and **/(root)** folder
6. Click **Save**

### 2. Configure GitHub Actions Permissions

1. In your repository **Settings**
2. Go to **Actions** → **General**
3. Under **Workflow permissions**, select **Read and write permissions**
4. Check **Allow GitHub Actions to create and approve pull requests**
5. Click **Save**

### 3. Deploy Your App

The deployment will happen automatically when you push to the `main` branch. The GitHub Actions workflow will:

1. Build your Flutter web app
2. Deploy it to the `gh-pages` branch
3. Make it available at `https://yourusername.github.io/your-repo-name`

### 4. Manual Deployment (Optional)

If you want to deploy manually:

```bash
# Build the web app
flutter build web --release

# The GitHub Actions workflow will handle the deployment automatically
# when you push to main branch
```

## Custom Domain (Optional)

To use a custom domain:

1. Add a `CNAME` file in the `web` folder with your domain
2. Configure your domain's DNS settings
3. Update the GitHub Pages settings with your custom domain

## Troubleshooting

- **Build fails**: Check the Actions tab in your repository for error details
- **Page not loading**: Ensure the `gh-pages` branch exists and contains the built files
- **Assets not loading**: Verify all assets are properly referenced in `pubspec.yaml`

## Local Testing

To test your web app locally before deployment:

```bash
flutter run -d chrome
```

This will run your app in Chrome for local testing. 