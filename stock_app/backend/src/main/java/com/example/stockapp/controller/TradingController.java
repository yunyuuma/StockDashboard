package com.example.stockapp.controller;

import com.example.stockapp.dto.trading.*;
import com.example.stockapp.security.CustomUserPrincipal;
import com.example.stockapp.service.TradingService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;

@RestController
@RequestMapping("/api/trading")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class TradingController {

    private final TradingService tradingService;

    @GetMapping("/summary")
    public TradingSummaryResponse summary(@AuthenticationPrincipal CustomUserPrincipal principal) {
        return tradingService.summary(principal.getId());
    }

    @GetMapping("/positions")
    public List<PositionResponse> positions(@AuthenticationPrincipal CustomUserPrincipal principal) {
        return tradingService.positions(principal.getId());
    }

    @GetMapping("/trades")
    public List<TradeResponse> trades(@AuthenticationPrincipal CustomUserPrincipal principal) {
        return tradingService.trades(principal.getId());
    }

    @PostMapping("/orders")
    public OrderResponse order(
            @AuthenticationPrincipal CustomUserPrincipal principal,
            @RequestBody OrderRequest request
    ) {
        return tradingService.order(principal.getId(), request);
    }

    @GetMapping("/order-book/{stockCode}")
    public OrderBookResponse pseudoBoard(
            @PathVariable String stockCode,
            @RequestParam BigDecimal currentPrice
    ) {
        return tradingService.pseudoBoard(stockCode, currentPrice);
    }
}