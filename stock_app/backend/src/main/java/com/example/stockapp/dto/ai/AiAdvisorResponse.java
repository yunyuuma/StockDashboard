package com.example.stockapp.dto.ai;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.List;

@Getter
@AllArgsConstructor
public class AiAdvisorResponse {
    private String riskLevel;
    private String summary;
    private List<String> portfolioAdvice;
    private List<String> tradingAdvice;
    private List<String> warnings;
}