package com.example.stockapp.service;

import com.example.stockapp.client.JQuantsClient;
import com.example.stockapp.dto.JQuantsDailyBarsResponse;
import com.example.stockapp.dto.JQuantsDividendResponse;
import com.example.stockapp.dto.JQuantsFinSummaryResponse;
import com.example.stockapp.dto.StockChartPointResponse;
import com.example.stockapp.dto.StockCompanyResponse;
import com.example.stockapp.dto.StockDetailResponse;
import com.example.stockapp.dto.StockMetricsResponse;
import com.example.stockapp.dto.StockNewsResponse;
import com.example.stockapp.dto.StockResponse;
import com.example.stockapp.entity.CompanyProfile;
import com.example.stockapp.repository.CompanyProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Service
@RequiredArgsConstructor
public class StockDetailService {

    private final JQuantsClient jQuantsClient;
    private final StockService stockService;
    private final CompanyProfileRepository companyProfileRepository;

    public StockDetailResponse getSummary(String code) {
        String normalizedCode = normalizeCodeForApi(code);

        StockResponse stock = stockService.getAllStocks()
                .stream()
                .filter(s -> s.getCode().equalsIgnoreCase(code))
                .findFirst()
                .orElse(new StockResponse(code, "", "", ""));

        JQuantsDailyBarsResponse bars = jQuantsClient.getDailyBars(normalizedCode, null, null);
        List<JQuantsDailyBarsResponse.Item> items = safeBars(bars);

        if (items.size() < 2) {
            return new StockDetailResponse(
                    code,
                    stock.getName(),
                    stock.getMarket(),
                    stock.getSector(),
                    0, 0, 0, 0, 0, 0, 0
            );
        }

        items.sort(Comparator.comparing(JQuantsDailyBarsResponse.Item::getDate));
        JQuantsDailyBarsResponse.Item latest = items.get(items.size() - 1);
        JQuantsDailyBarsResponse.Item prev = items.get(items.size() - 2);

        double latestClose = nvl(latest.getAdjClose(), latest.getClose());
        double prevClose = nvl(prev.getAdjClose(), prev.getClose());
        double changePct = prevClose == 0 ? 0 : ((latestClose - prevClose) / prevClose) * 100.0;

        return new StockDetailResponse(
                code,
                stock.getName(),
                stock.getMarket(),
                stock.getSector(),
                latestClose,
                changePct,
                nvl(latest.getHigh()),
                nvl(latest.getLow()),
                nvl(latest.getOpen()),
                nvl(latest.getClose()),
                nvl(latest.getVolume())
        );
    }

    public List<StockChartPointResponse> getChart(String code) {
        String normalizedCode = normalizeCodeForApi(code);

        LocalDate to = LocalDate.now();
        LocalDate from = to.minusMonths(12);

        JQuantsDailyBarsResponse bars =
                jQuantsClient.getDailyBars(normalizedCode, from.toString(), to.toString());

        List<JQuantsDailyBarsResponse.Item> items = safeBars(bars);
        items.sort(Comparator.comparing(JQuantsDailyBarsResponse.Item::getDate));

        List<StockChartPointResponse> out = new ArrayList<>();
        for (JQuantsDailyBarsResponse.Item item : items) {
            out.add(new StockChartPointResponse(
                    item.getDate(),
                    nvl(item.getOpen()),
                    nvl(item.getHigh()),
                    nvl(item.getLow()),
                    nvl(item.getAdjClose(), item.getClose()),
                    nvl(item.getVolume())
            ));
        }
        return out;
    }

    public StockMetricsResponse getMetrics(String code) {
        String normalizedCode = normalizeCodeForApi(code);

        try {
            JQuantsFinSummaryResponse finRes = jQuantsClient.getFinSummary(normalizedCode);
            List<JQuantsFinSummaryResponse.Item> items = safeFin(finRes);

            items.sort(Comparator.comparing(
                    item -> str(item.getDisclosedDate()) + str(item.getDisclosureNumber())
            ));

            if (items.isEmpty()) {
                return emptyMetrics();
            }

            JQuantsFinSummaryResponse.Item latest = null;

            for (int i = items.size() - 1; i >= 0; i--) {
                JQuantsFinSummaryResponse.Item x = items.get(i);
                if (x.getNetSales() != null
                        || x.getOperatingProfit() != null
                        || x.getOrdinaryProfit() != null
                        || x.getProfit() != null
                        || x.getEarningsPerShare() != null
                        || x.getForecastNetSales() != null
                        || x.getForecastProfit() != null
                        || x.getAnnualDividendPerShareForecast() != null) {
                    latest = x;
                    break;
                }
            }

            if (latest == null) {
                latest = items.get(items.size() - 1);
            }

            return new StockMetricsResponse(
                    str(latest.getDisclosedDate()),
                    str(latest.getDisclosedTime()),
                    str(latest.getTypeOfDocument()),
                    str(latest.getCurrentPeriodEndDate()),

                    nvl(latest.getNetSales()),
                    nvl(latest.getOperatingProfit()),
                    nvl(latest.getOrdinaryProfit()),
                    nvl(latest.getProfit()),
                    nvl(latest.getEarningsPerShare()),

                    nvl(latest.getForecastNetSales()),
                    nvl(latest.getForecastOperatingProfit()),
                    nvl(latest.getForecastOrdinaryProfit()),
                    nvl(latest.getForecastProfit()),

                    nvl(latest.getAnnualDividendPerShareForecast())
            );

        } catch (Exception e) {
            e.printStackTrace();
            return emptyMetrics();
        }
    }

    public StockCompanyResponse getCompany(String code) {
        StockResponse stock = stockService.getAllStocks().stream()
                .filter(s -> s.getCode().equalsIgnoreCase(code))
                .findFirst()
                .orElse(new StockResponse(code, "", "", ""));

        String companyName = stock.getName() == null ? "" : stock.getName();
        String market = stock.getMarket() == null ? "" : stock.getMarket();
        String industry = stock.getSector() == null ? "" : stock.getSector();

        CompanyProfile profile = companyProfileRepository.findByStockCode(code)
                .orElse(null);

        String description = profile != null && profile.getDescription() != null
                ? profile.getDescription()
                : "";

        String website = profile != null && profile.getWebsite() != null
                ? profile.getWebsite()
                : "";

        String mapQuery = profile != null && profile.getMapQuery() != null && !profile.getMapQuery().isBlank()
                ? profile.getMapQuery()
                : (companyName.isBlank() ? code : companyName + " 本社");

        String trendsKeyword = profile != null && profile.getTrendsKeyword() != null && !profile.getTrendsKeyword().isBlank()
                ? profile.getTrendsKeyword()
                : (companyName.isBlank() ? code : companyName);

        return new StockCompanyResponse(
                companyName,
                market,
                industry,
                description,
                website,
                mapQuery,
                trendsKeyword
        );
    }

    public List<StockNewsResponse> getNews(String code) {
        return List.of();
    }

    private List<JQuantsDailyBarsResponse.Item> safeBars(JQuantsDailyBarsResponse response) {
        if (response == null || response.getData() == null) {
            return new ArrayList<>();
        }
        return new ArrayList<>(response.getData());
    }

    private List<JQuantsFinSummaryResponse.Item> safeFin(JQuantsFinSummaryResponse response) {
        if (response == null || response.getData() == null) {
            return new ArrayList<>();
        }
        return new ArrayList<>(response.getData());
    }

    private List<JQuantsDividendResponse.Item> safeDividend(JQuantsDividendResponse response) {
        if (response == null || response.getData() == null) {
            return new ArrayList<>();
        }
        return new ArrayList<>(response.getData());
    }

    private String normalizeCodeForApi(String code) {
        if (code == null) {
            return "";
        }
        return code.trim().toUpperCase();
    }

    private StockMetricsResponse emptyMetrics() {
        return new StockMetricsResponse(
                "",
                "",
                "",
                "",
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                0
        );
    }

    private String str(String value) {
        return value == null ? "" : value;
    }

    private double parseDivRate(String value) {
        if (value == null) {
            return 0;
        }

        String trimmed = value.trim();
        if (trimmed.isEmpty() || "-".equals(trimmed)) {
            return 0;
        }

        try {
            return Double.parseDouble(trimmed);
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    private double lastPositive(List<Double> values) {
        for (int i = values.size() - 1; i >= 0; i--) {
            Double v = values.get(i);
            if (v != null && v > 0) {
                return v;
            }
        }
        return 0;
    }

    private double nvl(Double value) {
        return value == null ? 0 : value;
    }

    private double nvl(Double primary, Double fallback) {
        if (primary != null) {
            return primary;
        }
        return fallback == null ? 0 : fallback;
    }
}