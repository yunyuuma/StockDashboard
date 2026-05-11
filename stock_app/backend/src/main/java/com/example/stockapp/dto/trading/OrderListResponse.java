package com.example.stockapp.dto.trading;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter
@AllArgsConstructor
public class OrderListResponse {

    private Long orderId;
    private String stockCode;
    private String stockName;
    private String market;
    private String sector;
    private String side;
    private String orderType;
    private Integer quantity;
    private BigDecimal limitPrice;
    private BigDecimal stopPrice;
    private BigDecimal currentPrice;
    private String status;
    private LocalDateTime orderedAt;
    private LocalDateTime filledAt;
    private LocalDateTime canceledAt;
    private String algoType;
    private String groupId;
    private Long parentOrderId;
}