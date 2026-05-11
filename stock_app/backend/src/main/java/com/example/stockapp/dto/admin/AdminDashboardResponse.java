package com.example.stockapp.dto.admin;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class AdminDashboardResponse {

    private long userCount;
    private long adminCount;
    private long favoriteCount;
    private long stockCount;
    private long companyProfileCount;
    private long twoFactorUserCount;
}