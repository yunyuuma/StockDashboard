package com.example.stockapp.dto.auth;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class AuthResponse {

    private Long userId;
    private String name;
    private String email;
    private String role;
    private String token;

    private boolean requiresTwoFactor;
    private String challengeId;

    public static AuthResponse loginSuccess(
            Long userId,
            String name,
            String email,
            String role,
            String token
    ) {
        return new AuthResponse(
                userId,
                name,
                email,
                role,
                token,
                false,
                null
        );
    }

    public static AuthResponse twoFactorRequired(
            Long userId,
            String name,
            String email,
            String role,
            String challengeId
    ) {
        return new AuthResponse(
                userId,
                name,
                email,
                role,
                null,
                true,
                challengeId
        );
    }
}