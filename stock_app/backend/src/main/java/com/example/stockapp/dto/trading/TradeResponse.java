package com.example.stockapp.dto.trading;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter
@AllArgsConstructor
public class TradeResponse {
    private Long id;
    private String stockCode;
    private String stockName;
    private String market;
    private String sector;
    private String side;
    private Integer quantity;
    private BigDecimal price;
    private LocalDateTime tradedAt;
}