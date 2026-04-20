package com.example.stockapp.service;

import com.example.stockapp.client.JQuantsClient;
import com.example.stockapp.config.JQuantsProperties;
import com.example.stockapp.dto.JQuantsMasterResponse;
import com.example.stockapp.dto.StockResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class StockService {

    private final JQuantsClient jQuantsClient;
    private final JQuantsProperties properties;

    private volatile List<StockResponse> cachedStocks = List.of();
    private volatile Instant cachedAt = Instant.EPOCH;

    public List<StockResponse> getStocks(int page, int size, String q, String market) {
        List<StockResponse> all = getAllStocksCached();

        String keyword = q == null ? "" : q.trim().toLowerCase();
        String marketFilter = market == null ? "" : market.trim();

        List<StockResponse> filtered = all.stream()
                .filter(s -> keyword.isEmpty()
                        || s.getCode().toLowerCase().contains(keyword)
                        || s.getName().toLowerCase().contains(keyword)
                        || s.getSector().toLowerCase().contains(keyword)
                        || s.getMarket().toLowerCase().contains(keyword))
                .filter(s -> marketFilter.isEmpty() || s.getMarket().equals(marketFilter))
                .toList();

        int safePage = Math.max(page, 0);
        int safeSize = Math.max(1, Math.min(size, 50));

        int from = safePage * safeSize;
        if (from >= filtered.size()) {
            return List.of();
        }

        int to = Math.min(from + safeSize, filtered.size());
        return filtered.subList(from, to);
    }

    public List<StockResponse> getAllStocks() {
        return getAllStocksCached();
    }

    public String findNameByCode(String code) {
        return getAllStocks().stream()
                .filter(stock -> stock.getCode().equalsIgnoreCase(code))
                .findFirst()
                .map(StockResponse::getName)
                .orElse(code);
    }

    public synchronized void reloadCache() {
        cachedStocks = fetchAllFromJQuants();
        cachedAt = Instant.now();
    }

    private List<StockResponse> getAllStocksCached() {
        long cacheMinutes = Math.max(1, properties.getCacheMinutes());
        Instant expiresAt = cachedAt.plusSeconds(cacheMinutes * 60);

        if (cachedStocks.isEmpty() || Instant.now().isAfter(expiresAt)) {
            synchronized (this) {
                expiresAt = cachedAt.plusSeconds(cacheMinutes * 60);
                if (cachedStocks.isEmpty() || Instant.now().isAfter(expiresAt)) {
                    cachedStocks = fetchAllFromJQuants();
                    cachedAt = Instant.now();
                }
            }
        }

        return cachedStocks;
    }

    private List<StockResponse> fetchAllFromJQuants() {
        List<StockResponse> result = new ArrayList<>();
        Set<String> seenCodes = new HashSet<>();

        String paginationKey = null;
        int pageCount = 0;

        while (true) {
            JQuantsMasterResponse response = jQuantsClient.getMaster(paginationKey);
            pageCount++;

            if (response == null || response.getData() == null || response.getData().isEmpty()) {
                break;
            }

            for (JQuantsMasterResponse.Item item : response.getData()) {
                String rawCode = safe(item.getCode()).trim();
                String code = normalizeCode(rawCode);
                String name = safe(item.getCompanyName()).trim();
                String market = safe(item.getMarketCodeName()).trim();
                String sector = safe(item.getSector33CodeName()).trim();

                if (code.isEmpty()) {
                    continue;
                }

                if ("TOKYO PRO MARKET".equals(market)) {
                    continue;
                }

                if ("その他".equals(market)) {
                    continue;
                }

                if (name.isEmpty() || market.isEmpty() || sector.isEmpty()) {
                    continue;
                }

                if (!seenCodes.add(code)) {
                    continue;
                }

                result.add(new StockResponse(code, name, market, sector));
            }

            if (response.getPaginationKey() == null || response.getPaginationKey().isBlank()) {
                break;
            }

            if (pageCount >= 100) {
                break;
            }

            paginationKey = response.getPaginationKey();
        }

        result.sort(Comparator.comparing(StockResponse::getCode));
        return result;
    }

    private String normalizeCode(String rawCode) {
        if (rawCode == null || rawCode.isBlank()) {
            return "";
        }

        String code = rawCode.trim().toUpperCase();

        if (code.length() == 5 && code.endsWith("0")) {
            code = code.substring(0, 4);
        }

        if (!code.matches("[0-9A-Z]{4}")) {
            return "";
        }

        return code;
    }

    private String safe(String value) {
        return value == null ? "" : value;
    }
}