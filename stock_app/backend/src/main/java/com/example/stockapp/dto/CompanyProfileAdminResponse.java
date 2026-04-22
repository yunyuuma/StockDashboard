package com.example.stockapp.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class CompanyProfileAdminResponse {
    private Integer id;
    private String stockCode;
    private String companyName;
    private String market;
    private String industry;
    private String website;
    private String description;
    private String mapQuery;
    private String trendsKeyword;
    private boolean registered;
}