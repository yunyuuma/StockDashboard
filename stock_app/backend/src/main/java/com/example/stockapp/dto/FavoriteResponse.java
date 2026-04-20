package com.example.stockapp.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class FavoriteResponse {
    private Integer id;
    private Integer userId;
    private String code;
    private String name;
    private String market;
    private String sector;
}