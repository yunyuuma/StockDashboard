package com.example.stockapp.service;

import com.example.stockapp.repository.StockRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import static org.junit.jupiter.api.Assertions.assertThrows;

class AiChatServiceTest {

    @Mock
    private PortfolioService portfolioService;

    @Mock
    private StockRepository stockRepository;

    @Mock
    private StockPriceService stockPriceService;

    @InjectMocks
    private OllamaChatService ollamaChatService;

    @BeforeEach
    void setup() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void メッセージが空なら例外になること() {
        assertThrows(
                IllegalArgumentException.class,
                () -> ollamaChatService.chat(1L, "")
        );
    }

    @Test
    void メッセージがnullなら例外になること() {
        assertThrows(
                IllegalArgumentException.class,
                () -> ollamaChatService.chat(1L, null)
        );
    }
}