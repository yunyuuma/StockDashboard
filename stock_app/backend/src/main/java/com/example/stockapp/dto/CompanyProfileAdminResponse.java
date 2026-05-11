package com.example.stockapp.dto;

import com.example.stockapp.entity.CompanyProfile;
import com.example.stockapp.entity.Stock;
import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class CompanyProfileAdminResponse {

    private Integer id;
    private String stockCode;
    private String stockName;
    private String market;
    private String sector;
    private String website;
    private String description;
    private String mapQuery;
    private String trendsKeyword;
    private boolean registered;

    public static CompanyProfileAdminResponse from(Stock stock, CompanyProfile profile) {
        return new CompanyProfileAdminResponse(
                profile != null ? profile.getId() : null,
                stock.getCode(),
                stock.getName(),
                stock.getMarket(),
                stock.getSector(),
                profile != null ? profile.getWebsite() : "",
                profile != null ? profile.getDescription() : "",
                profile != null ? profile.getMapQuery() : "",
                profile != null ? profile.getTrendsKeyword() : "",
                profile != null
        );
    }
}