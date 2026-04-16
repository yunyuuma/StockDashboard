package com.example.stockapp.controller;

import com.example.stockapp.dto.FavoriteCreateRequest;
import com.example.stockapp.dto.FavoriteResponse;
import com.example.stockapp.service.FavoriteService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/favorites")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class FavoriteController {

    private final FavoriteService favoriteService;

    @GetMapping
    public List<FavoriteResponse> getFavorites(
            @RequestParam(defaultValue = "1") Long userId
    ) {
        return favoriteService.getFavorites(userId);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public FavoriteResponse addFavorite(@RequestBody FavoriteCreateRequest request) {
        return favoriteService.addFavorite(request);
    }

    @DeleteMapping("/{stockCode}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteFavorite(
            @PathVariable String stockCode,
            @RequestParam(defaultValue = "1") Long userId
    ) {
        favoriteService.deleteFavorite(userId, stockCode);
    }
}