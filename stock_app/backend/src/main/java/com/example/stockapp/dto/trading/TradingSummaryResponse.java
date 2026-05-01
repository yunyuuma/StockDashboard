package com.example.stockapp.dto.trading;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
@AllArgsConstructor
public class TradingSummaryResponse {
    private BigDecimal cash;
    private Integer positionCount;
    private Integer tradeCount;
}