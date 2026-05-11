package com.example.stockapp.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class StockNewsResponse {

    private String title;
    private String link;
    private String publishedAt;
    private String source;
}