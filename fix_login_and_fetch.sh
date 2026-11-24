#!/bin/bash
set -e

echo "🚀 হাইব্রিড লগইন + নেটিভ ডাটা ফেচ ড্যাশবোর্ড আপডেট হচ্ছে..."

# ১. activity_main.xml আপডেট (লগইন ওয়েবপেজ ও নেটিভ ড্যাশবোর্ড উভয়ের কন্টেইনার)
cat << 'INNER' > app/src/main/res/layout/activity_main.xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#0B1120"
    android:orientation="vertical"
    android:padding="14dp">

    <!-- টপ হেডার -->
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

        <LinearLayout
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_marginStart="10dp"
            android:layout_weight="1"
            android:orientation="vertical">

            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="GRP2601 Control"
                android:textColor="#F8FAFC"
                android:textSize="18sp"
                android:textStyle="bold" />

            <TextView
                android:id="@+id/tvConnectionBadge"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="● Ready"
                android:textColor="#38BDF8"
                android:textSize="12sp" />
        </LinearLayout>

        <Button
            android:id="@+id/btnRefresh"
            style="@style/Widget.Material3.Button.TonalButton"
            android:layout_width="wrap_content"
            android:layout_height="40dp"
            android:layout_marginEnd="6dp"
            android:text="Refresh"
            android:textSize="12sp" />

        <Button
            android:id="@+id/btnToggleIp"
            style="@style/Widget.Material3.Button.OutlinedButton"
            android:layout_width="wrap_content"
            android:layout_height="40dp"
            android:text="IP"
            android:textColor="#38BDF8"
            android:textSize="12sp"
            app:strokeColor="#38BDF8" />
    </LinearLayout>

    <!-- IP সেটিংস ও অটো ডিটেক্ট বার -->
    <com.google.android.material.card.MaterialCardView
        android:id="@+id/cardIpSetup"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginBottom="10dp"
        android:visibility="gone"
        app:cardBackgroundColor="#1E293B"
        app:cardCornerRadius="12dp"
        app:strokeColor="#334155"
        app:strokeWidth="1dp">

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:orientation="horizontal"
            android:padding="10dp">

            <EditText
                android:id="@+id/etIp"
                android:layout_width="0dp"
                android:layout_height="44dp"
                android:layout_weight="1"
                android:background="@android:drawable/edit_text"
                android:backgroundTint="#0F172A"
                android:hint="192.168.31.48"
                android:inputType="textUri"
                android:paddingHorizontal="10dp"
                android:textColor="#FFFFFF"
                android:textSize="14sp" />

            <Button
                android:id="@+id/btnAutoScan"
                android:layout_width="wrap_content"
                android:layout_height="44dp"
                android:layout_marginStart="6dp"
                android:backgroundTint="#0284C7"
                android:text="Auto"
                android:textColor="#FFFFFF" />

            <Button
                android:id="@+id/btnSaveIp"
                android:layout_width="wrap_content"
                android:layout_height="44dp"
                android:layout_marginStart="6dp"
                android:backgroundTint="#38BDF8"
                android:text="Go"
                android:textColor="#0F172A"
                android:textStyle="bold" />
        </LinearLayout>
    </com.google.android.material.card.MaterialCardView>

    <!-- মেইন কন্টেন্ট এরিয়া (লগইন ওয়েবপেজ এবং নেটিভ কার্ড ড্যাশবোর্ড) -->
    <FrameLayout
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1">

        <!-- ১. লগইন ওয়েবপেজ (শুধুমাত্র লগইন করার সময় সামনে আসবে) -->
        <com.google.android.material.card.MaterialCardView
            android:id="@+id/webLoginContainer"
            android:layout_width="match_parent"
            android:layout_height="match_parent"
            app:cardBackgroundColor="#FFFFFF"
            app:cardCornerRadius="14dp">

            <WebView
                android:id="@+id/webView"
                android:layout_width="match_parent"
                android:layout_height="match_parent" />
        </com.google.android.material.card.MaterialCardView>

        <!-- ২. লগইনের পর সুন্দর নেটিভ কার্ড ড্যাশবোর্ড -->
        <androidx.swiperefreshlayout.widget.SwipeRefreshLayout
            android:id="@+id/swipeRefresh"
            android:layout_width="match_parent"
            android:layout_height="match_parent"
            android:visibility="gone">

            <ScrollView
                android:layout_width="match_parent"
                android:layout_height="match_parent">

                <LinearLayout
                    android:id="@+id/cardsContainer"
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:orientation="vertical"
                    android:paddingBottom="20dp" />
            </ScrollView>
        </androidx.swiperefreshlayout.widget.SwipeRefreshLayout>

    </FrameLayout>
</LinearLayout>
INNER

# ২. MainActivity.java আপডেট (লগইন পেইজ ডিটেকশন + অটো সেশন সেভ + সুন্দর নেটিভ কার্ড)
cat << 'INNER' > app/src/main/java/com/akter/grpmanager/MainActivity.java
package com.akter.grpmanager;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.Typeface;
import android.net.wifi.WifiManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.format.Formatter;
import android.view.View;
import android.webkit.CookieManager;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;
import com.google.android.material.card.MaterialCardView;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends AppCompatActivity {

    private EditText etIp;
    private TextView tvConnectionBadge;
    private WebView webView;
    private MaterialCardView cardIpSetup, webLoginContainer;
    private SwipeRefreshLayout swipeRefresh;
    private LinearLayout cardsContainer;
    private SharedPreferences prefs;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private boolean isExtracting = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        prefs = getSharedPreferences("GRP_PREFS", MODE_PRIVATE);

        etIp = findViewById(R.id.etIp);
        tvConnectionBadge = findViewById(R.id.tvConnectionBadge);
        webView = findViewById(R.id.webView);
        cardIpSetup = findViewById(R.id.cardIpSetup);
        webLoginContainer = findViewById(R.id.webLoginContainer);
        swipeRefresh = findViewById(R.id.swipeRefresh);
        cardsContainer = findViewById(R.id.cardsContainer);

        Button btnToggleIp = findViewById(R.id.btnToggleIp);
        Button btnAutoScan = findViewById(R.id.btnAutoScan);
        Button btnSaveIp = findViewById(R.id.btnSaveIp);
        Button btnRefresh = findViewById(R.id.btnRefresh);

        String savedIp = prefs.getString("ip", "192.168.31.48");
        etIp.setText(savedIp);

        setupWebView();
        loadUrl(savedIp);

        btnToggleIp.setOnClickListener(v ->
            cardIpSetup.setVisibility(cardIpSetup.getVisibility() == View.VISIBLE ? View.GONE : View.VISIBLE)
        );

        btnAutoScan.setOnClickListener(v -> scanNetworkForGRP());

        btnSaveIp.setOnClickListener(v -> {
            String ip = etIp.getText().toString().trim();
            if (!ip.isEmpty()) {
                prefs.edit().putString("ip", ip).apply();
                cardIpSetup.setVisibility(View.GONE);
                loadUrl(ip);
            }
        });

        btnRefresh.setOnClickListener(v -> {
            if (swipeRefresh.getVisibility() == View.VISIBLE) {
                extractDataFromDom();
            } else {
                webView.reload();
            }
        });

        swipeRefresh.setOnRefreshListener(this::extractDataFromDom);
    }

    private void setupWebView() {
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setDatabaseEnabled(true);
        settings.setSaveFormData(true);

        CookieManager cookieManager = CookieManager.getInstance();
        cookieManager.setAcceptCookie(true);
        cookieManager.setAcceptThirdPartyCookies(webView, true);

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                CookieManager.getInstance().flush();
                startPageWatcher();
            }
        });
    }

    // SPA রাউটিং মনিটর: লগইন পেইজ নাকি স্ট্যাটাস পেইজ তা প্রতি ৮০০ms পরপর চেক করবে
    private void startPageWatcher() {
        handler.postDelayed(new Runnable() {
            @Override
            public void run() {
                String checkJs = "(function() {" +
                        "var url = window.location.href;" +
                        "var hasPass = document.querySelector('input[type=password]') !== null;" +
                        "if(hasPass || url.includes('/login')) return 'LOGIN_PAGE';" +
                        "return 'DASHBOARD_PAGE';" +
                        "})()";

                webView.evaluateJavascript(checkJs, state -> {
                    if (state != null && state.contains("LOGIN_PAGE")) {
                        // লগইন পেইজ সামনে দেখাবে
                        if (webLoginContainer.getVisibility() != View.VISIBLE) {
                            webLoginContainer.setVisibility(View.VISIBLE);
                            swipeRefresh.setVisibility(View.GONE);
                        }
                        tvConnectionBadge.setText("● Login Required • " + prefs.getString("ip", ""));
                        tvConnectionBadge.setTextColor(Color.parseColor("#FBBF24"));
                        isExtracting = false;
                        handler.postDelayed(this, 800);
                    } else if (state != null && state.contains("DASHBOARD_PAGE")) {
                        // লগইন হয়ে গেছে! এবার ওয়েবপেজ হাইড করে নেটিভ কার্ডে ডাটা দেখাবে
                        if (webLoginContainer.getVisibility() == View.VISIBLE) {
                            webLoginContainer.setVisibility(View.GONE);
                            swipeRefresh.setVisibility(View.VISIBLE);
                        }
                        if (!isExtracting) {
                            isExtracting = true;
                            extractDataFromDom();
                        }
                    }
                });
            }
        }, 600);
    }

    private void extractDataFromDom() {
        tvConnectionBadge.setText("● Fetching Data...");
        String extractJs = "(function() {" +
                "var data = [];" +
                "var rows = document.querySelectorAll('tr');" +
                "rows.forEach(function(row) {" +
                "  var cols = row.querySelectorAll('td, th');" +
                "  if(cols.length >= 2) {" +
                "    var k = cols[0].innerText.trim();" +
                "    var v = cols[1].innerText.trim();" +
                "    var extra = cols.length > 2 ? cols[2].innerText.trim() : '';" +
                "    if(k && v && k !== v) {" +
                "      data.push({key: k, val: v + (extra ? ' | ' + extra : '')});" +
                "    }" +
                "  }" +
                "});" +
                "return JSON.stringify(data);" +
                "})()";

        webView.evaluateJavascript(extractJs, jsonResult -> {
            swipeRefresh.setRefreshing(false);
            try {
                if (jsonResult == null || jsonResult.equals("null")) {
                    handler.postDelayed(this::extractDataFromDom, 1000);
                    return;
                }
                String cleanJson = jsonResult.substring(1, jsonResult.length() - 1)
                        .replace("\\\"", "\"")
                        .replace("\\\\", "\\");

                JSONArray arr = new JSONArray(cleanJson);
                if (arr.length() > 0) {
                    renderNativeCards(arr);
                    tvConnectionBadge.setText("● Connected • " + prefs.getString("ip", ""));
                    tvConnectionBadge.setTextColor(Color.parseColor("#4ADE80"));
                    isExtracting = false;
                } else {
                    handler.postDelayed(this::extractDataFromDom, 1000);
                }
            } catch (Exception e) {
                handler.postDelayed(this::extractDataFromDom, 1000);
            }
        });
    }

    private void renderNativeCards(JSONArray items) {
        cardsContainer.removeAllViews();

        // টপ কুইক মেনু বার (Account / Network / System Info / Logout)
        LinearLayout tabBar = new LinearLayout(this);
        tabBar.setOrientation(LinearLayout.HORIZONTAL);
        tabBar.setPadding(0, 0, 0, 18);

        String[] tabs = {"Account Status", "Network Status", "System Info"};
        for (String tabName : tabs) {
            Button b = new Button(this);
            b.setText(tabName.replace(" Status", ""));
            b.setTextSize(12);
            b.setTextColor(Color.parseColor("#38BDF8"));
            b.setBackgroundColor(Color.parseColor("#1E293B"));
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, 105, 1f);
            lp.setMargins(6, 0, 6, 0);
            b.setLayoutParams(lp);
            b.setOnClickListener(v -> switchPhoneTab(tabName));
            tabBar.addView(b);
        }
        cardsContainer.addView(tabBar);

        // প্রতিটি ডাটা কার্ড আকারে সাজানো
        for (int i = 0; i < items.length(); i++) {
            try {
                JSONObject obj = items.getJSONObject(i);
                String key = obj.getString("key");
                String val = obj.getString("val");

                MaterialCardView card = new MaterialCardView(this);
                LinearLayout.LayoutParams cardParams = new LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.MATCH_PARENT,
                        LinearLayout.LayoutParams.WRAP_CONTENT
                );
                cardParams.setMargins(0, 0, 0, 16);
                card.setLayoutParams(cardParams);
                card.setCardBackgroundColor(Color.parseColor("#1E293B"));
                card.setRadius(26f);
                card.setStrokeColor(Color.parseColor("#334155"));
                card.setStrokeWidth(2);

                LinearLayout inner = new LinearLayout(this);
                inner.setOrientation(LinearLayout.VERTICAL);
                inner.setPadding(34, 24, 34, 24);

                TextView tvKey = new TextView(this);
                tvKey.setText(key);
                tvKey.setTextColor(Color.parseColor("#94A3B8"));
                tvKey.setTextSize(13f);

                TextView tvVal = new TextView(this);
                tvVal.setText(val);
                tvVal.setTextSize(16f);
                tvVal.setTypeface(null, Typeface.BOLD);
                tvVal.setPadding(0, 6, 0, 0);

                if (val.toLowerCase().contains("registered") && !val.toLowerCase().contains("unregistered")) {
                    tvVal.setTextColor(Color.parseColor("#4ADE80"));
                } else if (val.toLowerCase().contains("unregistered") || val.toLowerCase().contains("down")) {
                    tvVal.setTextColor(Color.parseColor("#F87171"));
                } else {
                    tvVal.setTextColor(Color.parseColor("#F8FAFC"));
                }

                inner.addView(tvKey);
                inner.addView(tvVal);
                card.addView(inner);
                cardsContainer.addView(card);
            } catch (Exception ignored) {}
        }
    }

    private void switchPhoneTab(String menuText) {
        tvConnectionBadge.setText("● Loading " + menuText + "...");
        String clickJs = "(function() {" +
                "var els = document.querySelectorAll('a, span, div, li');" +
                "for(var i=0; i<els.length; i++) {" +
                "  if(els[i].innerText && els[i].innerText.trim() === '" + menuText + "') {" +
                "    els[i].click(); break;" +
                "  }" +
                "}" +
                "})()";
        webView.evaluateJavascript(clickJs, null);
        handler.postDelayed(this::extractDataFromDom, 900);
    }

    private void loadUrl(String ip) {
        String url = ip.startsWith("http") ? ip : "http://" + ip;
        webView.loadUrl(url);
    }

    private void scanNetworkForGRP() {
        tvConnectionBadge.setText("● Scanning Wi-Fi...");
        WifiManager wm = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);
        int ipAddress = wm.getConnectionInfo().getIpAddress();
        String deviceIp = Formatter.formatIpAddress(ipAddress);

        if (deviceIp == null || deviceIp.equals("0.0.0.0")) {
            Toast.makeText(this, "Wi-Fi চালু নেই", Toast.LENGTH_SHORT).show();
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
                                    prefs.edit().putString("ip", testIp).apply();
                                    tvConnectionBadge.setText("● Found: " + testIp);
                                    loadUrl(testIp);
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

echo "✅ হাইব্রিড লগইন + নেটিভ ডাটা ফেচ কোড প্রস্তুত!"
