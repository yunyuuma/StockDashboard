package com.example.stockapp.service;

import com.example.stockapp.dto.trading.PortfolioSummaryResponse;
import com.example.stockapp.entity.CashBalance;
import com.example.stockapp.entity.Position;
import com.example.stockapp.entity.Stock;
import com.example.stockapp.repository.CashBalanceRepository;
import com.example.stockapp.repository.PortfolioSnapshotRepository;
import com.example.stockapp.repository.PositionRepository;
import com.example.stockapp.repository.StockRepository;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class PortfolioServiceTest {

    @Mock
    private CashBalanceRepository cashBalanceRepository;

    @Mock
    private PositionRepository positionRepository;

    @Mock
    private PortfolioSnapshotRepository portfolioSnapshotRepository;

    @Mock
    private StockRepository stockRepository;

    @Mock
    private StockPriceService stockPriceService;

    @InjectMocks
    private PortfolioService portfolioService;

    @BeforeEach
    void setup() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void 現金のみのポートフォリオを取得できること() {

        CashBalance cash = new CashBalance();
        cash.setUserId(1L);
        cash.setCash(new BigDecimal("1000000"));

        when(cashBalanceRepository.findByUserId(1L))
                .thenReturn(Optional.of(cash));

        when(positionRepository.findByUserIdOrderByStockCodeAsc(1L))
                .thenReturn(List.of());

        when(portfolioSnapshotRepository.findByUserIdOrderBySnapshotAtAsc(1L))
                .thenReturn(List.of());

        PortfolioSummaryResponse res =
                portfolioService.getPortfolio(1L);

        assertNotNull(res);

        assertEquals(
                0,
                res.getCash().compareTo(new BigDecimal("1000000"))
        );
    }

    @Test
    void 保有銘柄がある場合に評価額が計算されること() {

        CashBalance cash = new CashBalance();
        cash.setUserId(1L);
        cash.setCash(new BigDecimal("500000"));

        Position position = new Position();
        position.setUserId(1L);
        position.setStockCode("7203");
        position.setQuantity(100);
        position.setAveragePrice(new BigDecimal("3000"));

        Stock stock = new Stock();
        stock.setCode("7203");
        stock.setName("トヨタ自動車");
        stock.setMarket("プライム");
        stock.setSector("輸送用機器");

        when(cashBalanceRepository.findByUserId(1L))
                .thenReturn(Optional.of(cash));

        when(positionRepository.findByUserIdOrderByStockCodeAsc(1L))
                .thenReturn(List.of(position));

        when(stockRepository.findById("7203"))
                .thenReturn(Optional.of(stock));

        when(stockPriceService.getCurrentPrice("7203"))
                .thenReturn(new BigDecimal("3200"));

        when(portfolioSnapshotRepository.findByUserIdOrderBySnapshotAtAsc(1L))
                .thenReturn(List.of());

        PortfolioSummaryResponse res =
                portfolioService.getPortfolio(1L);

        assertNotNull(res);

        assertTrue(
                res.getStockValue()
                        .compareTo(BigDecimal.ZERO) > 0
        );

        assertTrue(
                res.getTotalAsset()
                        .compareTo(BigDecimal.ZERO) > 0
        );

        assertNotNull(res.getSectorAllocations());
        assertNotNull(res.getMaxDrawdown());
    }
}