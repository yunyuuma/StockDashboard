package com.example.stockapp.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class StockDetailResponse {
    private String code;
    private String name;
    private String market;
    private String industry;
    private double price;
    private double changePct;
    private double high;
    private double low;
    private double open;
    private double close;
    private double volume;
}