package com.example.stockapp.service;

import com.example.stockapp.dto.FavoriteCreateRequest;
import com.example.stockapp.dto.FavoriteResponse;
import com.example.stockapp.entity.Favorite;
import com.example.stockapp.entity.Stock;
import com.example.stockapp.repository.FavoriteRepository;
import com.example.stockapp.repository.StockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class FavoriteService {

    private final FavoriteRepository favoriteRepository;
    private final StockRepository stockRepository;

    public List<FavoriteResponse> getFavorites(Long userId) {
        return favoriteRepository.findByUserIdOrderByIdAsc(userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public FavoriteResponse addFavorite(FavoriteCreateRequest request) {
        if (request.getUserId() == null) {
            throw new IllegalArgumentException("userId is required");
        }
        if (request.getStockCode() == null || request.getStockCode().isBlank()) {
            throw new IllegalArgumentException("stockCode is required");
        }

        String stockCode = request.getStockCode().trim();

        if (favoriteRepository.existsByUserIdAndStock_Code(request.getUserId(), stockCode)) {
            throw new IllegalArgumentException("favorite already exists");
        }

        Stock stock = stockRepository.findById(stockCode)
                .orElseThrow(() -> new IllegalArgumentException("stock not found"));

        Favorite favorite = new Favorite();
        favorite.setUserId(request.getUserId());
        favorite.setStock(stock);

        Favorite saved = favoriteRepository.save(favorite);
        return toResponse(saved);
    }

    @Transactional
    public void deleteFavorite(Long userId, String stockCode) {
        Favorite favorite = favoriteRepository.findByUserIdAndStock_Code(userId, stockCode)
                .orElseThrow(() -> new IllegalArgumentException("favorite not found"));

        favoriteRepository.delete(favorite);
    }

    private FavoriteResponse toResponse(Favorite favorite) {
        return new FavoriteResponse(
                favorite.getId(),
                favorite.getUserId(),
                favorite.getStock().getCode(),
                favorite.getStock().getName(),
                favorite.getStock().getMarket(),
                favorite.getStock().getSector(),
                favorite.getCreatedAt().toString()
        );
    }
}