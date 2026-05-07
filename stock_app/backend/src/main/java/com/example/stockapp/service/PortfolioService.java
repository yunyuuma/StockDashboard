package com.example.stockapp.service;

import com.example.stockapp.dto.trading.PortfolioPointResponse;
import com.example.stockapp.dto.trading.PortfolioSummaryResponse;
import com.example.stockapp.dto.trading.SectorAllocationResponse;
import com.example.stockapp.entity.CashBalance;
import com.example.stockapp.entity.PortfolioSnapshot;
import com.example.stockapp.entity.Position;
import com.example.stockapp.entity.Stock;
import com.example.stockapp.repository.CashBalanceRepository;
import com.example.stockapp.repository.PortfolioSnapshotRepository;
import com.example.stockapp.repository.PositionRepository;
import com.example.stockapp.repository.StockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;

@Service
@RequiredArgsConstructor
public class PortfolioService {

    private final CashBalanceRepository cashBalanceRepository;
    private final PositionRepository positionRepository;
    private final PortfolioSnapshotRepository portfolioSnapshotRepository;
    private final StockRepository stockRepository;
    private final StockPriceService stockPriceService;

    private static final BigDecimal INITIAL_CASH = new BigDecimal("1000000");

    @Transactional(readOnly = true)
    public PortfolioSummaryResponse getPortfolio(Long userId) {
        BigDecimal cash = cashBalanceRepository.findByUserId(userId)
                .map(CashBalance::getCash)
                .orElse(INITIAL_CASH);

        BigDecimal stockValue = calcCurrentStockValue(userId);
        BigDecimal totalAsset = cash.add(stockValue);

        BigDecimal profitLoss = totalAsset.subtract(INITIAL_CASH);
        BigDecimal profitLossRate = percent(profitLoss, INITIAL_CASH);

        List<PortfolioPointResponse> points = buildSnapshotPoints(userId);

        BigDecimal dailyProfitLoss = calcDailyProfitLoss(points, totalAsset);
        BigDecimal dailyProfitLossRate = percent(dailyProfitLoss, totalAsset.subtract(dailyProfitLoss));

        BigDecimal maxDrawdown = calcMaxDrawdown(points);
        BigDecimal maxDrawdownRate = calcMaxDrawdownRate(points);

        List<SectorAllocationResponse> sectorAllocations =
                buildSectorAllocations(userId, stockValue);

        return new PortfolioSummaryResponse(
                cash,
                stockValue,
                totalAsset,
                profitLoss,
                profitLossRate,
                dailyProfitLoss,
                dailyProfitLossRate,
                maxDrawdown,
                maxDrawdownRate,
                points,
                sectorAllocations
        );
    }

    private BigDecimal calcCurrentStockValue(Long userId) {
        BigDecimal total = BigDecimal.ZERO;

        for (Position p : positionRepository.findByUserIdOrderByStockCodeAsc(userId)) {
            BigDecimal currentPrice = stockPriceService.getCurrentPrice(p.getStockCode());

            if (currentPrice == null || currentPrice.compareTo(BigDecimal.ZERO) <= 0) {
                currentPrice = p.getAveragePrice();
            }

            total = total.add(currentPrice.multiply(BigDecimal.valueOf(p.getQuantity())));
        }

        return total;
    }

    private List<PortfolioPointResponse> buildSnapshotPoints(Long userId) {
        List<PortfolioSnapshot> snapshots =
                portfolioSnapshotRepository.findByUserIdOrderBySnapshotAtAsc(userId);

        List<PortfolioPointResponse> points = new ArrayList<>();

        points.add(new PortfolioPointResponse(
                null,
                INITIAL_CASH,
                BigDecimal.ZERO,
                BigDecimal.ZERO,
                INITIAL_CASH,
                "開始"
        ));

        for (PortfolioSnapshot s : snapshots) {
            points.add(new PortfolioPointResponse(
                    s.getSnapshotAt(),
                    s.getCash(),
                    s.getStockValue(),
                    s.getMarketValue(),
                    s.getTotalAsset(),
                    s.getEventLabel()
            ));
        }

        return points;
    }

    private BigDecimal calcDailyProfitLoss(
            List<PortfolioPointResponse> points,
            BigDecimal currentTotalAsset
    ) {
        if (points == null || points.size() < 2) {
            return BigDecimal.ZERO;
        }

        PortfolioPointResponse previous = points.get(points.size() - 2);
        BigDecimal previousAsset = previous.getTotalAsset();

        if (previousAsset == null || previousAsset.compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ZERO;
        }

        return currentTotalAsset.subtract(previousAsset);
    }

    private BigDecimal calcMaxDrawdown(List<PortfolioPointResponse> points) {
        if (points == null || points.isEmpty()) {
            return BigDecimal.ZERO;
        }

        BigDecimal peak = BigDecimal.ZERO;
        BigDecimal maxDrawdown = BigDecimal.ZERO;

        for (PortfolioPointResponse p : points) {
            BigDecimal asset = p.getTotalAsset();
            if (asset == null) continue;

            if (asset.compareTo(peak) > 0) {
                peak = asset;
            }

            BigDecimal drawdown = peak.subtract(asset);

            if (drawdown.compareTo(maxDrawdown) > 0) {
                maxDrawdown = drawdown;
            }
        }

        return maxDrawdown;
    }

    private BigDecimal calcMaxDrawdownRate(List<PortfolioPointResponse> points) {
        if (points == null || points.isEmpty()) {
            return BigDecimal.ZERO;
        }

        BigDecimal peak = BigDecimal.ZERO;
        BigDecimal maxRate = BigDecimal.ZERO;

        for (PortfolioPointResponse p : points) {
            BigDecimal asset = p.getTotalAsset();
            if (asset == null) continue;

            if (asset.compareTo(peak) > 0) {
                peak = asset;
            }

            if (peak.compareTo(BigDecimal.ZERO) <= 0) {
                continue;
            }

            BigDecimal drawdown = peak.subtract(asset);
            BigDecimal rate = drawdown
                    .multiply(BigDecimal.valueOf(100))
                    .divide(peak, 2, RoundingMode.HALF_UP);

            if (rate.compareTo(maxRate) > 0) {
                maxRate = rate;
            }
        }

        return maxRate;
    }

    private List<SectorAllocationResponse> buildSectorAllocations(
            Long userId,
            BigDecimal totalStockValue
    ) {
        if (totalStockValue.compareTo(BigDecimal.ZERO) <= 0) {
            return List.of();
        }

        Map<String, BigDecimal> sectorMap = new LinkedHashMap<>();

        for (Position p : positionRepository.findByUserIdOrderByStockCodeAsc(userId)) {
            Stock stock = stockRepository.findById(p.getStockCode()).orElse(null);

            String sector = stock != null && stock.getSector() != null && !stock.getSector().isBlank()
                    ? stock.getSector()
                    : "未設定";

            BigDecimal currentPrice = stockPriceService.getCurrentPrice(p.getStockCode());

            if (currentPrice == null || currentPrice.compareTo(BigDecimal.ZERO) <= 0) {
                currentPrice = p.getAveragePrice();
            }

            BigDecimal amount = currentPrice.multiply(BigDecimal.valueOf(p.getQuantity()));

            sectorMap.put(sector, sectorMap.getOrDefault(sector, BigDecimal.ZERO).add(amount));
        }

        return sectorMap.entrySet()
                .stream()
                .map(e -> new SectorAllocationResponse(
                        e.getKey(),
                        e.getValue(),
                        e.getValue()
                                .multiply(BigDecimal.valueOf(100))
                                .divide(totalStockValue, 2, RoundingMode.HALF_UP)
                ))
                .sorted((a, b) -> b.getAmount().compareTo(a.getAmount()))
                .toList();
    }

    private BigDecimal percent(BigDecimal numerator, BigDecimal denominator) {
        if (denominator == null || denominator.compareTo(BigDecimal.ZERO) == 0) {
            return BigDecimal.ZERO;
        }

        return numerator
                .multiply(BigDecimal.valueOf(100))
                .divide(denominator, 2, RoundingMode.HALF_UP);
    }
}