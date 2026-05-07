package com.example.stockapp.controller;

import com.example.stockapp.dto.trading.PortfolioSummaryResponse;
import com.example.stockapp.security.CustomUserPrincipal;
import com.example.stockapp.service.PortfolioService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/trading/portfolio")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class PortfolioController {

    private final PortfolioService portfolioService;

    @GetMapping
    public PortfolioSummaryResponse getPortfolio(
            @AuthenticationPrincipal CustomUserPrincipal principal
    ) {
        return portfolioService.getPortfolio(principal.getId());
    }
}