package com.example.stockapp.service;

import com.example.stockapp.client.JQuantsClient;
import com.example.stockapp.dto.JQuantsMasterResponse;
import com.example.stockapp.entity.Stock;
import com.example.stockapp.repository.StockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class StockSyncService {

    private final StockRepository stockRepository;
    private final JQuantsClient jQuantsClient;

    @Transactional
    public String syncStocks() {
        Map<String, Stock> stockMap = new LinkedHashMap<>();

        int apiCount = 0;
        int invalidCount = 0;

        String paginationKey = null;

        do {
            JQuantsMasterResponse response = jQuantsClient.getMaster(paginationKey);

            if (response == null || response.getData() == null) {
                return "API取得=0件 / 保存=0件 / response.dataがnullです。";
            }

            for (JQuantsMasterResponse.Item item : response.getData()) {
                apiCount++;

                String code = normalizeCode(item.getCode());
                String name = safe(item.getCompanyName());
                String market = safe(item.getMarketCodeName());
                String sector = safe(item.getSector33CodeName());

                if (!isValidStock(code, name, market, sector)) {
                    invalidCount++;
                    continue;
                }

                Stock stock = new Stock();
                stock.setCode(code);
                stock.setName(name);
                stock.setMarket(market);
                stock.setSector(sector);

                stockMap.put(code, stock);
            }

            paginationKey = response.getPaginationKey();

        } while (paginationKey != null && !paginationKey.isBlank());

        stockRepository.saveAll(stockMap.values());

        return "API取得=" + apiCount
                + "件 / 保存=" + stockMap.size()
                + "件 / 除外=" + invalidCount + "件";
    }

    private String normalizeCode(String code) {
        if (code == null) return "";

        String value = code.trim();

        if (value.matches("^[0-9]{5}$") && value.endsWith("0")) {
            return value.substring(0, 4);
        }

        return value;
    }

    private boolean isValidStock(
            String code,
            String name,
            String market,
            String sector
    ) {
        if (code == null || !code.matches("^[0-9]{4}$")) return false;
        if (name == null || name.isBlank()) return false;
        if (market == null || market.isBlank()) return false;
        if (sector == null || sector.isBlank()) return false;

        // その他市場はいらない
        if ("その他".equals(market)) return false;

        return true;
    }

    private String safe(String value) {
        return value == null ? "" : value.trim();
    }
}