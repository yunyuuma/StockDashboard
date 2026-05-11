package com.example.stockapp.dto.admin;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class AdminUserRoleUpdateRequest {

    @NotBlank(message = "権限は必須です。")
    private String role;
}