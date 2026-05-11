package com.example.stockapp.dto.ai;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class AiChatRequest {
    private String message;
    private String StockCode;
}