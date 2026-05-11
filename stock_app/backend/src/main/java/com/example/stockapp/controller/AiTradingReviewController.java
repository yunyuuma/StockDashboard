package com.example.stockapp.controller;

import com.example.stockapp.dto.ai.AiTradingReviewResponse;
import com.example.stockapp.security.CustomUserPrincipal;
import com.example.stockapp.service.AiTradingReviewService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/ai-advisor")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AiTradingReviewController {

    private final AiTradingReviewService aiTradingReviewService;

    @GetMapping("/trading-review")
    public AiTradingReviewResponse review(
            @AuthenticationPrincipal CustomUserPrincipal principal
    ) {
        return aiTradingReviewService.review(principal.getId());
    }
}