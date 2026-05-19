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

    @Test
    void 指値買いが条件未達ならOPENになること() {
        Long userId = 1L;

        when(tradeOrderRepository.save(any()))
                .thenAnswer(invocation -> {
                    TradeOrder order = invocation.getArgument(0);
                    order.setId(1L);
                    return order;
                });

        OrderRequest request = new OrderRequest();
        request.setStockCode("7203");
        request.setSide("BUY");
        request.setOrderType("LIMIT");
        request.setQuantity(100);
        request.setCurrentPrice(new BigDecimal("3000"));
        request.setLimitPrice(new BigDecimal("2900"));

        OrderResponse response = tradingService.order(userId, request);

        assertEquals("OPEN", response.getStatus());
        verify(tradeRepository, never()).save(any());
    }

    @Test
    void 指値買いが条件一致ならFILLEDになること() {
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
        request.setOrderType("LIMIT");
        request.setQuantity(100);
        request.setCurrentPrice(new BigDecimal("2800"));
        request.setLimitPrice(new BigDecimal("2900"));

        OrderResponse response = tradingService.order(userId, request);

        assertEquals("FILLED", response.getStatus());
        verify(tradeRepository, times(1)).save(any());
    }

    @Test
    void 注文取消できること() {
        Long userId = 1L;

        TradeOrder order = new TradeOrder();
        order.setId(10L);
        order.setUserId(userId);
        order.setStatus("OPEN");

        when(tradeOrderRepository.findById(10L))
                .thenReturn(Optional.of(order));

        tradingService.cancelOrder(userId, 10L);

        assertEquals("CANCELED", order.getStatus());
        verify(tradeOrderRepository, times(1)).save(order);
    }

    @Test
    void 数量マイナスなら例外() {

        OrderRequest request = new OrderRequest();
        request.setStockCode("7203");
        request.setSide("BUY");
        request.setOrderType("MARKET");
        request.setQuantity(-100);
        request.setCurrentPrice(new BigDecimal("3000"));

        assertThrows(
                IllegalArgumentException.class,
                () -> tradingService.order(1L, request)
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
    void LIMIT価格未入力なら例外() {

        OrderRequest request = new OrderRequest();
        request.setStockCode("7203");
        request.setSide("BUY");
        request.setOrderType("LIMIT");
        request.setQuantity(100);
        request.setCurrentPrice(new BigDecimal("3000"));

        assertThrows(
                IllegalArgumentException.class,
                () -> tradingService.order(1L, request)
        );
    }

    @Test
    void STOP価格未入力なら例外() {

        OrderRequest request = new OrderRequest();
        request.setStockCode("7203");
        request.setSide("SELL");
        request.setOrderType("STOP");
        request.setQuantity(100);
        request.setCurrentPrice(new BigDecimal("3000"));

        assertThrows(
                IllegalArgumentException.class,
                () -> tradingService.order(1L, request)
        );
    }

    @Test
    void currentPriceがnullなら例外() {
        OrderRequest request = new OrderRequest();
        request.setStockCode("7203");
        request.setSide("BUY");
        request.setOrderType("MARKET");
        request.setQuantity(100);
        request.setCurrentPrice(null);

        assertThrows(
                IllegalArgumentException.class,
                () -> tradingService.order(1L, request)
        );
    }

    @Test
    void sideが不正なら例外() {
        OrderRequest request = new OrderRequest();
        request.setStockCode("7203");
        request.setSide("TEST");
        request.setOrderType("MARKET");
        request.setQuantity(100);
        request.setCurrentPrice(new BigDecimal("3000"));

        assertThrows(
                IllegalArgumentException.class,
                () -> tradingService.order(1L, request)
        );
    }
}