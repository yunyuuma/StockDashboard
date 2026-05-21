package com.example.stockapp.controller;

import com.example.stockapp.dto.ai.AiAdvisorResponse;
import com.example.stockapp.security.CustomUserPrincipal;
import com.example.stockapp.service.AiAdvisorService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/ai-advisor")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AiAdvisorController {

    private final AiAdvisorService aiAdvisorService;

    @GetMapping
    public AiAdvisorResponse analyze(
            @AuthenticationPrincipal CustomUserPrincipal principal
    ) {
        return aiAdvisorService.analyze(principal.getId());
    }
}