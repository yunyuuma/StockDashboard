package com.example.stockapp.service;

import com.example.stockapp.dto.admin.AdminDashboardResponse;
import com.example.stockapp.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AdminDashboardService {

    private final UserRepository userRepository;
    private final FavoriteRepository favoriteRepository;
    private final StockRepository stockRepository;
    private final CompanyProfileRepository companyProfileRepository;

    public AdminDashboardResponse getSummary() {

        long userCount = userRepository.count();
        long adminCount = userRepository.findAll()
                .stream()
                .filter(x -> "ADMIN".equals(x.getRole()))
                .count();

        long twoFactor = userRepository.findAll()
                .stream()
                .filter(x -> x.isTwoFactorEnabled())
                .count();

        return new AdminDashboardResponse(
                userCount,
                adminCount,
                favoriteRepository.count(),
                stockRepository.count(),
                companyProfileRepository.count(),
                twoFactor
        );
    }
}