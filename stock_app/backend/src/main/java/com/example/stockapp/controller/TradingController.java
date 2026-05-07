package com.example.stockapp.controller;

import com.example.stockapp.dto.trading.*;
import com.example.stockapp.security.CustomUserPrincipal;
import com.example.stockapp.service.TradingService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

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

    @GetMapping("/orders")
    public List<OrderListResponse> orders(@AuthenticationPrincipal CustomUserPrincipal principal) {
        return tradingService.orders(principal.getId());
    }

    @GetMapping("/orders/open")
    public List<OrderListResponse> openOrders(@AuthenticationPrincipal CustomUserPrincipal principal) {
        return tradingService.openOrders(principal.getId());
    }

    @PostMapping("/orders")
    public OrderResponse order(
            @AuthenticationPrincipal CustomUserPrincipal principal,
            @RequestBody OrderRequest request
    ) {
        return tradingService.order(principal.getId(), request);
    }

    @DeleteMapping("/orders/{orderId}")
    public Map<String, String> cancelOrder(
            @AuthenticationPrincipal CustomUserPrincipal principal,
            @PathVariable Long orderId
    ) {
        tradingService.cancelOrder(principal.getId(), orderId);
        return Map.of("message", "注文を取消しました。");
    }

    @PostMapping("/orders/check")
    public Map<String, Object> checkOpenOrders(@AuthenticationPrincipal CustomUserPrincipal principal) {
        int filledCount = tradingService.checkOpenOrders(principal.getId());
        return Map.of(
                "message", "未約定注文を再判定しました。",
                "filledCount", filledCount
        );
    }

    @PostMapping("/algo-orders")
    public OrderResponse algoOrder(
            @AuthenticationPrincipal CustomUserPrincipal principal,
            @RequestBody AlgoOrderRequest request
    ) {
        return tradingService.algoOrder(principal.getId(), request);
    }

    @GetMapping("/order-book/{stockCode}")
    public OrderBookResponse pseudoBoard(
            @PathVariable String stockCode,
            @RequestParam BigDecimal currentPrice
    ) {
        return tradingService.pseudoBoard(stockCode, currentPrice);
    }
}