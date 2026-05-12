package com.example.stockapp.service;

import com.example.stockapp.dto.trading.OrderRequest;
import com.example.stockapp.dto.trading.OrderResponse;
import com.example.stockapp.entity.CashBalance;
import com.example.stockapp.entity.TradeOrder;
import com.example.stockapp.repository.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class TradingServiceTest {

    @Mock
    private CashBalanceRepository cashBalanceRepository;

    @Mock
    private PositionRepository positionRepository;

    @Mock
    private TradeOrderRepository tradeOrderRepository;

    @Mock
    private TradeRepository tradeRepository;

    @Mock
    private StockRepository stockRepository;

    @Mock
    private StockPriceService stockPriceService;

    @Mock
    private PortfolioSnapshotService portfolioSnapshotService;

    @InjectMocks
    private TradingService tradingService;

    @BeforeEach
    void setup() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void 成行買い注文成功() {

        Long userId = 1L;

        CashBalance balance = new CashBalance();
        balance.setUserId(userId);
        balance.setCash(new BigDecimal("1000000"));

        when(cashBalanceRepository.findByUserId(userId))
                .thenReturn(Optional.of(balance));

        when(tradeOrderRepository.save(any()))
                .thenAnswer(invocation -> {
                    TradeOrder order = invocation.getArgument(0);
                    order.setId(1L);
                    return order;
                });

        OrderRequest request = new OrderRequest();
        request.setStockCode("7203");
        request.setSide("BUY");
        request.setOrderType("MARKET");
        request.setQuantity(100);
        request.setCurrentPrice(new BigDecimal("3000"));

        OrderResponse response =
                tradingService.order(userId, request);

        assertNotNull(response);
        assertEquals("FILLED", response.getStatus());

        verify(tradeOrderRepository, times(1)).save(any());
        verify(tradeRepository, times(1)).save(any());
        verify(cashBalanceRepository, atLeastOnce()).save(any());
    }

    @Test
    void 残高不足なら例外() {

        Long userId = 1L;

        CashBalance balance = new CashBalance();
        balance.setUserId(userId);
        balance.setCash(new BigDecimal("1000"));

        when(cashBalanceRepository.findByUserId(userId))
                .thenReturn(Optional.of(balance));

        when(tradeOrderRepository.save(any()))
                .thenAnswer(invocation -> {
                    TradeOrder order = invocation.getArgument(0);
                    order.setId(1L);
                    return order;
                });

        OrderRequest request = new OrderRequest();
        request.setStockCode("7203");
        request.setSide("BUY");
        request.setOrderType("MARKET");
        request.setQuantity(100);
        request.setCurrentPrice(new BigDecimal("3000"));

        assertThrows(
                IllegalArgumentException.class,
                () -> tradingService.order(userId, request)
        );
    }

    @Test
    void 数量0なら例外() {

        OrderRequest request = new OrderRequest();
        request.setStockCode("7203");
        request.setSide("BUY");
        request.setOrderType("MARKET");
        request.setQuantity(0);
        request.setCurrentPrice(new BigDecimal("3000"));

        assertThrows(
                IllegalArgumentException.class,
                () -> tradingService.order(1L, request)
        );
    }

    @Test
    void 銘柄コード未入力なら例外() {

        OrderRequest request = new OrderRequest();
        request.setStockCode("");
        request.setSide("BUY");
        request.setOrderType("MARKET");
        request.setQuantity(100);
        request.setCurrentPrice(new BigDecimal("3000"));

        assertThrows(
                IllegalArgumentException.class,
                () -> tradingService.order(1L, request)
        );
    }

    @Test
    void 不正注文種別なら例外() {

        OrderRequest request = new OrderRequest();
        request.setStockCode("7203");
        request.setSide("BUY");
        request.setOrderType("TEST");
        request.setQuantity(100);
        request.setCurrentPrice(new BigDecimal("3000"));

        assertThrows(
                IllegalArgumentException.class,
                () -> tradingService.order(1L, request)
        );
    }
}