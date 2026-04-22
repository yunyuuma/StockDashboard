package com.example.stockapp.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class StockMetricsResponse {

    private String disclosedDate;
    private String disclosedTime;
    private String typeOfDocument;
    private String currentPeriodEndDate;

    private double netSales;
    private double operatingProfit;
    private double ordinaryProfit;
    private double profit;
    private double earningsPerShare;

    private double forecastNetSales;
    private double forecastOperatingProfit;
    private double forecastOrdinaryProfit;
    private double forecastProfit;

    private double annualDividendPerShareForecast;
}