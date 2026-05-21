package com.example.stockapp.controller;

import com.example.stockapp.dto.StockChartPointResponse;
import com.example.stockapp.dto.StockCompanyResponse;
import com.example.stockapp.dto.StockDetailResponse;
import com.example.stockapp.dto.StockMetricsResponse;
import com.example.stockapp.dto.StockNewsResponse;
import com.example.stockapp.service.StockDetailService;
import com.example.stockapp.service.StockNewsService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/stocks")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class StockDetailController {

    private final StockDetailService stockDetailService;
    private final StockNewsService stockNewsService;

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
        return stockNewsService.getNews(code);
    }
}