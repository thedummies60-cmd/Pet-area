package com.petarena.game;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

/** Full-screen web view that runs the bundled Pet Arena game. */
public class MainActivity extends Activity {
    // Serving the game from a fixed https origin gives localStorage (trophies, coins, deck)
    // a stable home, so progress survives app restarts.
    private static final String HOST = "appassets.androidplatform.net";
    private static final String START_URL = "https://" + HOST + "/index.html";
    private static final String GAME_FILE = "Pet Arena (1).html";
    /** Bundled copies of the Google Fonts the game uses: {font family, file}. */
    private static final String[][] FONTS = {
        {"Lilita One", "LilitaOne-Regular.ttf"},
        {"Creepster", "Creepster-Regular.ttf"},
    };

    private WebView webView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        webView = new WebView(this);
        webView.setBackgroundColor(getResources().getColor(R.color.game_background));
        webView.setOverScrollMode(WebView.OVER_SCROLL_NEVER);
        webView.setVerticalScrollBarEnabled(false);
        webView.setHorizontalScrollBarEnabled(false);
        // Long-press would otherwise pop up text selection over the cards.
        webView.setLongClickable(false);
        webView.setOnLongClickListener(new View.OnLongClickListener() {
            @Override
            public boolean onLongClick(View v) {
                return true;
            }
        });

        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setMediaPlaybackRequiresUserGesture(false);
        settings.setSupportZoom(false);
        settings.setBuiltInZoomControls(false);
        settings.setTextZoom(100);
        settings.setAllowFileAccess(false);
        settings.setAllowContentAccess(false);

        webView.setWebViewClient(new GameClient());
        setContentView(webView);

        if (savedInstanceState == null || webView.restoreState(savedInstanceState) == null) {
            webView.loadUrl(START_URL);
        }
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        webView.saveState(outState);
    }

    @Override
    protected void onResume() {
        super.onResume();
        webView.onResume();
    }

    @Override
    protected void onPause() {
        webView.onPause();
        super.onPause();
    }

    @Override
    protected void onDestroy() {
        webView.destroy();
        super.onDestroy();
    }

    private class GameClient extends WebViewClient {
        @Override
        public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {
            Uri url = request.getUrl();
            if (!HOST.equals(url.getHost())) {
                return null;
            }
            String path = url.getPath() == null ? "/" : url.getPath();
            try {
                if (path.equals("/") || path.equals("/index.html")) {
                    String html = new String(readAsset(GAME_FILE), StandardCharsets.UTF_8);
                    return response("text/html", "utf-8", offlineFonts(html).getBytes(StandardCharsets.UTF_8));
                }
                for (String[] font : FONTS) {
                    if (path.equals("/" + font[1])) {
                        return response("font/ttf", null, readAsset(font[1]));
                    }
                }
            } catch (IOException e) {
                // Fall through to 404.
            }
            WebResourceResponse missing = response("text/plain", "utf-8", new byte[0]);
            missing.setStatusCodeAndReasonPhrase(404, "Not Found");
            return missing;
        }

        @Override
        @SuppressWarnings("deprecation") // The WebResourceRequest overload delegates here.
        public boolean shouldOverrideUrlLoading(WebView view, String link) {
            Uri url = Uri.parse(link);
            if (HOST.equals(url.getHost())) {
                return false;
            }
            // Any outside link opens in the browser instead of replacing the game.
            try {
                startActivity(new Intent(Intent.ACTION_VIEW, url));
            } catch (ActivityNotFoundException e) {
                // Nothing can open it; stay in the game.
            }
            return true;
        }
    }

    private byte[] readAsset(String name) throws IOException {
        try (InputStream in = getAssets().open(name)) {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            byte[] buffer = new byte[16384];
            int n;
            while ((n = in.read(buffer)) != -1) {
                out.write(buffer, 0, n);
            }
            return out.toByteArray();
        }
    }

    private static WebResourceResponse response(String mimeType, String encoding, byte[] data) {
        return new WebResourceResponse(mimeType, encoding, new ByteArrayInputStream(data));
    }

    /** Swaps the Google Fonts stylesheet for the bundled font files. */
    private static String offlineFonts(String html) {
        StringBuilder style = new StringBuilder("<style>");
        for (String[] font : FONTS) {
            style.append("@font-face{font-family:'").append(font[0])
                .append("';src:url('").append(font[1])
                .append("') format('truetype');font-display:swap}");
        }
        style.append("</style>");
        return html.replaceAll("<link[^>]*fonts\\.googleapis\\.com[^>]*>", style.toString());
    }
}
