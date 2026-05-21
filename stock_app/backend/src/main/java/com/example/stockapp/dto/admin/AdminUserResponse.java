package com.example.stockapp.dto.admin;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class AdminUserResponse {

    private Long userId;
    private String userName;
    private String email;
    private String role;
    private boolean twoFactorEnabled;
}