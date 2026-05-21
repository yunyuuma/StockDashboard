package com.example.stockapp.dto.ai;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.List;

@Getter
@AllArgsConstructor
public class AiStockAdvisorResponse {
    private String stockCode;
    private String stockName;
    private String market;
    private String sector;
    private String riskLevel;
    private String summary;
    private List<String> analysis;
    private List<String> checkPoints;
    private List<String> warnings;
}