#!/bin/bash
set -e

echo "🚀 GRP2601 Android App প্রজেক্ট তৈরি হচ্ছে..."

# ফোল্ডার স্ট্রাকচার তৈরি
mkdir -p app/src/main/java/com/akter/grpmanager
mkdir -p app/src/main/res/layout
mkdir -p app/src/main/res/drawable
mkdir -p app/src/main/res/values
mkdir -p app/src/main/res/anim
mkdir -p .github/workflows

# ১. Root build.gradle
cat << 'INNER' > build.gradle
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.2.2'
    }
}
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
INNER

# ২. settings.gradle
cat << 'INNER' > settings.gradle
rootProject.name = "GRP2601Manager"
include ':app'
INNER

# ৩. gradle.properties
cat << 'INNER' > gradle.properties
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.enableJetifier=true
INNER

# ৪. app/build.gradle
cat << 'INNER' > app/build.gradle
plugins {
    id 'com.android.application'
}

android {
    namespace 'com.akter.grpmanager'
    compileSdk 34

    defaultConfig {
        applicationId "com.akter.grpmanager"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            minifyEnabled false
            signingConfig signingConfigs.debug
        }
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'androidx.swiperefreshlayout:swiperefreshlayout:1.1.0'
}
INNER

# ৫. AndroidManifest.xml (HTTP লোকাল আইপি অ্যাক্সেসের জন্য usesCleartextTraffic=true)
cat << 'INNER' > app/src/main/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />

    <application
        android:allowBackup="true"
        android:icon="@drawable/ic_grp_logo"
        android:label="GRP2601 Manager"
        android:usesCleartextTraffic="true"
        android:theme="@style/Theme.GRPManager">

        <activity
            android:name=".SplashActivity"
            android:exported="true"
            android:theme="@style/Theme.GRPManager.NoActionBar">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <activity
            android:name=".MainActivity"
            android:exported="false" />
    </application>
</manifest>
INNER

# ৬. কাস্টম ভেক্টর লোগো (drawable/ic_grp_logo.xml)
cat << 'INNER' > app/src/main/res/drawable/ic_grp_logo.xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="120dp"
    android:height="120dp"
    android:viewportWidth="100"
    android:viewportHeight="100">
    <path
        android:fillColor="#0F172A"
        android:pathData="M50,5 A45,45 0 1,1 49.9,5 Z" />
    <path
        android:strokeColor="#38BDF8"
        android:strokeWidth="4"
        android:fillColor="#00000000"
        android:pathData="M50,12 A38,38 0 1,1 49.9,12 Z" />
    <path
        android:fillColor="#38BDF8"
        android:pathData="M36,32 C33,32 30,35 30,38 C30,55 45,70 62,70 C65,70 68,67 68,64 L68,56 C68,54 66,52 64,52 L56,52 C54,52 52,53 51,55 L48,58 C43,55 39,51 36,46 L39,43 C41,42 42,40 42,38 L42,34 C42,32 40,32 36,32 Z" />
</vector>
INNER

# ৭. লোগো অ্যানিমেশন (anim/logo_anim.xml)
cat << 'INNER' > app/src/main/res/anim/logo_anim.xml
<?xml version="1.0" encoding="utf-8"?>
<set xmlns:android="http://schemas.android.com/apk/res/android"
    android:interpolator="@android:anim/overshoot_interpolator">
    <scale
        android:duration="900"
        android:fromXScale="0.3"
        android:fromYScale="0.3"
        android:pivotX="50%"
        android:pivotY="50%"
        android:toXScale="1.0"
        android:toYScale="1.0" />
    <alpha
        android:duration="800"
        android:fromAlpha="0.0"
        android:toAlpha="1.0" />
</set>
INNER

# ৮. ইউনিক ডার্ক-সায়ান থিম (values/themes.xml)
cat << 'INNER' > app/src/main/res/values/themes.xml
<resources>
    <style name="Theme.GRPManager" parent="Theme.Material3.Dark.NoActionBar">
        <item name="colorPrimary">#38BDF8</item>
        <item name="colorOnPrimary">#0F172A</item>
        <item name="colorSecondary">#0EA5E9</item>
        <item name="android:windowBackground">#0B1120</item>
        <item name="android:statusBarColor">#0B1120</item>
    </style>

    <style name="Theme.GRPManager.NoActionBar" parent="Theme.GRPManager">
        <item name="windowActionBar">false</item>
        <item name="windowNoTitle">true</item>
    </style>
</resources>
INNER

# ৯. স্প্ল্যাশ স্ক্রিন লেআউট (layout/activity_splash.xml)
cat << 'INNER' > app/src/main/res/layout/activity_splash.xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#0B1120"
    android:gravity="center"
    android:orientation="vertical">

    <ImageView
        android:id="@+id/splashLogo"
        android:layout_width="130dp"
        android:layout_height="130dp"
        android:src="@drawable/ic_grp_logo" />

    <TextView
        android:id="@+id/splashTitle"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="20dp"
        android:text="GRP2601 CONTROL"
        android:textColor="#38BDF8"
        android:textSize="22sp"
        android:textStyle="bold"
        android:letterSpacing="0.12" />

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="6dp"
        android:text="Smart IP Phone Dashboard"
        android:textColor="#94A3B8"
        android:textSize="13sp" />
</LinearLayout>
INNER

# ১০. মেইন ড্যাশবোর্ড লেআউট (layout/activity_main.xml)
cat << 'INNER' > app/src/main/res/layout/activity_main.xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#0B1120"
    android:orientation="vertical"
    android:padding="14dp">

    <!-- টপ বার -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:gravity="center_vertical"
        android:orientation="horizontal"
        android:paddingBottom="10dp">

        <ImageView
            android:layout_width="36dp"
            android:layout_height="36dp"
            android:src="@drawable/ic_grp_logo" />

        <TextView
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_marginStart="10dp"
            android:layout_weight="1"
            android:text="GRP2601 Live Status"
            android:textColor="#F8FAFC"
            android:textSize="19sp"
            android:textStyle="bold" />

        <Button
            android:id="@+id/btnToggleSettings"
            style="@style/Widget.Material3.Button.OutlinedButton"
            android:layout_width="wrap_content"
            android:layout_height="40dp"
            android:text="IP / Login"
            android:textColor="#38BDF8"
            app:strokeColor="#38BDF8" />
    </LinearLayout>

    <!-- সেটিংস ও আইপি ডিটেকশন কার্ড -->
    <com.google.android.material.card.MaterialCardView
        android:id="@+id/cardConfig"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginBottom="12dp"
        app:cardBackgroundColor="#1E293B"
        app:cardCornerRadius="14dp"
        app:strokeColor="#334155"
        app:strokeWidth="1dp">

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:orientation="vertical"
            android:padding="14dp">

            <LinearLayout
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:orientation="horizontal">

                <EditText
                    android:id="@+id/etIp"
                    android:layout_width="0dp"
                    android:layout_height="46dp"
                    android:layout_weight="1"
                    android:background="@android:drawable/edit_text"
                    android:backgroundTint="#0F172A"
                    android:hint="IP (e.g. 192.168.31.48)"
                    android:inputType="textUri"
                    android:paddingHorizontal="12dp"
                    android:textColor="#FFFFFF"
                    android:textColorHint="#64748B"
                    android:textSize="14sp" />

                <Button
                    android:id="@+id/btnAutoScan"
                    android:layout_width="wrap_content"
                    android:layout_height="46dp"
                    android:layout_marginStart="8dp"
                    android:backgroundTint="#0284C7"
                    android:text="Auto Find"
                    android:textColor="#FFFFFF" />
            </LinearLayout>

            <LinearLayout
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:layout_marginTop="8dp"
                android:orientation="horizontal">

                <EditText
                    android:id="@+id/etUser"
                    android:layout_width="0dp"
                    android:layout_height="46dp"
                    android:layout_marginEnd="4dp"
                    android:layout_weight="1"
                    android:background="@android:drawable/edit_text"
                    android:backgroundTint="#0F172A"
                    android:hint="Username (admin)"
                    android:paddingHorizontal="12dp"
                    android:textColor="#FFFFFF"
                    android:textColorHint="#64748B"
                    android:textSize="14sp" />

                <EditText
                    android:id="@+id/etPass"
                    android:layout_width="0dp"
                    android:layout_height="46dp"
                    android:layout_marginStart="4dp"
                    android:layout_weight="1"
                    android:background="@android:drawable/edit_text"
                    android:backgroundTint="#0F172A"
                    android:hint="Password"
                    android:inputType="textPassword"
                    android:paddingHorizontal="12dp"
                    android:textColor="#FFFFFF"
                    android:textColorHint="#64748B"
                    android:textSize="14sp" />
            </LinearLayout>

            <Button
                android:id="@+id/btnConnect"
                android:layout_width="match_parent"
                android:layout_height="46dp"
                android:layout_marginTop="10dp"
                android:backgroundTint="#38BDF8"
                android:text="Save &amp; Auto Login"
                android:textColor="#0F172A"
                android:textStyle="bold" />

            <TextView
                android:id="@+id/tvScanStatus"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:layout_marginTop="6dp"
                android:text="Status: Ready"
                android:textColor="#38BDF8"
                android:textSize="12sp" />
        </LinearLayout>
    </com.google.android.material.card.MaterialCardView>

    <!-- ডাটা ডিসপ্লে WebView (কাস্টম থিম ও অটো-লগইন ইনজেকশনসহ) -->
    <com.google.android.material.card.MaterialCardView
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1"
        app:cardBackgroundColor="#1E293B"
        app:cardCornerRadius="14dp"
        app:strokeColor="#334155"
        app:strokeWidth="1dp">

        <WebView
            android:id="@+id/webView"
            android:layout_width="match_parent"
            android:layout_height="match_parent" />
    </com.google.android.material.card.MaterialCardView>

</LinearLayout>
INNER

# ১১. SplashActivity.java
cat << 'INNER' > app/src/main/java/com/akter/grpmanager/SplashActivity.java
package com.akter.grpmanager;

import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.widget.ImageView;
import androidx.appcompat.app.AppCompatActivity;

public class SplashActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_splash);

        ImageView logo = findViewById(R.id.splashLogo);
        Animation anim = AnimationUtils.loadAnimation(this, R.anim.logo_anim);
        logo.startAnimation(anim);

        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            startActivity(new Intent(SplashActivity.this, MainActivity.class));
            finish();
        }, 1600);
    }
}
INNER

# ১২. MainActivity.java (অটো আইপি স্ক্যানার + অটো লগইন + কাস্টম UI)
cat << 'INNER' > app/src/main/java/com/akter/grpmanager/MainActivity.java
package com.akter.grpmanager;

import android.content.Context;
import android.content.SharedPreferences;
import android.net.wifi.WifiManager;
import android.os.Bundle;
import android.text.format.Formatter;
import android.view.View;
import android.webkit.CookieManager;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.material.card.MaterialCardView;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends AppCompatActivity {

    private EditText etIp, etUser, etPass;
    private TextView tvScanStatus;
    private WebView webView;
    private MaterialCardView cardConfig;
    private SharedPreferences prefs;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        prefs = getSharedPreferences("GRP_PREFS", MODE_PRIVATE);

        etIp = findViewById(R.id.etIp);
        etUser = findViewById(R.id.etUser);
        etPass = findViewById(R.id.etPass);
        tvScanStatus = findViewById(R.id.tvScanStatus);
        webView = findViewById(R.id.webView);
        cardConfig = findViewById(R.id.cardConfig);

        Button btnAutoScan = findViewById(R.id.btnAutoScan);
        Button btnConnect = findViewById(R.id.btnConnect);
        Button btnToggleSettings = findViewById(R.id.btnToggleSettings);

        // সেভ করা ডাটা লোড
        String savedIp = prefs.getString("ip", "192.168.31.48");
        String savedUser = prefs.getString("user", "admin");
        String savedPass = prefs.getString("pass", "");

        etIp.setText(savedIp);
        etUser.setText(savedUser);
        etPass.setText(savedPass);

        setupWebView();

        // যদি আগে থেকেই পাসওয়ার্ড সেভ থাকে তবে কার্ড হাইড করে সরাসরি কানেক্ট হবে
        if (!savedPass.isEmpty()) {
            cardConfig.setVisibility(View.GONE);
            connectToPhone(savedIp);
        }

        btnToggleSettings.setOnClickListener(v -> {
            if (cardConfig.getVisibility() == View.VISIBLE) {
                cardConfig.setVisibility(View.GONE);
            } else {
                cardConfig.setVisibility(View.VISIBLE);
            }
        });

        btnAutoScan.setOnClickListener(v -> scanNetworkForGRP());

        btnConnect.setOnClickListener(v -> {
            String ip = etIp.getText().toString().trim();
            String user = etUser.getText().toString().trim();
            String pass = etPass.getText().toString().trim();

            if (ip.isEmpty()) {
                Toast.makeText(this, "IP দিন বা Auto Find চাপুন", Toast.LENGTH_SHORT).show();
                return;
            }

            prefs.edit()
                .putString("ip", ip)
                .putString("user", user)
                .putString("pass", pass)
                .apply();

            cardConfig.setVisibility(View.GONE);
            connectToPhone(ip);
        });
    }

    private void setupWebView() {
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setLoadWithOverviewMode(true);
        settings.setUseWideViewPort(true);
        CookieManager.getInstance().setAcceptCookie(true);

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                String user = prefs.getString("user", "admin");
                String pass = prefs.getString("pass", "");

                // লগইন পেইজ হলে অটো ফিল ও সাবমিট + ডার্ক কাস্টম থিম ইনজেক্ট
                String js = "javascript:(function() {" +
                        "var inputs = document.getElementsByTagName('input');" +
                        "var uField = null, pField = null;" +
                        "for(var i=0; i<inputs.length; i++) {" +
                        "  if(inputs[i].type === 'text') uField = inputs[i];" +
                        "  if(inputs[i].type === 'password') pField = inputs[i];" +
                        "}" +
                        "if(uField && pField && '" + pass + "' !== '') {" +
                        "  uField.value = '" + user + "';" +
                        "  uField.dispatchEvent(new Event('input', { bubbles: true }));" +
                        "  pField.value = '" + pass + "';" +
                        "  pField.dispatchEvent(new Event('input', { bubbles: true }));" +
                        "  var btns = document.querySelectorAll('button, input[type=submit]');" +
                        "  if(btns.length > 0) setTimeout(function(){ btns[0].click(); }, 400);" +
                        "}" +
                        "})()";
                view.evaluateJavascript(js, null);
                tvScanStatus.setText("Connected: " + url);
            }
        });
    }

    private void connectToPhone(String ip) {
        String url = ip.startsWith("http") ? ip : "http://" + ip;
        tvScanStatus.setText("Connecting to " + url + "...");
        webView.loadUrl(url);
    }

    private void scanNetworkForGRP() {
        tvScanStatus.setText("Scanning Wi-Fi subnet for GRP2601...");
        WifiManager wm = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);
        int ipAddress = wm.getConnectionInfo().getIpAddress();
        String deviceIp = Formatter.formatIpAddress(ipAddress);

        if (deviceIp == null || deviceIp.equals("0.0.0.0")) {
            tvScanStatus.setText("Wi-Fi connected নেই! ম্যানুয়ালি IP দিন।");
            return;
        }

        String prefix = deviceIp.substring(0, deviceIp.lastIndexOf(".") + 1);
        ExecutorService executor = Executors.newFixedThreadPool(30);

        for (int i = 1; i < 255; i++) {
            final String testIp = prefix + i;
            executor.execute(() -> {
                try {
                    URL url = new URL("http://" + testIp);
                    HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                    conn.setConnectTimeout(350);
                    conn.setReadTimeout(350);
                    if (conn.getResponseCode() == 200) {
                        BufferedReader in = new BufferedReader(new InputStreamReader(conn.getInputStream()));
                        String line;
                        while ((line = in.readLine()) != null) {
                            if (line.contains("GRP2601") || line.contains("Grandstream")) {
                                runOnUiThread(() -> {
                                    etIp.setText(testIp);
                                    tvScanStatus.setText("Found GRP2601 at: " + testIp);
                                    Toast.makeText(MainActivity.this, "Found: " + testIp, Toast.LENGTH_SHORT).show();
                                });
                                break;
                            }
                        }
                        in.close();
                    }
                    conn.disconnect();
                } catch (Exception ignored) {}
            });
        }
    }
}
INNER

# ১৩. GitHub Actions Workflow (অটোমেটিক APK বিল্ড করার জন্য)
cat << 'INNER' > .github/workflows/build_apk.yml
name: Build GRP2601 Android APK

on:
  push:
    branches: [ "main", "master" ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Setup Gradle
        uses: gradle/actions/setup-gradle@v3
        with:
          gradle-version: '8.4'

      - name: Build Debug APK
        run: gradle assembleDebug

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: GRP2601-Manager-APK
          path: app/build/outputs/apk/debug/app-debug.apk
INNER

echo "✅ সব ফাইল সফলভাবে তৈরি হয়েছে!"
