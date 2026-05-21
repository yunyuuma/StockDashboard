package com.example.stockapp.dto.trading;

import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
public class AlgoOrderRequest {

    private String stockCode;
    private Integer quantity;
    private BigDecimal currentPrice;

    // IFD用
    private BigDecimal entryLimitPrice;
    private BigDecimal profitLimitPrice;

    // OCO / IFDOCO用
    private BigDecimal stopPrice;

    // IFD / OCO / IFDOCO
    private String algoType;
}