package com.example.stockapp.dto.ai;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.List;

@Getter
@AllArgsConstructor
public class AiPortfolioAdvisorResponse {

    private String riskLevel;

    private String summary;

    private List<String> strengths;

    private List<String> risks;

    private List<String> suggestions;
}