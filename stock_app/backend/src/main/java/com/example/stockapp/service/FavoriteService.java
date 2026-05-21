package com.example.stockapp.service;

import com.example.stockapp.dto.FavoriteRequest;
import com.example.stockapp.dto.FavoriteResponse;
import com.example.stockapp.dto.StockResponse;
import com.example.stockapp.entity.Favorite;
import com.example.stockapp.repository.FavoriteRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class FavoriteService {

    private final FavoriteRepository favoriteRepository;
    private final StockService stockService;

    @Transactional(readOnly = true)
    public List<FavoriteResponse> getFavorites(Integer userId) {
        List<Favorite> favorites = favoriteRepository.findByUserIdOrderByIdAsc(userId);
        List<StockResponse> allStocks = stockService.getAllStocks();

        return favorites.stream()
                .map(favorite -> {
                    StockResponse stock = allStocks.stream()
                            .filter(s -> s.getCode().equalsIgnoreCase(favorite.getStockCode()))
                            .findFirst()
                            .orElse(null);

                    return new FavoriteResponse(
                            favorite.getId(),
                            favorite.getUserId(),
                            favorite.getStockCode(),
                            stock != null ? stock.getName() : "",
                            stock != null ? stock.getMarket() : "",
                            stock != null ? stock.getSector() : ""
                    );
                })
                .toList();
    }

    @Transactional
    public FavoriteResponse addFavorite(FavoriteRequest request) {
        validateRequest(request);

        String stockCode = normalizeStockCode(request.getStockCode());

        if (favoriteRepository.existsByUserIdAndStockCode(request.getUserId(), stockCode)) {
            throw new RuntimeException("favorite already exists");
        }

        StockResponse stock = stockService.getAllStocks().stream()
                .filter(s -> s.getCode().equalsIgnoreCase(stockCode))
                .findFirst()
                .orElseThrow(() -> new RuntimeException("stock not found"));

        Favorite favorite = new Favorite();
        favorite.setUserId(request.getUserId());
        favorite.setStockCode(stockCode);

        Favorite saved = favoriteRepository.save(favorite);

        return new FavoriteResponse(
                saved.getId(),
                saved.getUserId(),
                saved.getStockCode(),
                stock.getName(),
                stock.getMarket(),
                stock.getSector()
        );
    }

    @Transactional
    public void deleteFavorite(Integer userId, String stockCode) {
        String normalizedStockCode = normalizeStockCode(stockCode);

        Favorite favorite = favoriteRepository.findByUserIdAndStockCode(userId, normalizedStockCode)
                .orElseThrow(() -> new RuntimeException("favorite not found"));

        favoriteRepository.delete(favorite);
    }

    private void validateRequest(FavoriteRequest request) {
        if (request == null) {
            throw new RuntimeException("request is null");
        }
        if (request.getUserId() == null) {
            throw new RuntimeException("userId is required");
        }
        if (request.getStockCode() == null || request.getStockCode().trim().isEmpty()) {
            throw new RuntimeException("stockCode is required");
        }
    }

    private String normalizeStockCode(String stockCode) {
        return stockCode == null ? "" : stockCode.trim().toUpperCase();
    }
}