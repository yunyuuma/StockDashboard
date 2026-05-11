package com.example.stockapp.controller;

import com.example.stockapp.dto.ai.AiChatRequest;
import com.example.stockapp.dto.ai.AiChatResponse;
import com.example.stockapp.security.CustomUserPrincipal;
import com.example.stockapp.service.OllamaChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/ai-advisor")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AiChatController {

    private final OllamaChatService ollamaChatService;

    @PostMapping("/chat")
    public AiChatResponse chat(
            @AuthenticationPrincipal CustomUserPrincipal principal,
            @RequestBody AiChatRequest request
    ) {
        return ollamaChatService.chat(
                principal.getId(),
                request.getMessage(),
                request.getStockCode()
        );
    }
}