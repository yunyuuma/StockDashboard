package com.example.stockapp.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class FavoriteCreateRequest {
    private Long userId;
    private String stockCode;
}