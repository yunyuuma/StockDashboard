package com.example.stockapp.controller;

import com.example.stockapp.dto.ai.AiPortfolioAdvisorResponse;
import com.example.stockapp.security.CustomUserPrincipal;
import com.example.stockapp.service.AiPortfolioAdvisorService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/ai-advisor")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AiPortfolioAdvisorController {

    private final AiPortfolioAdvisorService service;

    @GetMapping("/portfolio")
    public AiPortfolioAdvisorResponse analyzePortfolio(
            @AuthenticationPrincipal CustomUserPrincipal principal
    ) {
        return service.analyze(principal.getId());
    }
}