package com.example.stockapp.dto.trading;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;
import java.util.List;

@Getter
@AllArgsConstructor
public class PortfolioSummaryResponse {
    private BigDecimal cash;
    private BigDecimal stockValue;
    private BigDecimal totalAsset;
    private BigDecimal profitLoss;
    private BigDecimal profitLossRate;

    private BigDecimal dailyProfitLoss;
    private BigDecimal dailyProfitLossRate;
    private BigDecimal maxDrawdown;
    private BigDecimal maxDrawdownRate;

    private List<PortfolioPointResponse> points;
    private List<SectorAllocationResponse> sectorAllocations;
}