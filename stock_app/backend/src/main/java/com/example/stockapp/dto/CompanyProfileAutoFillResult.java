package com.example.stockapp.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class CompanyProfileAutoFillResult {
    private String stockCode;
    private String website;
    private String description;
    private boolean updated;
}