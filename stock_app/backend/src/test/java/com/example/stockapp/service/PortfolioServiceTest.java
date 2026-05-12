package com.example.stockapp.service;

import com.example.stockapp.dto.trading.PortfolioSummaryResponse;
import com.example.stockapp.entity.CashBalance;
import com.example.stockapp.repository.CashBalanceRepository;
import com.example.stockapp.repository.PortfolioSnapshotRepository;
import com.example.stockapp.repository.PositionRepository;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.math.BigDecimal;
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
    private StockPriceService stockPriceService;

    @InjectMocks
    private PortfolioService portfolioService;

    @BeforeEach
    void setup() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void ポートフォリオ取得成功() {

        CashBalance balance = new CashBalance();
        balance.setUserId(1L);
        balance.setCash(new BigDecimal("1500000"));

        when(cashBalanceRepository.findByUserId(1L))
                .thenReturn(Optional.of(balance));

        PortfolioSummaryResponse result =
                portfolioService.getPortfolio(1L);

        assertNotNull(result);
        assertEquals(
                new BigDecimal("1500000"),
                result.getCash()
        );
    }
}