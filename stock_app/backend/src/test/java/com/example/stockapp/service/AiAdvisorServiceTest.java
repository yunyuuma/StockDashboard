package com.example.stockapp.service;

import com.example.stockapp.dto.ai.AiAdvisorResponse;
import com.example.stockapp.dto.trading.PortfolioSummaryResponse;
import com.example.stockapp.repository.TradeRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class AiAdvisorServiceTest {

    @Mock
    private PortfolioService portfolioService;

    @Mock
    private TradeRepository tradeRepository;

    @InjectMocks
    private AiAdvisorService aiAdvisorService;

    @BeforeEach
    void setup() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void 現金比率が低い場合はリスク高めになること() {
        PortfolioSummaryResponse portfolio = mock(PortfolioSummaryResponse.class);

        when(portfolio.getTotalAsset()).thenReturn(new BigDecimal("1000000"));
        when(portfolio.getCash()).thenReturn(new BigDecimal("100000"));
        when(portfolio.getStockValue()).thenReturn(new BigDecimal("900000"));
        when(portfolio.getProfitLoss()).thenReturn(BigDecimal.ZERO);
        when(portfolio.getDailyProfitLoss()).thenReturn(BigDecimal.ZERO);
        when(portfolio.getMaxDrawdownRate()).thenReturn(BigDecimal.ZERO);
        when(portfolio.getSectorAllocations()).thenReturn(List.of());

        when(portfolioService.getPortfolio(1L)).thenReturn(portfolio);
        when(tradeRepository.findByUserIdOrderByTradedAtDesc(1L)).thenReturn(List.of());

        AiAdvisorResponse res = aiAdvisorService.analyze(1L);

        assertNotNull(res);
        assertEquals("HIGH", res.getRiskLevel());
        assertFalse(res.getPortfolioAdvice().isEmpty());
    }

    @Test
    void 最大DDが大きい場合はリスク高めになること() {
        PortfolioSummaryResponse portfolio = mock(PortfolioSummaryResponse.class);

        when(portfolio.getTotalAsset()).thenReturn(new BigDecimal("1000000"));
        when(portfolio.getCash()).thenReturn(new BigDecimal("500000"));
        when(portfolio.getStockValue()).thenReturn(new BigDecimal("500000"));
        when(portfolio.getProfitLoss()).thenReturn(BigDecimal.ZERO);
        when(portfolio.getDailyProfitLoss()).thenReturn(BigDecimal.ZERO);
        when(portfolio.getMaxDrawdownRate()).thenReturn(new BigDecimal("15"));
        when(portfolio.getSectorAllocations()).thenReturn(List.of());

        when(portfolioService.getPortfolio(1L)).thenReturn(portfolio);
        when(tradeRepository.findByUserIdOrderByTradedAtDesc(1L)).thenReturn(List.of());

        AiAdvisorResponse res = aiAdvisorService.analyze(1L);

        assertNotNull(res);
        assertEquals("HIGH", res.getRiskLevel());
        assertFalse(res.getWarnings().isEmpty());
    }
}