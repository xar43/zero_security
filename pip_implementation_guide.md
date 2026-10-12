# Android Picture-in-Picture (PiP) Implementation Guide for Flutter

Agar aapko kisi bhi Flutter app mein Picture-in-Picture (PiP) mode implement karna hai (bina kisi third-party "floating window" plugin ya dangerous permissions ke), toh aap Native Android code ka use kar sakte hain. 

Ye approach sabse stable hoti hai aur YouTube/Netflix jaisi apps mein yahi system use hota hai. Yahan step-by-step process samjhaya gaya hai.

---

## Step 1: Android Manifest ko update karna

Sabse pehle Android system ko batana hota hai ki aapki app PiP mode support karti hai.

**File:** `android/app/src/main/AndroidManifest.xml`

Aapko apni main `<activity>` ke andar `android:supportsPictureInPicture="true"` add karna hoga:

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:supportsPictureInPicture="true" <!-- YE LINE ADD KARNI HAI -->
    ... >
```

> [!NOTE] 
> Agar aap Android 14+ devices ko support kar rahe hain aur `PopScope` ko thik se chalana chahte hain (taki back swipe app ko kill na kare), toh `<application>` tag ke andar `android:enableOnBackInvokedCallback="true"` **nahi** hona chahiye, ya phir ise bahut carefully handle karna padta hai.

---

## Step 2: MainActivity (Kotlin/Java) mein Native PiP logic likhna

Flutter directly Android ke window manager se baat nahi kar sakta, isliye hume Kotlin mein Native Channel (MethodChannel) aur PiP trigger likhna padta hai.

**File:** `android/app/src/main/kotlin/.../MainActivity.kt`

Aapko apni `MainActivity` ko is tarah modify karna hai:

```kotlin
package com.your.package.name

import android.app.PictureInPictureParams
import android.content.res.Configuration
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    // Ye channel name aapke Flutter code se match hona chahiye
    private val CHANNEL = "com.your.package/app"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 1. Flutter se aane wali "moveToBackground" request sunna
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "moveToBackground") {
                enterPiP()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    // 2. PiP mode trigger karne ka main function
    private fun enterPiP() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Screen ka aspect ratio set karna (e.g., 16:9 ya 1:1)
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(16, 9))
                .build()
            enterPictureInPictureMode(params)
        } else {
            // Agar purana Android version hai toh sirf app ko minimize kardo
            moveTaskToBack(true)
        }
    }

    // 3. Jab user phone ka "Home" button dabaye toh automatically PiP mein jana
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        enterPiP()
    }

    // 4. Jab app PiP mode mein jaye ya bahar aaye, toh Flutter ko batana (UI change karne ke liye)
    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration?) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        // Flutter ko signal bhej rahe hain "onPipChanged"
        methodChannel?.invokeMethod("onPipChanged", isInPictureInPictureMode)
    }
}
```

> [!TIP]
> `onUserLeaveHint` Android ki life-saver method hai. Jab bhi user app chhodkar home screen par jata hai (app switch karta hai), ye trigger hoti hai. Yahan PiP call karne se YouTube jaisa seamless minimize experience milta hai.

---

## Step 3: Flutter UI (Dart) mein PiP ke hisaab se screen change karna

Ab jab app choti (PiP) ho jayegi, toh hume poori badi screen nahi dikhani hai, sirf zaroori chizein (jaise Timer ya Video) dikhani hain.

**File:** `lib/screens/your_main_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class YourMainScreen extends StatefulWidget {
  @override
  _YourMainScreenState createState() => _YourMainScreenState();
}

class _YourMainScreenState extends State<YourMainScreen> {
  // Same channel name jo Kotlin mein tha
  static const MethodChannel _appChannel = MethodChannel('com.your.package/app');
  
  bool _isPipMode = false;

  @override
  void initState() {
    super.initState();
    
    // Kotlin se aane wale signals (onPipChanged) ko sunna
    _appChannel.setMethodCallHandler((call) async {
      if (call.method == 'onPipChanged') {
        if (mounted) {
          setState(() {
            _isPipMode = call.arguments as bool;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Agar app choti window (PiP) mein hai, toh ek chota minimal UI dikhao
    if (_isPipMode) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "12:45", // Sirf timer
            style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    // Agar normal full screen hai, toh poora dashboard dikhao
    // WillPopScope ya PopScope laga kar back button intercept karo
    return WillPopScope(
      onWillPop: () async {
        // Jab user Back dabaye, toh app ko minimize (PiP) karne ka signal Kotlin ko bhejo
        try {
          await _appChannel.invokeMethod('moveToBackground');
        } catch (e) {
          print("Error entering PiP: $e");
        }
        return false; // Back button se app kill hone se rokna
      },
      child: Scaffold(
        appBar: AppBar(title: Text("Full App Dashboard")),
        body: Center(child: Text("App Content Here")),
      ),
    );
  }
}
```

---

## Summary

1. **AndroidManifest:** PiP support `true` kiya.
2. **Kotlin (MainActivity):** `MethodChannel` banaya aur Home/Back dabne par native `enterPictureInPictureMode()` trigger kiya. Jo UI switch ka signal wapas Flutter ko bhejta hai.
3. **Flutter (Dart):** PiP mode True hote hi `setState` chala kar ek naya chota sa `Scaffold` return kiya jo floating window mein fit ho jaye, aur `WillPopScope` se Back button ko Override kiya.

Yahi best practice hai jisse memory leaks aur crashes nahi hote!
