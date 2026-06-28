#!/bin/bash

echo "📦 Starting Abyss Chat Release Process..."

# Prompt for the version tag
read -p "Enter version tag (e.g., v1.0.0-alpha): " version

# Prompt for a short release message
read -p "Enter release message: " message

# Ask if user wants to build all or specific platforms
read -p "Build all platforms? (y/n): " build_all

if [[ "$build_all" == "y" || "$build_all" == "Y" ]]; then
    build_android=true
    build_linux=true
    build_web=true
    build_windows=true
    build_macos=true
    upload_only=false
else
    # Initialize all as false
    build_android=false
    build_linux=false
    build_web=false
    build_windows=false
    build_macos=false
    upload_only=false
    
    # Show menu for specific builds
    echo ""
    echo "Select which platforms to build:"
    echo "0) Upload only (no build)"
    echo "1) Android APK"
    echo "2) Linux"
    echo "3) Web"
    echo "4) Windows"
    echo "5) macOS"
    echo ""
    
    read -p "Enter your choices (e.g., 1,2,5 or 1 2 5): " choices
    
    # Parse the choices - handle both comma and space separated
    for choice in $(echo "$choices" | tr ',' ' '); do
        case "$choice" in
            0)
                upload_only=true
                ;;
            1)
                build_android=true
                ;;
            2)
                build_linux=true
                ;;
            3)
                build_web=true
                ;;
            4)
                build_windows=true
                ;;
            5)
                build_macos=true
                ;;
            *)
                echo "⚠️  Invalid choice: $choice"
                ;;
        esac
    done
fi

echo ""
if [ "$upload_only" = true ]; then
    echo "⏭️  Skipping builds - upload only mode"
else
    echo "🛠️ Compiling Release Builds..."

    # Build for Android
    if [ "$build_android" = true ]; then
        echo "Building Android APK..."
        flutter build apk --release
        echo "✅ Android APK build complete"
    fi

    # Build for Linux
    if [ "$build_linux" = true ]; then
        echo "Building Linux Native App..."
        flutter build linux --release
        echo "✅ Linux build complete"
    fi

    # Build for Web
    if [ "$build_web" = true ]; then
        echo "Building Web App..."
        flutter build web --release
        echo "✅ Web build complete"
    fi

    # Build for Windows
    if [ "$build_windows" = true ]; then
        echo "Building Windows Native App..."
        flutter build windows --release
        echo "✅ Windows build complete"
    fi

    # Build for macOS
    if [ "$build_macos" = true ]; then
        echo "Building macOS Native App..."
        flutter build macos --release
        echo "✅ macOS build complete"
    fi
fi

echo ""

# add the build files and upload them in release section of github

if [ "$upload_only" = true ]; then
    echo "⏭️  Skipping git operations - upload only mode"
else
    # 1. Stage and commit any lingering changes (including any updated build files if tracked)
    git add .
    git commit -m "chore: prepare for release $version and generate builds"

    # 2. Create an annotated git tag
    git tag -a "$version" -m "$message"

    # 3. Push commits and the new tag to your remote
    echo "🚀 Pushing branch and tags to North-Abyss/abyss_chat..."
    git push origin main
    git push origin "$version"
fi

# 4. Create GitHub Release and upload build files
echo "📤 Creating GitHub release and uploading build files..."

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "⚠️  GitHub CLI (gh) is not installed. Please install it to upload release assets."
    echo "Visit: https://cli.github.com/"
    exit 1
fi

# Create the release on GitHub with the tag
gh release create "$version" \
    --title "Abyss Chat $version" \
    --notes "$message" \
    --repo North-Abyss/abyss_chat

# Upload Android APK
if [ "$upload_only" = true ] || [ "$build_android" = true ]; then
    if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        echo "Uploading Android APK..."
        cp "build/app/outputs/flutter-apk/app-release.apk" "build/app/outputs/flutter-apk/AbyssChat-Android.apk"
        gh release upload "$version" "build/app/outputs/flutter-apk/AbyssChat-Android.apk" \
            --repo North-Abyss/abyss_chat --clobber
    else
        echo "⚠️  Android APK not found at build/app/outputs/flutter-apk/app-release.apk"
    fi
fi

# Upload Linux binary
if [ "$upload_only" = true ] || [ "$build_linux" = true ]; then
    if [ -d "build/linux/x64/release/bundle/" ]; then
        echo "Uploading Linux binary..."
        cd "build/linux/x64/release/bundle/"
        tar -czf "abyss-chat-linux-x64.tar.gz" .
        gh release upload "$version" "abyss-chat-linux-x64.tar.gz" \
            --repo North-Abyss/abyss_chat --clobber
        cd - > /dev/null
    else
        echo "⚠️  Linux bundle not found"
    fi
fi

# Upload Web build
if [ "$upload_only" = true ] || [ "$build_web" = true ]; then
    if [ -d "build/web" ]; then
        echo "Uploading Web build..."
        cd "build/web"
        tar -czf "abyss-chat-web.tar.gz" .
        gh release upload "$version" "abyss-chat-web.tar.gz" \
            --repo North-Abyss/abyss_chat --clobber
        cd - > /dev/null
    else
        echo "⚠️  Web build not found"
    fi
fi

# Upload Windows binary
if [ "$upload_only" = true ] || [ "$build_windows" = true ]; then
    if [ -d "build/windows/x64/runner/Release/" ]; then
        echo "Uploading Windows binary..."
        cd "build/windows/x64/runner/Release/"
        tar -czf "abyss_chat-windows-x64.zip" .
        gh release upload "$version" "abyss_chat-windows-x64.zip" \
            --repo North-Abyss/abyss_chat --clobber
        cd - > /dev/null
    else
        echo "⚠️  Windows build not found"
    fi
fi

# Upload macOS binary
if [ "$upload_only" = true ] || [ "$build_macos" = true ]; then
    if [ -d "build/macos/Build/Products/Release/" ]; then
        echo "Uploading macOS binary..."
        cd "build/macos/Build/Products/Release/"
        tar -czf "abyss-chat-macos-x64.tar.gz" .
        gh release upload "$version" "abyss-chat-macos-x64.tar.gz" \
            --repo North-Abyss/abyss_chat --clobber
        cd - > /dev/null
    else
        echo "⚠️  macOS build not found"
    fi
fi

echo ""
if [ "$upload_only" = true ]; then
    echo "✅ Release $version created and uploaded successfully (upload-only mode)!"
else
    echo "✅ Release $version created and uploaded successfully!"
fi
echo "🔗 View release at: https://github.com/North-Abyss/abyss_chat/releases/tag/$version"
echo "📋 Uploaded assets:"
[ -f "build/app/outputs/flutter-apk/app-release.apk" ] && echo "   ✓ Android: AbyssChat-Android.apk"
[ -d "build/linux/x64/release/bundle/" ] && echo "   ✓ Linux: abyss-chat-linux-x64.tar.gz"
[ -d "build/web" ] && echo "   ✓ Web: abyss-chat-web.tar.gz"
[ -d "build/windows/x64/runner/Release/" ] && echo "   ✓ Windows: abyss_chat-windows-x64.zip"
[ -d "build/macos/Build/Products/Release/" ] && echo "   ✓ macOS: abyss-chat-macos-x64.tar.gz"
