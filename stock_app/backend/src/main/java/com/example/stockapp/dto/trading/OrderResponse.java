package com.example.stockapp.dto.trading;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
@AllArgsConstructor
public class OrderResponse {

    private Long orderId;
    private String stockCode;
    private String side;
    private String orderType;
    private Integer quantity;
    private BigDecimal limitPrice;
    private BigDecimal stopPrice;
    private BigDecimal currentPrice;
    private String status;
    private String message;
}