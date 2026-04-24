package com.example.stockapp.dto.auth;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class AuthResponse {
    private Long userId;
    private String userName;
    private String email;
    private String role;
    private boolean twoFactorEnabled;
    private String token;
}
