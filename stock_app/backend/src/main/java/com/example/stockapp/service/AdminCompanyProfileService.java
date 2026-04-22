package com.example.stockapp.service;

import com.example.stockapp.dto.CompanyProfileAdminResponse;
import com.example.stockapp.dto.CompanyProfileRequest;
import com.example.stockapp.dto.StockResponse;
import com.example.stockapp.entity.CompanyProfile;
import com.example.stockapp.repository.CompanyProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminCompanyProfileService {

    private final CompanyProfileRepository companyProfileRepository;
    private final StockService stockService;

    @Transactional(readOnly = true)
    public List<CompanyProfileAdminResponse> getAll() {
        Map<String, CompanyProfile> profileMap = companyProfileRepository.findAll().stream()
                .collect(Collectors.toMap(
                        p -> p.getStockCode().toUpperCase(),
                        Function.identity()
                ));

        return stockService.getAllStocks().stream()
                .sorted(Comparator.comparing(StockResponse::getCode))
                .map(stock -> {
                    CompanyProfile profile = profileMap.get(stock.getCode().toUpperCase());
                    return toResponse(stock, profile);
                })
                .toList();
    }

    @Transactional(readOnly = true)
    public CompanyProfileAdminResponse getByStockCode(String stockCode) {
        String normalizedStockCode = normalizeStockCode(stockCode);

        StockResponse stock = stockService.getAllStocks().stream()
                .filter(s -> s.getCode().equalsIgnoreCase(normalizedStockCode))
                .findFirst()
                .orElseThrow(() -> new RuntimeException("stock not found"));

        CompanyProfile profile = companyProfileRepository.findByStockCode(normalizedStockCode)
                .orElse(null);

        return toResponse(stock, profile);
    }

    @Transactional
    public CompanyProfileAdminResponse create(CompanyProfileRequest request) {
        validateRequest(request);

        String normalizedStockCode = normalizeStockCode(request.getStockCode());

        if (companyProfileRepository.existsByStockCode(normalizedStockCode)) {
            throw new RuntimeException("company profile already exists");
        }

        StockResponse stock = ensureStockExists(normalizedStockCode);

        CompanyProfile profile = new CompanyProfile();
        profile.setStockCode(normalizedStockCode);
        profile.setWebsite(trim(request.getWebsite()));
        profile.setDescription(trim(request.getDescription()));
        profile.setMapQuery(buildMapQuery(normalizedStockCode, request));
        profile.setTrendsKeyword(buildTrendsKeyword(normalizedStockCode, request));

        CompanyProfile saved = companyProfileRepository.save(profile);
        return toResponse(stock, saved);
    }

    @Transactional
    public CompanyProfileAdminResponse update(String stockCode, CompanyProfileRequest request) {
        validateRequestForUpdate(request);

        String normalizedStockCode = normalizeStockCode(stockCode);

        StockResponse stock = ensureStockExists(normalizedStockCode);

        CompanyProfile profile = companyProfileRepository.findByStockCode(normalizedStockCode)
                .orElseThrow(() -> new RuntimeException("company profile not found"));

        profile.setWebsite(trim(request.getWebsite()));
        profile.setDescription(trim(request.getDescription()));
        profile.setMapQuery(buildMapQuery(normalizedStockCode, request));
        profile.setTrendsKeyword(buildTrendsKeyword(normalizedStockCode, request));

        CompanyProfile saved = companyProfileRepository.save(profile);
        return toResponse(stock, saved);
    }

    private CompanyProfileAdminResponse toResponse(StockResponse stock, CompanyProfile profile) {
        return new CompanyProfileAdminResponse(
                profile != null ? profile.getId() : null,
                stock.getCode(),
                nullToEmpty(stock.getName()),
                nullToEmpty(stock.getMarket()),
                nullToEmpty(stock.getSector()),
                profile != null ? nullToEmpty(profile.getWebsite()) : "",
                profile != null ? nullToEmpty(profile.getDescription()) : "",
                profile != null ? nullToEmpty(profile.getMapQuery()) : defaultMapQuery(stock),
                profile != null ? nullToEmpty(profile.getTrendsKeyword()) : defaultTrendsKeyword(stock),
                profile != null
        );
    }

    private StockResponse ensureStockExists(String stockCode) {
        return stockService.getAllStocks().stream()
                .filter(s -> s.getCode().equalsIgnoreCase(stockCode))
                .findFirst()
                .orElseThrow(() -> new RuntimeException("stock not found"));
    }

    private void validateRequest(CompanyProfileRequest request) {
        if (request == null) {
            throw new RuntimeException("request is null");
        }
        if (request.getStockCode() == null || request.getStockCode().trim().isEmpty()) {
            throw new RuntimeException("stockCode is required");
        }
    }

    private void validateRequestForUpdate(CompanyProfileRequest request) {
        if (request == null) {
            throw new RuntimeException("request is null");
        }
    }

    private String normalizeStockCode(String stockCode) {
        return stockCode == null ? "" : stockCode.trim().toUpperCase();
    }

    private String buildMapQuery(String stockCode, CompanyProfileRequest request) {
        String mapQuery = trim(request.getMapQuery());
        if (!mapQuery.isEmpty()) {
            return mapQuery;
        }

        String companyName = stockService.findNameByCode(stockCode);
        return companyName.isBlank() ? stockCode : companyName + " 本社";
    }

    private String buildTrendsKeyword(String stockCode, CompanyProfileRequest request) {
        String trendsKeyword = trim(request.getTrendsKeyword());
        if (!trendsKeyword.isEmpty()) {
            return trendsKeyword;
        }

        String companyName = stockService.findNameByCode(stockCode);
        return companyName.isBlank() ? stockCode : companyName;
    }

    private String defaultMapQuery(StockResponse stock) {
        return stock.getName() == null || stock.getName().isBlank()
                ? stock.getCode()
                : stock.getName() + " 本社";
    }

    private String defaultTrendsKeyword(StockResponse stock) {
        return stock.getName() == null || stock.getName().isBlank()
                ? stock.getCode()
                : stock.getName();
    }

    private String trim(String value) {
        return value == null ? "" : value.trim();
    }

    private String nullToEmpty(String value) {
        return value == null ? "" : value;
    }
}