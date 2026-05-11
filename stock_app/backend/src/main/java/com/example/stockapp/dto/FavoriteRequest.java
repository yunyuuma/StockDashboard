package com.example.stockapp.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class FavoriteRequest {
    private Integer userId;
    private String stockCode;
}