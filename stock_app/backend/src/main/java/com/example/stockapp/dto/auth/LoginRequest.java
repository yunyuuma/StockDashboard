package com.example.stockapp.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter

public class LoginRequest {

    @NotBlank(message = "メールアドレスは必須です。")
    @Email(message = "正しいメールアドレスを入力してください。")

    private String email;

    @NotBlank(message = "パスワードは必須です。")
    private String password;
}