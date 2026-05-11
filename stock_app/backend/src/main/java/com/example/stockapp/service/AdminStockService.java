package com.example.stockapp.service;

import com.example.stockapp.dto.admin.AdminStockRequest;
import com.example.stockapp.dto.admin.AdminStockResponse;
import com.example.stockapp.entity.Stock;
import com.example.stockapp.repository.CompanyProfileRepository;
import com.example.stockapp.repository.FavoriteRepository;
import com.example.stockapp.repository.StockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AdminStockService {

    private final StockRepository stockRepository;
    private final FavoriteRepository favoriteRepository;
    private final CompanyProfileRepository companyProfileRepository;

    @Transactional(readOnly = true)
    public List<AdminStockResponse> getStocks() {
        return stockRepository.findAll()
                .stream()
                .sorted(Comparator.comparing(Stock::getCode))
                .map(AdminStockResponse::from)
                .toList();
    }

    @Transactional
    public AdminStockResponse create(AdminStockRequest request) {
        String code = normalizeCode(request.getCode());

        validateStock(code, request.getName(), request.getMarket(), request.getSector());

        if (stockRepository.existsById(code)) {
            throw new IllegalArgumentException("この銘柄コードは既に登録されています。");
        }

        Stock stock = new Stock();
        stock.setCode(code);
        stock.setName(request.getName().trim());
        stock.setMarket(request.getMarket().trim());
        stock.setSector(request.getSector().trim());

        return AdminStockResponse.from(stockRepository.save(stock));
    }

    @Transactional
    public AdminStockResponse update(String code, AdminStockRequest request) {
        String normalizedCode = normalizeCode(code);

        Stock stock = stockRepository.findById(normalizedCode)
                .orElseThrow(() -> new IllegalArgumentException("銘柄が存在しません。"));

        validateStock(normalizedCode, request.getName(), request.getMarket(), request.getSector());

        stock.setName(request.getName().trim());
        stock.setMarket(request.getMarket().trim());
        stock.setSector(request.getSector().trim());

        return AdminStockResponse.from(stockRepository.save(stock));
    }

    @Transactional
    public void delete(String code) {
        String normalizedCode = normalizeCode(code);

        if (!stockRepository.existsById(normalizedCode)) {
            throw new IllegalArgumentException("銘柄が存在しません。");
        }

        favoriteRepository.deleteByStockCode(normalizedCode);
        companyProfileRepository.deleteByStockCode(normalizedCode);
        stockRepository.deleteById(normalizedCode);
    }

    private String normalizeCode(String code) {
        if (code == null) {
            return "";
        }

        String value = code.trim();

        if (value.matches("^[0-9]{5}$") && value.endsWith("0")) {
            return value.substring(0, 4);
        }

        return value;
    }

    private void validateStock(
            String code,
            String name,
            String market,
            String sector
    ) {
        if (code == null || !code.matches("^[0-9]{4}$")) {
            throw new IllegalArgumentException("銘柄コードは4桁の数字で入力してください。");
        }

        if (name == null || name.trim().isEmpty()) {
            throw new IllegalArgumentException("銘柄名は必須です。");
        }

        if (market == null || market.trim().isEmpty()) {
            throw new IllegalArgumentException("市場は必須です。");
        }

        if (sector == null || sector.trim().isEmpty()) {
            throw new IllegalArgumentException("業種は必須です。");
        }
    }
}