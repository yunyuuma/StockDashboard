package com.example.stockapp.controller;

import com.example.stockapp.dto.CompanyProfileAutoFillResult;
import com.example.stockapp.service.CompanyProfileEdinetAutoFillService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/company-profiles")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AdminCompanyProfileAutoFillController {

    private final CompanyProfileEdinetAutoFillService autoFillService;

    @PostMapping("/{stockCode}/autofill-edinet")
    public CompanyProfileAutoFillResult autoFill(@PathVariable String stockCode) {
        return autoFillService.autoFillByStockCode(stockCode);
    }
}