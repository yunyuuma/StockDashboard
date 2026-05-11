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
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TradingService {

    private final CashBalanceRepository cashBalanceRepository;
    private final PositionRepository positionRepository;
    private final TradeOrderRepository tradeOrderRepository;
    private final TradeRepository tradeRepository;
    private final StockRepository stockRepository;
    private final StockPriceService stockPriceService;
    private final PortfolioSnapshotService portfolioSnapshotService;

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

                    BigDecimal currentPrice = stockPriceService.getCurrentPrice(p.getStockCode());
                    if (currentPrice == null || currentPrice.compareTo(BigDecimal.ZERO) <= 0) {
                        currentPrice = p.getAveragePrice();
                    }

                    BigDecimal valuationAmount = currentPrice.multiply(BigDecimal.valueOf(p.getQuantity()));
                    BigDecimal costAmount = p.getAveragePrice().multiply(BigDecimal.valueOf(p.getQuantity()));
                    BigDecimal profitLoss = valuationAmount.subtract(costAmount);

                    BigDecimal profitLossRate = BigDecimal.ZERO;
                    if (costAmount.compareTo(BigDecimal.ZERO) > 0) {
                        profitLossRate = profitLoss
                                .multiply(BigDecimal.valueOf(100))
                                .divide(costAmount, 2, RoundingMode.HALF_UP);
                    }

                    return new PositionResponse(
                            p.getStockCode(),
                            stock != null ? stock.getName() : "",
                            stock != null ? stock.getMarket() : "",
                            stock != null ? stock.getSector() : "",
                            p.getQuantity(),
                            p.getAveragePrice(),
                            currentPrice,
                            valuationAmount,
                            profitLoss,
                            profitLossRate
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

    @Transactional(readOnly = true)
    public List<OrderListResponse> orders(Long userId) {
        return tradeOrderRepository.findByUserIdOrderByOrderedAtDesc(userId)
                .stream()
                .map(this::toOrderListResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<OrderListResponse> openOrders(Long userId) {
        return tradeOrderRepository.findByUserIdAndStatusOrderByOrderedAtDesc(userId, "OPEN")
                .stream()
                .map(this::toOrderListResponse)
                .toList();
    }

    @Transactional
    public OrderResponse order(Long userId, OrderRequest request) {
        validate(request);

        String stockCode = normalizeCode(request.getStockCode());
        String side = request.getSide().trim().toUpperCase();
        String orderType = request.getOrderType().trim().toUpperCase();

        BigDecimal currentPrice = request.getCurrentPrice();
        BigDecimal limitPrice = request.getLimitPrice();
        BigDecimal stopPrice = request.getStopPrice();

        boolean shouldFill = shouldFill(side, orderType, currentPrice, limitPrice, stopPrice);

        TradeOrder order = new TradeOrder();
        order.setUserId(userId);
        order.setStockCode(stockCode);
        order.setSide(side);
        order.setOrderType(orderType);
        order.setQuantity(request.getQuantity());
        order.setLimitPrice(limitPrice);
        order.setStopPrice(stopPrice);
        order.setCurrentPrice(currentPrice);
        order.setStatus(shouldFill ? "FILLED" : "OPEN");
        order.setOrderedAt(LocalDateTime.now());
        order.setAlgoType("NONE");
        order.setGroupId(null);
        order.setParentOrderId(null);

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
                savedOrder.getStopPrice(),
                savedOrder.getCurrentPrice(),
                savedOrder.getStatus(),
                shouldFill ? "注文が約定しました。" : "注文を受付しました。"
        );
    }

    @Transactional
    public OrderResponse algoOrder(Long userId, AlgoOrderRequest request) {
        validateAlgo(request);

        String algoType = request.getAlgoType().trim().toUpperCase();
        String stockCode = normalizeCode(request.getStockCode());
        String groupId = UUID.randomUUID().toString();

        if ("IFD".equals(algoType)) {
            return createIfdOrder(userId, request, stockCode, groupId);
        }

        if ("OCO".equals(algoType)) {
            return createOcoOrder(userId, request, stockCode, groupId);
        }

        if ("IFDOCO".equals(algoType)) {
            return createIfdOcoOrder(userId, request, stockCode, groupId);
        }

        throw new IllegalArgumentException("アルゴ注文種別が不正です。");
    }

    private OrderResponse createIfdOrder(
            Long userId,
            AlgoOrderRequest request,
            String stockCode,
            String groupId
    ) {
        TradeOrder entry = createOpenOrder(
                userId,
                stockCode,
                "BUY",
                "LIMIT",
                request.getQuantity(),
                request.getEntryLimitPrice(),
                null,
                request.getCurrentPrice(),
                "IFD",
                groupId,
                null
        );

        TradeOrder profit = createOpenOrder(
                userId,
                stockCode,
                "SELL",
                "LIMIT",
                request.getQuantity(),
                request.getProfitLimitPrice(),
                null,
                request.getCurrentPrice(),
                "IFD",
                groupId,
                entry.getId()
        );
        profit.setStatus("WAITING");
        tradeOrderRepository.save(profit);

        return new OrderResponse(
                entry.getId(),
                stockCode,
                "BUY",
                "LIMIT",
                request.getQuantity(),
                request.getEntryLimitPrice(),
                null,
                request.getCurrentPrice(),
                "OPEN",
                "IFD注文を受付しました。"
        );
    }

    private OrderResponse createOcoOrder(
            Long userId,
            AlgoOrderRequest request,
            String stockCode,
            String groupId
    ) {
        TradeOrder profit = createOpenOrder(
                userId,
                stockCode,
                "SELL",
                "LIMIT",
                request.getQuantity(),
                request.getProfitLimitPrice(),
                null,
                request.getCurrentPrice(),
                "OCO",
                groupId,
                null
        );

        createOpenOrder(
                userId,
                stockCode,
                "SELL",
                "STOP",
                request.getQuantity(),
                null,
                request.getStopPrice(),
                request.getCurrentPrice(),
                "OCO",
                groupId,
                null
        );

        return new OrderResponse(
                profit.getId(),
                stockCode,
                "SELL",
                "LIMIT",
                request.getQuantity(),
                request.getProfitLimitPrice(),
                request.getStopPrice(),
                request.getCurrentPrice(),
                "OPEN",
                "OCO注文を受付しました。"
        );
    }

    private OrderResponse createIfdOcoOrder(
            Long userId,
            AlgoOrderRequest request,
            String stockCode,
            String groupId
    ) {
        TradeOrder entry = createOpenOrder(
                userId,
                stockCode,
                "BUY",
                "LIMIT",
                request.getQuantity(),
                request.getEntryLimitPrice(),
                null,
                request.getCurrentPrice(),
                "IFDOCO",
                groupId,
                null
        );

        TradeOrder profit = createOpenOrder(
                userId,
                stockCode,
                "SELL",
                "LIMIT",
                request.getQuantity(),
                request.getProfitLimitPrice(),
                null,
                request.getCurrentPrice(),
                "IFDOCO",
                groupId,
                entry.getId()
        );
        profit.setStatus("WAITING");
        tradeOrderRepository.save(profit);

        TradeOrder stop = createOpenOrder(
                userId,
                stockCode,
                "SELL",
                "STOP",
                request.getQuantity(),
                null,
                request.getStopPrice(),
                request.getCurrentPrice(),
                "IFDOCO",
                groupId,
                entry.getId()
        );
        stop.setStatus("WAITING");
        tradeOrderRepository.save(stop);

        return new OrderResponse(
                entry.getId(),
                stockCode,
                "BUY",
                "LIMIT",
                request.getQuantity(),
                request.getEntryLimitPrice(),
                request.getStopPrice(),
                request.getCurrentPrice(),
                "OPEN",
                "IFDOCO注文を受付しました。"
        );
    }

    private TradeOrder createOpenOrder(
            Long userId,
            String stockCode,
            String side,
            String orderType,
            Integer quantity,
            BigDecimal limitPrice,
            BigDecimal stopPrice,
            BigDecimal currentPrice,
            String algoType,
            String groupId,
            Long parentOrderId
    ) {
        TradeOrder order = new TradeOrder();
        order.setUserId(userId);
        order.setStockCode(stockCode);
        order.setSide(side);
        order.setOrderType(orderType);
        order.setQuantity(quantity);
        order.setLimitPrice(limitPrice);
        order.setStopPrice(stopPrice);
        order.setCurrentPrice(currentPrice);
        order.setStatus("OPEN");
        order.setOrderedAt(LocalDateTime.now());
        order.setAlgoType(algoType);
        order.setGroupId(groupId);
        order.setParentOrderId(parentOrderId);
        return tradeOrderRepository.save(order);
    }

    @Transactional
    public void cancelOrder(Long userId, Long orderId) {
        TradeOrder order = tradeOrderRepository.findById(orderId)
                .orElseThrow(() -> new IllegalArgumentException("注文が存在しません。"));

        if (!order.getUserId().equals(userId)) {
            throw new IllegalArgumentException("他ユーザの注文は取消できません。");
        }

        if (!"OPEN".equals(order.getStatus()) && !"WAITING".equals(order.getStatus())) {
            throw new IllegalArgumentException("未約定注文以外は取消できません。");
        }

        order.setStatus("CANCELED");
        order.setCanceledAt(LocalDateTime.now());
        tradeOrderRepository.save(order);
    }

    @Transactional
    public int checkOpenOrders(Long userId) {
        List<TradeOrder> orders =
                tradeOrderRepository.findByUserIdAndStatusOrderByOrderedAtDesc(userId, "OPEN");

        int filledCount = 0;

        for (TradeOrder order : orders) {
            BigDecimal currentPrice = order.getCurrentPrice();

            if (currentPrice == null || currentPrice.compareTo(BigDecimal.ZERO) <= 0) {
                continue;
            }

            boolean shouldFill = shouldFill(
                    order.getSide(),
                    order.getOrderType(),
                    currentPrice,
                    order.getLimitPrice(),
                    order.getStopPrice()
            );

            if (!shouldFill) {
                continue;
            }

            order.setStatus("FILLED");
            order.setFilledAt(LocalDateTime.now());
            tradeOrderRepository.save(order);

            executeTrade(userId, order, currentPrice);
            afterAlgoFilled(order);

            filledCount++;
        }

        return filledCount;
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

    private OrderListResponse toOrderListResponse(TradeOrder order) {
        Stock stock = stockRepository.findById(order.getStockCode()).orElse(null);

        return new OrderListResponse(
                order.getId(),
                order.getStockCode(),
                stock != null ? stock.getName() : "",
                stock != null ? stock.getMarket() : "",
                stock != null ? stock.getSector() : "",
                order.getSide(),
                order.getOrderType(),
                order.getQuantity(),
                order.getLimitPrice(),
                order.getStopPrice(),
                order.getCurrentPrice(),
                order.getStatus(),
                order.getOrderedAt(),
                order.getFilledAt(),
                order.getCanceledAt(),
                order.getAlgoType(),
                order.getGroupId(),
                order.getParentOrderId()
        );
    }

    private void afterAlgoFilled(TradeOrder filledOrder) {
        String algoType = filledOrder.getAlgoType();

        if (algoType == null || algoType.isBlank() || "NONE".equals(algoType)) {
            return;
        }

        List<TradeOrder> waitingChildren =
                tradeOrderRepository.findByParentOrderIdAndStatus(filledOrder.getId(), "WAITING");

        for (TradeOrder child : waitingChildren) {
            child.setStatus("OPEN");
            tradeOrderRepository.save(child);
        }

        if ("OCO".equals(algoType) || "IFDOCO".equals(algoType)) {
            List<TradeOrder> sameGroupOpenOrders =
                    tradeOrderRepository.findByGroupIdAndStatus(filledOrder.getGroupId(), "OPEN");

            for (TradeOrder order : sameGroupOpenOrders) {
                if (!order.getId().equals(filledOrder.getId())) {
                    order.setStatus("CANCELED");
                    order.setCanceledAt(LocalDateTime.now());
                    tradeOrderRepository.save(order);
                }
            }
        }
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

        portfolioSnapshotService.saveSnapshot(
                userId,
                order.getStockCode() + " " + ("BUY".equals(order.getSide()) ? "買い" : "売り")
        );
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

    private boolean shouldFill(
            String side,
            String orderType,
            BigDecimal currentPrice,
            BigDecimal limitPrice,
            BigDecimal stopPrice
    ) {
        if ("MARKET".equals(orderType)) {
            return true;
        }

        if ("LIMIT".equals(orderType)) {
            if ("BUY".equals(side)) {
                return currentPrice.compareTo(limitPrice) <= 0;
            }
            return currentPrice.compareTo(limitPrice) >= 0;
        }

        if ("STOP".equals(orderType)) {
            if ("BUY".equals(side)) {
                return currentPrice.compareTo(stopPrice) >= 0;
            }
            return currentPrice.compareTo(stopPrice) <= 0;
        }

        return false;
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

        String side = request.getSide() == null ? "" : request.getSide().trim().toUpperCase();
        if (!side.equals("BUY") && !side.equals("SELL")) {
            throw new IllegalArgumentException("売買区分が不正です。");
        }

        String orderType = request.getOrderType() == null ? "" : request.getOrderType().trim().toUpperCase();
        if (!orderType.equals("MARKET") && !orderType.equals("LIMIT") && !orderType.equals("STOP")) {
            throw new IllegalArgumentException("注文種別が不正です。");
        }

        if (orderType.equals("LIMIT")
                && (request.getLimitPrice() == null || request.getLimitPrice().compareTo(BigDecimal.ZERO) <= 0)) {
            throw new IllegalArgumentException("指値価格は必須です。");
        }

        if (orderType.equals("STOP")
                && (request.getStopPrice() == null || request.getStopPrice().compareTo(BigDecimal.ZERO) <= 0)) {
            throw new IllegalArgumentException("逆指値価格は必須です。");
        }
    }

    private void validateAlgo(AlgoOrderRequest request) {
        if (request.getStockCode() == null || request.getStockCode().isBlank()) {
            throw new IllegalArgumentException("銘柄コードは必須です。");
        }

        if (request.getQuantity() == null || request.getQuantity() <= 0) {
            throw new IllegalArgumentException("数量は1以上で入力してください。");
        }

        if (request.getCurrentPrice() == null || request.getCurrentPrice().compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("現在価格が不正です。");
        }

        String algoType = request.getAlgoType() == null ? "" : request.getAlgoType().trim().toUpperCase();

        if (!algoType.equals("IFD") && !algoType.equals("OCO") && !algoType.equals("IFDOCO")) {
            throw new IllegalArgumentException("アルゴ注文種別が不正です。");
        }

        if ("IFD".equals(algoType)) {
            if (request.getEntryLimitPrice() == null || request.getEntryLimitPrice().compareTo(BigDecimal.ZERO) <= 0) {
                throw new IllegalArgumentException("IFDの買い指値価格は必須です。");
            }
            if (request.getProfitLimitPrice() == null || request.getProfitLimitPrice().compareTo(BigDecimal.ZERO) <= 0) {
                throw new IllegalArgumentException("IFDの利確指値価格は必須です。");
            }
        }

        if ("OCO".equals(algoType)) {
            if (request.getProfitLimitPrice() == null || request.getProfitLimitPrice().compareTo(BigDecimal.ZERO) <= 0) {
                throw new IllegalArgumentException("OCOの利確指値価格は必須です。");
            }
            if (request.getStopPrice() == null || request.getStopPrice().compareTo(BigDecimal.ZERO) <= 0) {
                throw new IllegalArgumentException("OCOの逆指値価格は必須です。");
            }
        }

        if ("IFDOCO".equals(algoType)) {
            if (request.getEntryLimitPrice() == null || request.getEntryLimitPrice().compareTo(BigDecimal.ZERO) <= 0) {
                throw new IllegalArgumentException("IFDOCOの買い指値価格は必須です。");
            }
            if (request.getProfitLimitPrice() == null || request.getProfitLimitPrice().compareTo(BigDecimal.ZERO) <= 0) {
                throw new IllegalArgumentException("IFDOCOの利確指値価格は必須です。");
            }
            if (request.getStopPrice() == null || request.getStopPrice().compareTo(BigDecimal.ZERO) <= 0) {
                throw new IllegalArgumentException("IFDOCOの損切逆指値価格は必須です。");
            }
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