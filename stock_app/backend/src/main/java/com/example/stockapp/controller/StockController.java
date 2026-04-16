package com.example.stockapp.controller;

import com.example.stockapp.client.JQuantsClient;
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
    private final JQuantsClient jQuantsClient;

    @GetMapping
    public List<StockResponse> getStocks(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "100") int size
    ) {
        return stockService.getStocks(page, size);
    }

    @PostMapping("/reload")
    public String reloadCache() {
        stockService.reloadCache();
        return "reloaded";
    }

    @GetMapping("/debug")
    public Object debug() {
        return jQuantsClient.getMaster(null);
    }
}