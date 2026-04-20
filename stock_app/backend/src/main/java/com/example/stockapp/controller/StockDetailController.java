package com.example.stockapp.controller;

import com.example.stockapp.dto.*;
import com.example.stockapp.service.StockDetailService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/stocks")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class StockDetailController {

    private final StockDetailService stockDetailService;

    @GetMapping("/{code}")
    public StockDetailResponse getSummary(@PathVariable String code) {
        return stockDetailService.getSummary(code);
    }

    @GetMapping("/{code}/chart")
    public List<StockChartPointResponse> getChart(@PathVariable String code) {
        return stockDetailService.getChart(code);
    }

    @GetMapping("/{code}/metrics")
    public StockMetricsResponse getMetrics(@PathVariable String code) {
        return stockDetailService.getMetrics(code);
    }

    @GetMapping("/{code}/company")
    public StockCompanyResponse getCompany(@PathVariable String code) {
        return stockDetailService.getCompany(code);
    }

    @GetMapping("/{code}/news")
    public List<StockNewsResponse> getNews(@PathVariable String code) {
        return stockDetailService.getNews(code);
    }
}