package com.example.stockapp.dto.user;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class TwoFactorSettingRequest {
    private boolean enabled;
}