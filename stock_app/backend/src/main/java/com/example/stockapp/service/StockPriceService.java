package com.example.stockapp.service;

import com.example.stockapp.client.JQuantsClient;
import com.example.stockapp.dto.JQuantsDailyBarsResponse;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class StockPriceService {

    private final JQuantsClient jQuantsClient;
    private final ObjectMapper objectMapper;

    public BigDecimal getCurrentPrice(String code) {
        try {
            String normalizedCode = normalizeCode(code);

            LocalDate to = LocalDate.now();
            LocalDate from = to.minusDays(14);

            JQuantsDailyBarsResponse response = jQuantsClient.getDailyBars(
                    normalizedCode,
                    from.toString().replace("-", ""),
                    to.toString().replace("-", "")
            );

            if (response == null) {
                return BigDecimal.ZERO;
            }

            Map<String, Object> map = objectMapper.convertValue(
                    response,
                    new TypeReference<Map<String, Object>>() {}
            );

            Object listObject = firstNotNull(
                    map.get("daily_quotes"),
                    map.get("dailyQuotes"),
                    map.get("data"),
                    map.get("quotes")
            );

            if (!(listObject instanceof List<?> list) || list.isEmpty()) {
                return BigDecimal.ZERO;
            }

            Object latestObject = list.get(list.size() - 1);

            Map<String, Object> latest = objectMapper.convertValue(
                    latestObject,
                    new TypeReference<Map<String, Object>>() {}
            );

            Object close = firstNotNull(
                    latest.get("Close"),
                    latest.get("close"),
                    latest.get("C"),
                    latest.get("AdjClose"),
                    latest.get("adjClose")
            );

            return toBigDecimal(close);

        } catch (Exception e) {
            return BigDecimal.ZERO;
        }
    }

    private Object firstNotNull(Object... values) {
        for (Object value : values) {
            if (value != null) {
                return value;
            }
        }
        return null;
    }

    private BigDecimal toBigDecimal(Object value) {
        if (value == null) {
            return BigDecimal.ZERO;
        }

        if (value instanceof BigDecimal bigDecimal) {
            return bigDecimal;
        }

        if (value instanceof Number number) {
            return BigDecimal.valueOf(number.doubleValue());
        }

        try {
            return new BigDecimal(value.toString());
        } catch (Exception e) {
            return BigDecimal.ZERO;
        }
    }

    private String normalizeCode(String code) {
        if (code == null) {
            return "";
        }

        String value = code.trim().toUpperCase();

        if (value.length() == 5 && value.endsWith("0")) {
            return value.substring(0, 4);
        }

        return value;
    }
}