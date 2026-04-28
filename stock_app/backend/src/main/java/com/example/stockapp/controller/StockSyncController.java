package com.example.stockapp.controller;

import com.example.stockapp.service.StockSyncService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/stocks")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class StockSyncController {

    private final StockSyncService stockSyncService;

    @PostMapping("/sync")
    public String sync() {
        return stockSyncService.syncStocks();
    }
}