package com.example.stockapp.dto.ai;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.List;

@Getter
@AllArgsConstructor
public class AiTradingReviewResponse {

    private String summary;

    private int tradeCount;

    private long buyCount;

    private long sellCount;

    private List<String> goodPoints;

    private List<String> weakPoints;

    private List<String> suggestions;

    private List<String> warnings;
}