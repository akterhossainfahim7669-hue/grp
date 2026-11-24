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

    private EditText etIp, etUser, etPass;
    private TextView tvConnectionBadge, tvEmptyState;
    private WebView hiddenWebView;
    private MaterialCardView cardConfig;
    private LinearLayout cardsContainer;
    private SwipeRefreshLayout swipeRefresh;
    private SharedPreferences prefs;
    private final Handler handler = new Handler(Looper.getMainLooper());

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        prefs = getSharedPreferences("GRP_PREFS", MODE_PRIVATE);

        etIp = findViewById(R.id.etIp);
        etUser = findViewById(R.id.etUser);
        etPass = findViewById(R.id.etPass);
        tvConnectionBadge = findViewById(R.id.tvConnectionBadge);
        tvEmptyState = findViewById(R.id.tvEmptyState);
        hiddenWebView = findViewById(R.id.hiddenWebView);
        cardConfig = findViewById(R.id.cardConfig);
        cardsContainer = findViewById(R.id.cardsContainer);
        swipeRefresh = findViewById(R.id.swipeRefresh);

        Button btnAutoScan = findViewById(R.id.btnAutoScan);
        Button btnConnect = findViewById(R.id.btnConnect);
        Button btnToggleSettings = findViewById(R.id.btnToggleSettings);
        Button btnRefresh = findViewById(R.id.btnRefresh);

        String savedIp = prefs.getString("ip", "192.168.31.48");
        String savedUser = prefs.getString("user", "admin");
        String savedPass = prefs.getString("pass", "");

        etIp.setText(savedIp);
        etUser.setText(savedUser);
        etPass.setText(savedPass);

        setupBackgroundFetcher();

        if (!savedPass.isEmpty()) {
            cardConfig.setVisibility(View.GONE);
            startFetching(savedIp);
        } else {
            tvConnectionBadge.setText("● Setup Required");
            tvEmptyState.setText("উপরের বক্সে পাসওয়ার্ড দিয়ে Save & Fetch Data চাপুন");
        }

        btnToggleSettings.setOnClickListener(v ->
            cardConfig.setVisibility(cardConfig.getVisibility() == View.VISIBLE ? View.GONE : View.VISIBLE)
        );

        btnRefresh.setOnClickListener(v -> startFetching(prefs.getString("ip", savedIp)));
        swipeRefresh.setOnRefreshListener(() -> startFetching(prefs.getString("ip", savedIp)));
        btnAutoScan.setOnClickListener(v -> scanNetworkForGRP());

        btnConnect.setOnClickListener(v -> {
            String ip = etIp.getText().toString().trim();
            String user = etUser.getText().toString().trim();
            String pass = etPass.getText().toString().trim();

            if (ip.isEmpty() || pass.isEmpty()) {
                Toast.makeText(this, "IP এবং Password দিন", Toast.LENGTH_SHORT).show();
                return;
            }

            prefs.edit().putString("ip", ip).putString("user", user).putString("pass", pass).apply();
            cardConfig.setVisibility(View.GONE);
            startFetching(ip);
        });
    }

    private void setupBackgroundFetcher() {
        WebSettings settings = hiddenWebView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        CookieManager.getInstance().setAcceptCookie(true);

        hiddenWebView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                String user = prefs.getString("user", "admin");
                String pass = prefs.getString("pass", "");

                // ১. যদি লগইন পেইজ হয় তবে অটো লগইন করবে
                String loginJs = "(function() {" +
                        "var u = document.querySelector('input[type=text]');" +
                        "var p = document.querySelector('input[type=password]');" +
                        "if(u && p) {" +
                        "  u.value = '" + user + "';" +
                        "  u.dispatchEvent(new Event('input', { bubbles: true }));" +
                        "  p.value = '" + pass + "';" +
                        "  p.dispatchEvent(new Event('input', { bubbles: true }));" +
                        "  var btn = document.querySelector('button, input[type=submit]');" +
                        "  if(btn) btn.click();" +
                        "  return 'LOGGING_IN';" +
                        "}" +
                        "return 'LOGGED_IN';" +
                        "})()";

                view.evaluateJavascript(loginJs, state -> {
                    if (state != null && state.contains("LOGGING_IN")) {
                        tvConnectionBadge.setText("● Authenticating...");
                    } else {
                        tvConnectionBadge.setText("● Fetching Live Data...");
                        // SPA পেইজ রেন্ডার হওয়ার জন্য ১.২ সেকেন্ড পর ডাটা এক্সট্র্যাক্ট
                        handler.postDelayed(() -> extractDataFromDom(), 1200);
                    }
                });
            }
        });
    }

    private void extractDataFromDom() {
        // ওয়েবপেজের সব টেবিল রো (tr) ও স্ট্যাটাস ডাটা JSON আকারে তুলে আনা
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

        hiddenWebView.evaluateJavascript(extractJs, jsonResult -> {
            swipeRefresh.setRefreshing(false);
            try {
                if (jsonResult == null || jsonResult.equals("null")) return;
                // WebView evaluateJavascript স্ট্রিং এস্কেপ পরিষ্কার করা
                String cleanJson = jsonResult.substring(1, jsonResult.length() - 1)
                        .replace("\\\"", "\"")
                        .replace("\\\\", "\\");

                JSONArray arr = new JSONArray(cleanJson);
                if (arr.length() > 0) {
                    renderNativeCards(arr);
                    tvConnectionBadge.setText("● Online • " + prefs.getString("ip", ""));
                    tvConnectionBadge.setTextColor(Color.parseColor("#4ADE80"));
                } else {
                    // প্রথমবার লোড হতে দেরি হলে আবার চেষ্টা করবে
                    handler.postDelayed(this::extractDataFromDom, 1500);
                }
            } catch (Exception e) {
                tvConnectionBadge.setText("● Parse Retry...");
            }
        });
    }

    private void renderNativeCards(JSONArray items) {
        cardsContainer.removeAllViews();

        // মেনু বাটন বার (Account / Network / System Info সুইচ করার জন্য)
        LinearLayout tabBar = new LinearLayout(this);
        tabBar.setOrientation(LinearLayout.HORIZONTAL);
        tabBar.setPadding(0, 0, 0, 16);

        String[] tabs = {"Account Status", "Network Status", "System Info"};
        for (String tabName : tabs) {
            Button b = new Button(this);
            b.setText(tabName.replace(" Status", ""));
            b.setTextSize(12);
            b.setTextColor(Color.parseColor("#38BDF8"));
            b.setBackgroundColor(Color.parseColor("#1E293B"));
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, 110, 1f);
            lp.setMargins(6, 0, 6, 0);
            b.setLayoutParams(lp);
            b.setOnClickListener(v -> clickWebMenu(tabName));
            tabBar.addView(b);
        }
        cardsContainer.addView(tabBar);

        // প্রতিটি ডাটা আইটেমের জন্য সুন্দর নেটিভ কার্ড তৈরি
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
                cardParams.setMargins(0, 0, 0, 18);
                card.setLayoutParams(cardParams);
                card.setCardBackgroundColor(Color.parseColor("#1E293B"));
                card.setRadius(28f);
                card.setStrokeColor(Color.parseColor("#334155"));
                card.setStrokeWidth(2);

                LinearLayout inner = new LinearLayout(this);
                inner.setOrientation(LinearLayout.VERTICAL);
                inner.setPadding(36, 28, 36, 28);

                TextView tvKey = new TextView(this);
                tvKey.setText(key);
                tvKey.setTextColor(Color.parseColor("#94A3B8"));
                tvKey.setTextSize(13f);

                TextView tvVal = new TextView(this);
                tvVal.setText(val);
                tvVal.setTextSize(17f);
                tvVal.setTypeface(null, Typeface.BOLD);
                tvVal.setPadding(0, 6, 0, 0);

                // স্ট্যাটাস অনুযায়ী রঙ পরিবর্তন (Registered হলে সবুজ, Unregistered হলে লাল)
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

    private void clickWebMenu(String menuText) {
        tvConnectionBadge.setText("● Loading " + menuText + "...");
        String clickJs = "(function() {" +
                "var els = document.querySelectorAll('a, span, div, li');" +
                "for(var i=0; i<els.length; i++) {" +
                "  if(els[i].innerText && els[i].innerText.trim() === '" + menuText + "') {" +
                "    els[i].click(); break;" +
                "  }" +
                "}" +
                "})()";
        hiddenWebView.evaluateJavascript(clickJs, null);
        handler.postDelayed(this::extractDataFromDom, 900);
    }

    private void startFetching(String ip) {
        String url = ip.startsWith("http") ? ip : "http://" + ip;
        tvConnectionBadge.setText("● Connecting to " + ip + "...");
        hiddenWebView.loadUrl(url);
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
                                    tvConnectionBadge.setText("● Found: " + testIp);
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
