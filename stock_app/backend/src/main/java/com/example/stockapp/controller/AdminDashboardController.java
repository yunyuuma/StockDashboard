package com.example.stockapp.controller;

import com.example.stockapp.dto.admin.AdminDashboardResponse;
import com.example.stockapp.service.AdminDashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/dashboard")
@RequiredArgsConstructor
@CrossOrigin("*")
public class AdminDashboardController {

    private final AdminDashboardService service;

    @GetMapping
    public AdminDashboardResponse summary() {
        return service.getSummary();
    }
}