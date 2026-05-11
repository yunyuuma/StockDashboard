package com.example.stockapp.dto.trading;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;
import java.util.List;

@Getter
@AllArgsConstructor
public class OrderBookResponse {

    private String stockCode;
    private BigDecimal currentPrice;
    private List<BoardRow> sellBoard;
    private List<BoardRow> buyBoard;

    @Getter
    @AllArgsConstructor
    public static class BoardRow {
        private BigDecimal price;
        private Integer quantity;
    }
}