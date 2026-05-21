package com.example.stockapp.dto.user;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class UserProfileResponse {
    private Long userId;
    private String userName;
    private String email;
    private String role;
    private boolean twoFactorEnabled;
}