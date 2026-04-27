package com.example.stockapp.controller;

import com.example.stockapp.dto.auth.*;
import com.example.stockapp.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")

public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.ok(authService.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @PostMapping("/logout")
    public ResponseEntity<Map<String, String>> logout() {
        return ResponseEntity.ok(Map.of("message", "ログアウトしました。"));
    }

    @PostMapping("/2fa/verify")
    public ResponseEntity<AuthResponse> verifyTwoFactor(
            @Valid @RequestBody TwoFactorVerifyRequest request
    ) {
        return ResponseEntity.ok(authService.verifyTwoFactor(request));
    }

    @PostMapping("/2fa/resend")
    public ResponseEntity<Map<String, String>> resendTwoFactor(
            @Valid @RequestBody TwoFactorResendRequest request
    ) {
        authService.resendTwoFactor(request);
        return ResponseEntity.ok(Map.of("message", "認証コードを再送しました。"));
    }
}