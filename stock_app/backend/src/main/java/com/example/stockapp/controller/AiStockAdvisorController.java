package com.example.stockapp.controller;

import com.example.stockapp.dto.ai.AiStockAdvisorResponse;
import com.example.stockapp.security.CustomUserPrincipal;
import com.example.stockapp.service.AiStockAdvisorService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/ai-advisor/stocks")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AiStockAdvisorController {

    private final AiStockAdvisorService aiStockAdvisorService;

    @GetMapping("/{code}")
    public AiStockAdvisorResponse analyzeStock(
            @AuthenticationPrincipal CustomUserPrincipal principal,
            @PathVariable String code
    ) {
        return aiStockAdvisorService.analyze(principal.getId(), code);
    }
}