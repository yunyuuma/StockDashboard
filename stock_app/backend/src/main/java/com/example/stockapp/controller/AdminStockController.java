package com.example.stockapp.controller;

import com.example.stockapp.dto.admin.AdminStockRequest;
import com.example.stockapp.dto.admin.AdminStockResponse;
import com.example.stockapp.service.AdminStockService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/stocks")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AdminStockController {

    private final AdminStockService adminStockService;

    @GetMapping
    public List<AdminStockResponse> getStocks() {
        return adminStockService.getStocks();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public AdminStockResponse create(@Valid @RequestBody AdminStockRequest request) {
        return adminStockService.create(request);
    }

    @PutMapping("/{code}")
    public AdminStockResponse update(
            @PathVariable String code,
            @Valid @RequestBody AdminStockRequest request
    ) {
        return adminStockService.update(code, request);
    }

    @DeleteMapping("/{code}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable String code) {
        adminStockService.delete(code);
    }
}