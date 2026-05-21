package com.example.stockapp.dto.admin;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class AdminStockRequest {

    @NotBlank(message = "銘柄コードは必須です。")
    private String code;

    @NotBlank(message = "銘柄名は必須です。")
    private String name;

    @NotBlank(message = "市場は必須です。")
    private String market;

    @NotBlank(message = "業種は必須です。")
    private String sector;
}