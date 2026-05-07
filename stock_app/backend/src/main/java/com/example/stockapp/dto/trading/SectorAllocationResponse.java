package com.example.stockapp.dto.trading;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
@AllArgsConstructor
public class SectorAllocationResponse {
    private String sector;
    private BigDecimal amount;
    private BigDecimal rate;
}