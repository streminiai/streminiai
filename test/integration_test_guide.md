# 🧪 Stremini AI - Integration Testing Guide

Complete guide for testing your Stremini AI app before production.

---

## 📋 Pre-Testing Checklist

### 1. **Setup Environment**
```bash
# Install dependencies
flutter pub get

# Clean build
flutter clean
flutter pub get

# Check for issues
flutter doctor
```

### 2. **Update Configuration**
- ✅ Verify `pubspec.yaml` has all dependencies
- ✅ Check `AndroidManifest.xml` has all permissions
- ✅ Verify API URL in `lib/config/api_constants.dart`

---

## 🧪 Testing Phases

### **Phase 1: Build & Run** (5 min)

```bash
# Connect Android device or start emulator
flutter devices

# Build and run
flutter run --release
```

**Expected Result**: App should launch successfully

---

### **Phase 2: Permissions Testing** (10 min)

#### Test Onboarding Flow
1. Open app (first launch)
2. See onboarding screen
3. Click through permission cards
4. Grant permissions:
   - ✅ Overlay permission (draw over apps)
   - ✅ Accessibility permission
   - ✅ Microphone permission

#### Verify Each Permission
```
Settings → Apps → Stremini AI → Permissions
- Display over other apps: ✓ Allowed
- Accessibility: ✓ Enabled
- Microphone: ✓ Allowed
```

---

### **Phase 3: Feature Testing** (30 min)

#### **Feature 1: Floating Widget** 
1. Launch app → Home screen
2. Tap "Start" button
3. **Expected**: Floating bubble appears
4. **Test**: 
   - Drag bubble around screen ✓
   - Tap bubble → Opens menu ✓
   - Bubble stays on top of other apps ✓

#### **Feature 2: AI Chat**
1. Tap floating bubble
2. Select "AI Chat"
3. **Test Chat**:
   - Type message → Send ✓
   - See typing indicator ✓
   - Receive AI response ✓
   - Try suggestions chips ✓
   - Long press message → Copy ✓

#### **Feature 3: Translation**
1. Open any app with text (e.g., Chrome)
2. Tap floating bubble → "Translate"
3. **Test Translation**:
   - Select language ✓
   - See screen content translated ✓
   - Translation overlay appears ✓

#### **Feature 4: Security Scanner**
1. Tap floating bubble → "Security Scan"
2. Copy suspicious text/URL
3. **Test Scanning**:
   - Paste content ✓
   - Tap "Scan" ✓
   - See security results ✓
   - Check threat indicators ✓

#### **Feature 5: AI Keyboard**
1. Open any text input (e.g., Messages app)
2. Tap floating bubble → "AI Keyboard"
3. **Test Keyboard**:
   - Type partial text ✓
   - Tap "Complete" → Get suggestions ✓
   - Try "Change Tone" ✓
   - Try "Translate" ✓
   - Copy result ✓

#### **Feature 6: Voice Commands**
1. Tap floating bubble → "Voice Commands"
2. Grant microphone permission (if needed)
3. **Test Voice**:
   - Speak command ✓
   - See recognized text ✓
   - Get AI action ✓

---

### **Phase 4: API Testing** (15 min)

#### Test Backend Connection
```bash
# Test chat endpoint
curl -X POST https://ai-keyboard-backend.vishwajeetadkine705.workers.dev/chat/message \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello"}'

# Expected: JSON response with AI reply
```

#### In-App API Tests
1. **Chat**: Send 5 different messages
   - Verify all responses work ✓
   - Check response time < 5 seconds ✓

2. **Translation**: Test 3 languages
   - English → Hindi ✓
   - English → Spanish ✓
   - English → French ✓

3. **Security**: Test 5 samples
   - Normal text: Low threat ✓
   - Suspicious link: High threat ✓
   - Phishing text: High threat ✓

4. **Keyboard**: Test all actions
   - Complete text ✓
   - Change tone ✓
   - Translate ✓

---

### **Phase 5: UI/UX Testing** (10 min)

#### Visual Tests
- ✅ Dark theme applied everywhere
- ✅ Colors match design (teal primary)
- ✅ Text readable on all backgrounds
- ✅ Icons visible and appropriate size
- ✅ Animations smooth (60fps)
- ✅ Loading indicators show during API calls
- ✅ Error messages display correctly

#### Interaction Tests
- ✅ Buttons give haptic feedback
- ✅ Scroll lists smoothly
- ✅ Tap targets are big enough (48dp min)
- ✅ Swipe gestures work
- ✅ Long press actions work
- ✅ Keyboard dismisses properly

---

### **Phase 6: Edge Cases** (10 min)

#### Network Issues
1. Turn off WiFi/Data
2. Try sending message
3. **Expected**: Error message shown ✓
4. Turn on network
5. Retry → Should work ✓

#### Permission Denied
1. Revoke overlay permission
2. Try opening floating widget
3. **Expected**: Permission prompt ✓

#### Low Memory
1. Open 10+ apps in background
2. Use Stremini AI
3. **Expected**: No crashes ✓

#### Long Text
1. Send 2000 character message
2. **Expected**: Handles gracefully ✓

#### Rapid Tapping
1. Tap buttons quickly 10 times
2. **Expected**: No double actions ✓

---

## 🐛 Common Issues & Fixes

### Issue 1: Floating Widget Not Appearing
**Cause**: Overlay permission not granted  
**Fix**: 
```
Settings → Apps → Stremini AI → Display over other apps → Allow
```

### Issue 2: No AI Response
**Cause**: API connection issue  
**Fix**: 
- Check internet connection
- Verify API URL in `api_constants.dart`
- Test API directly with curl

### Issue 3: Accessibility Not Working
**Cause**: Service not enabled  
**Fix**:
```
Settings → Accessibility → Stremini AI → Enable
```

### Issue 4: App Crashes on Launch
**Cause**: Missing dependency or build issue  
**Fix**:
```bash
flutter clean
flutter pub get
flutter run --release
```

### Issue 5: Keyboard Overlay Not Showing
**Cause**: Overlay library issue  
**Fix**: Check `flutter_overlay_window` setup in MainActivity

---

## 📊 Performance Benchmarks

### Expected Metrics
- **App Size**: < 50 MB
- **Launch Time**: < 3 seconds
- **API Response**: < 5 seconds
- **Memory Usage**: < 150 MB
- **Battery Drain**: < 5%/hour (idle)

### Test Performance
```bash
# Check app size
flutter build apk --release
ls -lh build/app/outputs/flutter-apk/

# Profile performance
flutter run --profile
# Open DevTools → Performance tab
```

---

## ✅ Final Checklist

### Before Production
- [ ] All features tested and working
- [ ] No crashes or critical bugs
- [ ] API endpoints responding
- [ ] Permissions working correctly
- [ ] UI looks good on different screen sizes
- [ ] Dark theme applied consistently
- [ ] Haptic feedback working
- [ ] Loading states showing
- [ ] Error messages clear and helpful
- [ ] Tested on real device (not just emulator)
- [ ] Tested on Android 6.0+ devices
- [ ] Battery usage acceptable
- [ ] App icon looks good
- [ ] App name displays correctly

### Production Build
```bash
# Generate release APK
flutter build apk --release

# Or generate App Bundle for Play Store
flutter build appbundle --release
```

---

## 📱 Device Testing Matrix

### Minimum Test Devices
1. **Android 6.0** (Min SDK 23)
2. **Android 10** (Common version)
3. **Android 13+** (Latest)

### Screen Sizes
- Small: 5.0" (720x1280)
- Medium: 6.0" (1080x1920)
- Large: 6.5"+ (1440x2960)

---

## 🎯 Success Criteria

Your app is ready for production when:

✅ All 5 features work perfectly  
✅ No crashes in 30 minutes of testing  
✅ API responds in < 5 seconds  
✅ Floating widget stable on all apps  
✅ Permissions flow smooth  
✅ UI looks professional  
✅ Dark theme consistent  
✅ Performance meets benchmarks  

---

## 📞 Support During Testing

### If You Find Bugs
1. Note the exact steps to reproduce
2. Check device logs:
```bash
flutter logs
# or
adb logcat | grep flutter
```
3. Take screenshots
4. Document error messages

### Debugging Commands
```bash
# Check running app
flutter run --verbose

# Hot reload
r (in terminal)

# Hot restart
R (in terminal)

# Profile mode
flutter run --profile

# Check build issues
flutter doctor -v
```

---

## 🎉 Testing Complete!

Once all tests pass:
1. ✅ Generate production build
2. ✅ Test production APK
3. ✅ Prepare Play Store listing
4. ✅ Submit for review

**Congratulations! Your app is production-ready! 🚀**
