package com.example.stockapp.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class StockCompanyResponse {
    private String companyName;
    private String market;
    private String industry;
    private String description;
    private String website;
    private String mapQuery;
    private String trendsKeyword;
}