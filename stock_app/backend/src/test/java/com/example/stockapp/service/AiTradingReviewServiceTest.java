package com.example.stockapp.service;

import com.example.stockapp.dto.ai.AiTradingReviewResponse;
import com.example.stockapp.entity.Trade;
import com.example.stockapp.repository.TradeRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class AiTradingReviewServiceTest {

    @Mock
    private TradeRepository tradeRepository;

    @InjectMocks
    private AiTradingReviewService aiTradingReviewService;

    @BeforeEach
    void setup() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void 売買履歴なしなら履歴なしレビューになること() {
        when(tradeRepository.findByUserIdOrderByTradedAtDesc(1L))
                .thenReturn(List.of());

        AiTradingReviewResponse res = aiTradingReviewService.review(1L);

        assertNotNull(res);
        assertEquals(0, res.getTradeCount());
        assertTrue(res.getSummary().contains("売買履歴"));
    }

    @Test
    void 買い注文に偏っている場合は改善点が出ること() {
        Trade t1 = trade("BUY", "7203", 100, "3000");
        Trade t2 = trade("BUY", "6758", 100, "2000");
        Trade t3 = trade("BUY", "9984", 100, "5000");

        when(tradeRepository.findByUserIdOrderByTradedAtDesc(1L))
                .thenReturn(List.of(t1, t2, t3));

        AiTradingReviewResponse res = aiTradingReviewService.review(1L);

        assertNotNull(res);
        assertEquals(3, res.getTradeCount());
        assertEquals(3, res.getBuyCount());
        assertEquals(0, res.getSellCount());
        assertFalse(res.getWeakPoints().isEmpty());
    }

    @Test
    void 買い売り両方ある場合はレビューできること() {
        Trade buy = trade("BUY", "7203", 100, "3000");
        Trade sell = trade("SELL", "7203", 100, "3300");

        when(tradeRepository.findByUserIdOrderByTradedAtDesc(1L))
                .thenReturn(List.of(sell, buy));

        AiTradingReviewResponse res = aiTradingReviewService.review(1L);

        assertNotNull(res);
        assertEquals(2, res.getTradeCount());
        assertEquals(1, res.getBuyCount());
        assertEquals(1, res.getSellCount());
        assertFalse(res.getGoodPoints().isEmpty());
    }

    private Trade trade(String side, String code, int quantity, String price) {
        Trade t = new Trade();
        t.setUserId(1L);
        t.setStockCode(code);
        t.setSide(side);
        t.setQuantity(quantity);
        t.setPrice(new BigDecimal(price));
        t.setTradedAt(LocalDateTime.now());
        return t;
    }
}