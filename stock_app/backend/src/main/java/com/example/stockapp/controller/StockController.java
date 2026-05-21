package com.example.stockapp.controller;

import com.example.stockapp.dto.StockResponse;
import com.example.stockapp.service.StockService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/stocks")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class StockController {

    private final StockService stockService;

    @GetMapping
    public List<StockResponse> getStocks(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "30") int size,
            @RequestParam(required = false) String q,
            @RequestParam(required = false) String market
    ) {
        return stockService.getStocks(page, size, q, market);
    }

    @PostMapping("/reload")
    public String reloadCache() {
        stockService.reloadCache();
        return "reloaded";
    }
}