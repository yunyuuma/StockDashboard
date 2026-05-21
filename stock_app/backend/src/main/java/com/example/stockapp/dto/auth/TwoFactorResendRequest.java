package com.example.stockapp.dto.auth;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class TwoFactorResendRequest {

    @NotBlank(message = "認証IDは必須です。")
    private String challengeId;
}