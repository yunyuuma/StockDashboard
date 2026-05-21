package com.example.stockapp.service;

import com.example.stockapp.entity.CashBalance;
import com.example.stockapp.entity.PortfolioSnapshot;
import com.example.stockapp.entity.Position;
import com.example.stockapp.repository.CashBalanceRepository;
import com.example.stockapp.repository.PortfolioSnapshotRepository;
import com.example.stockapp.repository.PositionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class PortfolioSnapshotService {

    private final PortfolioSnapshotRepository portfolioSnapshotRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final PositionRepository positionRepository;
    private final StockPriceService stockPriceService;

    private static final BigDecimal INITIAL_CASH = new BigDecimal("1000000");

    @Transactional
    public void saveSnapshot(Long userId, String eventLabel) {
        BigDecimal cash = cashBalanceRepository.findByUserId(userId)
                .map(CashBalance::getCash)
                .orElse(INITIAL_CASH);

        BigDecimal marketValue = BigDecimal.ZERO;

        for (Position p : positionRepository.findByUserIdOrderByStockCodeAsc(userId)) {
            BigDecimal currentPrice = stockPriceService.getCurrentPrice(p.getStockCode());

            if (currentPrice == null || currentPrice.compareTo(BigDecimal.ZERO) <= 0) {
                currentPrice = p.getAveragePrice();
            }

            marketValue = marketValue.add(
                    currentPrice.multiply(BigDecimal.valueOf(p.getQuantity()))
            );
        }

        PortfolioSnapshot snapshot = new PortfolioSnapshot();
        snapshot.setUserId(userId);
        snapshot.setSnapshotAt(LocalDateTime.now());
        snapshot.setCash(cash);
        snapshot.setStockValue(marketValue);
        snapshot.setMarketValue(marketValue);
        snapshot.setTotalAsset(cash.add(marketValue));
        snapshot.setEventLabel(eventLabel);

        portfolioSnapshotRepository.save(snapshot);
    }
}