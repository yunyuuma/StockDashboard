package com.example.stockapp.service;

import com.example.stockapp.dto.trading.*;
import com.example.stockapp.entity.*;
import com.example.stockapp.repository.*;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class TradingService {

    private final CashBalanceRepository cashBalanceRepository;
    private final PositionRepository positionRepository;
    private final TradeOrderRepository tradeOrderRepository;
    private final TradeRepository tradeRepository;
    private final StockRepository stockRepository;

    private static final BigDecimal INITIAL_CASH = new BigDecimal("1000000");

    @Transactional(readOnly = true)
    public TradingSummaryResponse summary(Long userId) {
        CashBalance cash = getOrCreateCash(userId);

        return new TradingSummaryResponse(
                cash.getCash(),
                positionRepository.findByUserIdOrderByStockCodeAsc(userId).size(),
                tradeRepository.findByUserIdOrderByTradedAtDesc(userId).size()
        );
    }

    @Transactional(readOnly = true)
    public List<PositionResponse> positions(Long userId) {
        return positionRepository.findByUserIdOrderByStockCodeAsc(userId)
                .stream()
                .map(p -> {
                    Stock stock = stockRepository.findById(p.getStockCode()).orElse(null);

                    return new PositionResponse(
                            p.getStockCode(),
                            stock != null ? stock.getName() : "",
                            stock != null ? stock.getMarket() : "",
                            stock != null ? stock.getSector() : "",
                            p.getQuantity(),
                            p.getAveragePrice()
                    );
                })
                .toList();
    }

    @Transactional(readOnly = true)
    public List<TradeResponse> trades(Long userId) {
        return tradeRepository.findByUserIdOrderByTradedAtDesc(userId)
                .stream()
                .map(t -> {
                    Stock stock = stockRepository.findById(t.getStockCode()).orElse(null);

                    return new TradeResponse(
                            t.getId(),
                            t.getStockCode(),
                            stock != null ? stock.getName() : "",
                            stock != null ? stock.getMarket() : "",
                            stock != null ? stock.getSector() : "",
                            t.getSide(),
                            t.getQuantity(),
                            t.getPrice(),
                            t.getTradedAt()
                    );
                })
                .toList();
    }

    @Transactional
    public OrderResponse order(Long userId, OrderRequest request) {
        validate(request);

        String stockCode = normalizeCode(request.getStockCode());
        String side = request.getSide().toUpperCase();
        String orderType = request.getOrderType().toUpperCase();
        BigDecimal currentPrice = request.getCurrentPrice();
        BigDecimal limitPrice = request.getLimitPrice();

        boolean shouldFill = shouldFill(side, orderType, currentPrice, limitPrice);

        TradeOrder order = new TradeOrder();
        order.setUserId(userId);
        order.setStockCode(stockCode);
        order.setSide(side);
        order.setOrderType(orderType);
        order.setQuantity(request.getQuantity());
        order.setLimitPrice(limitPrice);
        order.setCurrentPrice(currentPrice);
        order.setStatus(shouldFill ? "FILLED" : "OPEN");
        order.setOrderedAt(LocalDateTime.now());

        if (shouldFill) {
            order.setFilledAt(LocalDateTime.now());
        }

        TradeOrder savedOrder = tradeOrderRepository.save(order);

        if (shouldFill) {
            executeTrade(userId, savedOrder, currentPrice);
        }

        return new OrderResponse(
                savedOrder.getId(),
                savedOrder.getStockCode(),
                savedOrder.getSide(),
                savedOrder.getOrderType(),
                savedOrder.getQuantity(),
                savedOrder.getLimitPrice(),
                savedOrder.getCurrentPrice(),
                savedOrder.getStatus(),
                shouldFill ? "注文が約定しました。" : "指値注文を受付しました。"
        );
    }

    public OrderBookResponse pseudoBoard(String stockCode, BigDecimal currentPrice) {
        BigDecimal p = currentPrice.setScale(0, RoundingMode.HALF_UP);

        List<OrderBookResponse.BoardRow> sell = List.of(
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("1.050")).setScale(0, RoundingMode.HALF_UP), 100),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("1.040")).setScale(0, RoundingMode.HALF_UP), 200),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("1.030")).setScale(0, RoundingMode.HALF_UP), 300),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("1.020")).setScale(0, RoundingMode.HALF_UP), 500),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("1.015")).setScale(0, RoundingMode.HALF_UP), 700),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("1.010")).setScale(0, RoundingMode.HALF_UP), 900),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("1.005")).setScale(0, RoundingMode.HALF_UP), 1200)
        );

        List<OrderBookResponse.BoardRow> buy = List.of(
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("0.995")).setScale(0, RoundingMode.HALF_UP), 1100),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("0.990")).setScale(0, RoundingMode.HALF_UP), 800),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("0.985")).setScale(0, RoundingMode.HALF_UP), 650),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("0.980")).setScale(0, RoundingMode.HALF_UP), 500),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("0.970")).setScale(0, RoundingMode.HALF_UP), 300),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("0.960")).setScale(0, RoundingMode.HALF_UP), 200),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("0.950")).setScale(0, RoundingMode.HALF_UP), 100)
        );

        return new OrderBookResponse(
                normalizeCode(stockCode),
                currentPrice,
                sell,
                buy
        );
    }

    private void executeTrade(Long userId, TradeOrder order, BigDecimal price) {
        if ("BUY".equals(order.getSide())) {
            buy(userId, order, price);
        } else {
            sell(userId, order, price);
        }

        Trade trade = new Trade();
        trade.setOrderId(order.getId());
        trade.setUserId(userId);
        trade.setStockCode(order.getStockCode());
        trade.setSide(order.getSide());
        trade.setQuantity(order.getQuantity());
        trade.setPrice(price);
        trade.setTradedAt(LocalDateTime.now());
        tradeRepository.save(trade);
    }

    private void buy(Long userId, TradeOrder order, BigDecimal price) {
        CashBalance cash = getOrCreateCash(userId);
        BigDecimal amount = price.multiply(BigDecimal.valueOf(order.getQuantity()));

        if (cash.getCash().compareTo(amount) < 0) {
            throw new IllegalArgumentException("仮想残高が不足しています。");
        }

        cash.setCash(cash.getCash().subtract(amount));
        cashBalanceRepository.save(cash);

        Position position = positionRepository
                .findByUserIdAndStockCode(userId, order.getStockCode())
                .orElseGet(() -> {
                    Position p = new Position();
                    p.setUserId(userId);
                    p.setStockCode(order.getStockCode());
                    p.setQuantity(0);
                    p.setAveragePrice(BigDecimal.ZERO);
                    return p;
                });

        int oldQty = position.getQuantity();
        int newQty = oldQty + order.getQuantity();

        BigDecimal oldAmount = position.getAveragePrice().multiply(BigDecimal.valueOf(oldQty));
        BigDecimal newAmount = oldAmount.add(amount);

        position.setQuantity(newQty);
        position.setAveragePrice(newAmount.divide(BigDecimal.valueOf(newQty), 2, RoundingMode.HALF_UP));

        positionRepository.save(position);
    }

    private void sell(Long userId, TradeOrder order, BigDecimal price) {
        Position position = positionRepository
                .findByUserIdAndStockCode(userId, order.getStockCode())
                .orElseThrow(() -> new IllegalArgumentException("保有していない銘柄です。"));

        if (position.getQuantity() < order.getQuantity()) {
            throw new IllegalArgumentException("保有数量が不足しています。");
        }

        position.setQuantity(position.getQuantity() - order.getQuantity());

        if (position.getQuantity() == 0) {
            positionRepository.delete(position);
        } else {
            positionRepository.save(position);
        }

        CashBalance cash = getOrCreateCash(userId);
        BigDecimal amount = price.multiply(BigDecimal.valueOf(order.getQuantity()));
        cash.setCash(cash.getCash().add(amount));
        cashBalanceRepository.save(cash);
    }

    private boolean shouldFill(String side, String orderType, BigDecimal currentPrice, BigDecimal limitPrice) {
        if ("MARKET".equals(orderType)) {
            return true;
        }

        if ("BUY".equals(side)) {
            return currentPrice.compareTo(limitPrice) <= 0;
        }

        return currentPrice.compareTo(limitPrice) >= 0;
    }

    private CashBalance getOrCreateCash(Long userId) {
        return cashBalanceRepository.findByUserId(userId)
                .orElseGet(() -> {
                    CashBalance c = new CashBalance();
                    c.setUserId(userId);
                    c.setCash(INITIAL_CASH);
                    return cashBalanceRepository.save(c);
                });
    }

    private void validate(OrderRequest request) {
        if (request.getStockCode() == null || request.getStockCode().isBlank()) {
            throw new IllegalArgumentException("銘柄コードは必須です。");
        }

        if (request.getQuantity() == null || request.getQuantity() <= 0) {
            throw new IllegalArgumentException("数量は1以上で入力してください。");
        }

        if (request.getCurrentPrice() == null || request.getCurrentPrice().compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("現在価格が不正です。");
        }

        String side = request.getSide() == null ? "" : request.getSide().toUpperCase();
        if (!side.equals("BUY") && !side.equals("SELL")) {
            throw new IllegalArgumentException("売買区分が不正です。");
        }

        String orderType = request.getOrderType() == null ? "" : request.getOrderType().toUpperCase();
        if (!orderType.equals("MARKET") && !orderType.equals("LIMIT")) {
            throw new IllegalArgumentException("注文種別が不正です。");
        }

        if (orderType.equals("LIMIT")
                && (request.getLimitPrice() == null || request.getLimitPrice().compareTo(BigDecimal.ZERO) <= 0)) {
            throw new IllegalArgumentException("指値価格は必須です。");
        }
    }

    private String normalizeCode(String code) {
        if (code == null) return "";
        String value = code.trim().toUpperCase();

        if (value.length() == 5 && value.endsWith("0")) {
            return value.substring(0, 4);
        }

        return value;
    }
}