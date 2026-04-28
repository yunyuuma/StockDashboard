package com.example.stockapp.service;

import com.example.stockapp.dto.CompanyProfileAdminResponse;
import com.example.stockapp.dto.CompanyProfileRequest;
import com.example.stockapp.entity.CompanyProfile;
import com.example.stockapp.entity.Stock;
import com.example.stockapp.repository.CompanyProfileRepository;
import com.example.stockapp.repository.StockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AdminCompanyProfileService {

    private final CompanyProfileRepository companyProfileRepository;
    private final StockRepository stockRepository;

    @Transactional(readOnly = true)
    public List<CompanyProfileAdminResponse> getAll() {
        return stockRepository.findAll()
                .stream()
                .sorted(Comparator.comparing(Stock::getCode))
                .map(stock -> {
                    CompanyProfile profile = companyProfileRepository
                            .findByStockCode(stock.getCode())
                            .orElse(null);

                    return CompanyProfileAdminResponse.from(stock, profile);
                })
                .toList();
    }

    @Transactional(readOnly = true)
    public CompanyProfileAdminResponse getByStockCode(String stockCode) {
        Stock stock = stockRepository.findById(stockCode)
                .orElseThrow(() -> new IllegalArgumentException("銘柄が存在しません。"));

        CompanyProfile profile = companyProfileRepository
                .findByStockCode(stockCode)
                .orElse(null);

        return CompanyProfileAdminResponse.from(stock, profile);
    }

    @Transactional
    public CompanyProfileAdminResponse create(CompanyProfileRequest request) {
        String stockCode = request.getStockCode().trim();

        Stock stock = stockRepository.findById(stockCode)
                .orElseThrow(() -> new IllegalArgumentException("銘柄が存在しません。"));

        if (companyProfileRepository.existsByStockCode(stockCode)) {
            throw new IllegalArgumentException("この銘柄コードの企業情報は既に登録されています。");
        }

        CompanyProfile profile = new CompanyProfile();
        profile.setStockCode(stockCode);
        profile.setWebsite(request.getWebsite());
        profile.setDescription(request.getDescription());
        profile.setMapQuery(request.getMapQuery());
        profile.setTrendsKeyword(request.getTrendsKeyword());

        CompanyProfile saved = companyProfileRepository.save(profile);

        return CompanyProfileAdminResponse.from(stock, saved);
    }

    @Transactional
    public CompanyProfileAdminResponse update(String stockCode, CompanyProfileRequest request) {
        Stock stock = stockRepository.findById(stockCode)
                .orElseThrow(() -> new IllegalArgumentException("銘柄が存在しません。"));

        CompanyProfile profile = companyProfileRepository
                .findByStockCode(stockCode)
                .orElseGet(() -> {
                    CompanyProfile p = new CompanyProfile();
                    p.setStockCode(stockCode);
                    return p;
                });

        profile.setWebsite(request.getWebsite());
        profile.setDescription(request.getDescription());
        profile.setMapQuery(request.getMapQuery());
        profile.setTrendsKeyword(request.getTrendsKeyword());

        CompanyProfile saved = companyProfileRepository.save(profile);

        return CompanyProfileAdminResponse.from(stock, saved);
    }
}