package com.example.stockapp.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class StockMetricsResponse {
    private double per;
    private double pbr;
    private double roe;
    private double dividendYield;
    private double marketCap;
}