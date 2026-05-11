package com.example.stockapp.controller;

import com.example.stockapp.dto.user.*;
import com.example.stockapp.security.CustomUserPrincipal;
import com.example.stockapp.service.UserService;
import com.example.stockapp.dto.user.TwoFactorSettingRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/users/me")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class UserController {

    private final UserService userService;

    @GetMapping
    public ResponseEntity<UserProfileResponse> getProfile(@AuthenticationPrincipal CustomUserPrincipal principal) {
        return ResponseEntity.ok(userService.getMyProfile(principal));
    }

    @PutMapping
    public ResponseEntity<UserProfileResponse> updateProfile(
            @AuthenticationPrincipal CustomUserPrincipal principal,
            @Valid @RequestBody UserUpdateRequest request) {
        return ResponseEntity.ok(userService.updateMyProfile(principal, request));
    }

    @PutMapping("/password")
    public ResponseEntity<Map<String, String>> updatePassword(
            @AuthenticationPrincipal CustomUserPrincipal principal,
            @Valid @RequestBody PasswordUpdateRequest request) {
        userService.updateMyPassword(principal, request);
        return ResponseEntity.ok(Map.of("message", "パスワードを更新しました。"));
    }

    @PutMapping("/2fa")
    public ResponseEntity<UserProfileResponse> updateTwoFactorSetting(
            @AuthenticationPrincipal CustomUserPrincipal principal,
            @RequestBody TwoFactorSettingRequest request
    ) {
        return ResponseEntity.ok(
                userService.updateTwoFactorSetting(principal, request)
        );
    }
}