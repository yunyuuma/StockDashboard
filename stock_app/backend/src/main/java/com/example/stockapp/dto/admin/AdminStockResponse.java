package com.example.stockapp.dto.admin;

import com.example.stockapp.entity.Stock;
import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class AdminStockResponse {

    private String code;
    private String name;
    private String market;
    private String sector;

    public static AdminStockResponse from(Stock stock) {
        return new AdminStockResponse(
                stock.getCode(),
                stock.getName(),
                stock.getMarket(),
                stock.getSector()
        );
    }
}