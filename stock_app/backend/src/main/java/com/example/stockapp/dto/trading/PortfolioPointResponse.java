package com.example.stockapp.dto.trading;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter
@AllArgsConstructor
public class PortfolioPointResponse {

    private LocalDateTime dateTime;
    private BigDecimal cash;
    private BigDecimal stockValue;
    private BigDecimal marketValue;
    private BigDecimal totalAsset;
    private String eventLabel;
}