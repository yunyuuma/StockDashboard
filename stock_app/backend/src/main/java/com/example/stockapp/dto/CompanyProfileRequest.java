package com.example.stockapp.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CompanyProfileRequest {
    private String stockCode;
    private String website;
    private String description;
    private String mapQuery;
    private String trendsKeyword;
}