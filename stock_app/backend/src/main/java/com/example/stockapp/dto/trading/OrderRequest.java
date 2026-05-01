package com.example.stockapp.dto.trading;

import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
public class OrderRequest {
    private String stockCode;
    private String side;       // BUY / SELL
    private String orderType;  // MARKET / LIMIT
    private Integer quantity;
    private BigDecimal limitPrice;
    private BigDecimal currentPrice;
}