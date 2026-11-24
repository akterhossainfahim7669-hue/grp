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
