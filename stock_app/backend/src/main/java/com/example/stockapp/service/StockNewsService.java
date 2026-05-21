package com.example.stockapp.service;

import com.example.stockapp.dto.StockNewsResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilderFactory;
import java.io.ByteArrayInputStream;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.text.SimpleDateFormat;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class StockNewsService {

    private final StockService stockService;

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .followRedirects(HttpClient.Redirect.NORMAL)
            .build();

    public List<StockNewsResponse> getNews(String code) {
        System.out.println("=== StockNewsService#getNews called: code=" + code);

        String company = stockService.findNameByCode(code);

        if (company == null || company.isBlank()) {
            company = code;
        }

        List<StockNewsResponse> result;

        // Google News RSS

        result = tryGoogle(company, code);
        if (!result.isEmpty()) return result;

        // Yahoo Japan News RSS

        result = tryYahoo(company, code);
        if (!result.isEmpty()) return result;

        return buildFallback(company, code);
    }

    // Google News
    private List<StockNewsResponse> tryGoogle(String company, String code) {

        List<String> queries = List.of(
                company,
                company + " 株価",
                company + " 株",
                code + " 株価",
                code + " 株"
        );

        for (String q : queries) {
            try {
                String url =
                        "https://news.google.com/rss/search?q="
                                + URLEncoder.encode(q, StandardCharsets.UTF_8)
                                + "&hl=ja&gl=JP&ceid=JP:ja";

                List<StockNewsResponse> list =
                        parseRss(url, "Google News");

                if (!list.isEmpty()) {
                    return list;
                }

            } catch (Exception ignored) {
            }
        }

        return List.of();
    }

    // Yahoo fallback
    private List<StockNewsResponse> tryYahoo(String company, String code) {

        List<String> queries = List.of(
                company,
                code
        );

        for (String q : queries) {

            try {

                String url =
                        "https://news.yahoo.co.jp/rss/search?p="
                                + URLEncoder.encode(q, StandardCharsets.UTF_8);

                List<StockNewsResponse> list =
                        parseRss(url, "Yahoo!ニュース");

                if (!list.isEmpty()) {
                    return list;
                }

            } catch (Exception ignored) {
            }
        }

        return List.of();
    }

    private List<StockNewsResponse> parseRss(
            String url,
            String source
    ) throws Exception {

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(Duration.ofSeconds(15))
                .header("User-Agent", "Mozilla/5.0")
                .GET()
                .build();

        HttpResponse<byte[]> response =
                httpClient.send(
                        request,
                        HttpResponse.BodyHandlers.ofByteArray()
                );

        if (response.statusCode() != 200) {
            return List.of();
        }

        DocumentBuilderFactory factory =
                DocumentBuilderFactory.newInstance();

        factory.setFeature(
                XMLConstants.FEATURE_SECURE_PROCESSING,
                true
        );

        Document document =
                factory.newDocumentBuilder()
                        .parse(
                                new ByteArrayInputStream(
                                        response.body()
                                )
                        );

        NodeList items =
                document.getElementsByTagName("item");

        List<StockNewsResponse> list =
                new ArrayList<>();

        for (int i = 0; i < Math.min(items.getLength(), 15); i++) {

            Element item = (Element) items.item(i);

            String title = get(item, "title");
            String link = get(item, "link");
            String pubDate = get(item, "pubDate");

            list.add(
                    new StockNewsResponse(
                            title,
                            link,
                            format(pubDate),
                            source
                    )
            );
        }

        return list.stream()
                .filter(x -> !x.getTitle().isBlank())
                .collect(Collectors.toList());
    }

    private List<StockNewsResponse> buildFallback(
            String company,
            String code
    ) {
        System.out.println("=== fallback news returned: code=" + code);
        return List.of(
                new StockNewsResponse(
                        company + " の最新ニュース取得中",
                        "https://finance.yahoo.co.jp/quote/" + code + ".T",
                        now(),
                        "System"
                ),
                new StockNewsResponse(
                        company + " に関する市場ニュースを準備中",
                        "https://finance.yahoo.co.jp/",
                        now(),
                        "System"
                )
        );
    }

    private String get(Element e, String tag) {

        NodeList nl = e.getElementsByTagName(tag);

        if (nl.getLength() == 0) return "";

        return nl.item(0).getTextContent();
    }

    private String format(String raw) {

        try {
            return new SimpleDateFormat(
                    "yyyy-MM-dd HH:mm"
            ).format(
                    new SimpleDateFormat(
                            "EEE, dd MMM yyyy HH:mm:ss zzz",
                            Locale.ENGLISH
                    ).parse(raw)
            );
        } catch (Exception e) {
            return raw;
        }
    }

    private String now() {
        return new SimpleDateFormat(
                "yyyy-MM-dd HH:mm"
        ).format(new Date());
    }
}