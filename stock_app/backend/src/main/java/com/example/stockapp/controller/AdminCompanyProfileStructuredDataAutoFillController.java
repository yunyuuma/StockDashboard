package com.example.stockapp.controller;

import com.example.stockapp.dto.CompanyProfileAutoFillResult;
import com.example.stockapp.service.CompanyProfileStructuredDataAutoFillService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/company-profiles")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AdminCompanyProfileStructuredDataAutoFillController {

    private final CompanyProfileStructuredDataAutoFillService autoFillService;

    @PostMapping("/{stockCode}/autofill-structured-data")
    public CompanyProfileAutoFillResult autoFill(@PathVariable String stockCode) {
        return autoFillService.autoFillByStockCode(stockCode);
    }
}