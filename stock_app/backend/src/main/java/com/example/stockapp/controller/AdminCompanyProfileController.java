package com.example.stockapp.controller;

import com.example.stockapp.dto.CompanyProfileAdminResponse;
import com.example.stockapp.dto.CompanyProfileRequest;
import com.example.stockapp.service.AdminCompanyProfileService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/company-profiles")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AdminCompanyProfileController {

    private final AdminCompanyProfileService adminCompanyProfileService;

    @GetMapping
    public List<CompanyProfileAdminResponse> getAll() {
        return adminCompanyProfileService.getAll();
    }

    @GetMapping("/{stockCode}")
    public CompanyProfileAdminResponse getByStockCode(@PathVariable String stockCode) {
        return adminCompanyProfileService.getByStockCode(stockCode);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public CompanyProfileAdminResponse create(@RequestBody CompanyProfileRequest request) {
        return adminCompanyProfileService.create(request);
    }

    @PutMapping("/{stockCode}")
    public CompanyProfileAdminResponse update(
            @PathVariable String stockCode,
            @RequestBody CompanyProfileRequest request
    ) {
        return adminCompanyProfileService.update(stockCode, request);
    }
}