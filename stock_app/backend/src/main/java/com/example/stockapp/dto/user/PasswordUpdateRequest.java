package com.example.stockapp.dto.user;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter

public class PasswordUpdateRequest {

    @NotBlank(message = "現在のパスワードは必須です。")
    private String currentPassword;

    @NotBlank(message = "新しいパスワードは必須です。")
    @Size(min = 8, max = 16, message = "パスワードは8~16文字で入力してください。")
    private String newPassword;
}