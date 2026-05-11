package com.example.stockapp.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class StockChartPointResponse {
    private String date;
    private double open;
    private double high;
    private double low;
    private double close;
    private double volume;
}