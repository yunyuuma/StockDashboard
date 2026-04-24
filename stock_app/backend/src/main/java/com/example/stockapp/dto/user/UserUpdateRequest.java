package com.example.stockapp.dto.user;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UserUpdateRequest {

    @NotBlank(message = "ユーザ名は必須です。")
    @Size(max = 50, message = "ユーザ名は50文字以内で入力してください。")
    private String userName;

    @NotBlank(message = "メールアドレスは必須です。")
    @Email(message = "正しいメールアドレスを入力してください。")
    private String email;

    private Boolean twoFactorEnabled;
}