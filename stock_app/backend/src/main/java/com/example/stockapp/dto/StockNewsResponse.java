package com.example.stockapp.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class StockNewsResponse {
    private String title;
    private String source;
    private String publishedAt;
    private String url;
}