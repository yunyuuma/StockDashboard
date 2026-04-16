package com.example.stockapp.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class FavoriteResponse {

    private Long id;
    private Long userId;
    private String stockCode;
    private String stockName;
    private String market;
    private String sector;
    private String createdAt;
}