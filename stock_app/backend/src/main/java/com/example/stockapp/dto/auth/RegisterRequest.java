package com.example.stockapp.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter

public class RegisterRequest {

    @NotBlank(message = "ユーザー名は必須です。")
    @Size(max = 50, message = "ユーザー名は50文字以内で入力してください。")
    private String userName;

    @NotBlank(message = "メールアドレスは必須です。")
    @Email(message = "正しいメールアドレスを入力してください。")
    private String email;

    @NotBlank(message = "パスワードは必須です。")
    @Size(min = 8, max = 16, message = "パスワードは8~16文字で入力してください。")
    private String password;

    private boolean twoFactorEnabled;
}