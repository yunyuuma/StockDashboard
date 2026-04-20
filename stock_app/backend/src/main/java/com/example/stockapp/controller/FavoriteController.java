package com.example.stockapp.controller;

import com.example.stockapp.dto.FavoriteRequest;
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
    public List<FavoriteResponse> getFavorites(@RequestParam Integer userId) {
        return favoriteService.getFavorites(userId);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public FavoriteResponse addFavorite(@RequestBody FavoriteRequest request) {
        return favoriteService.addFavorite(request);
    }

    @DeleteMapping("/{stockCode}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteFavorite(
            @RequestParam Integer userId,
            @PathVariable String stockCode
    ) {
        favoriteService.deleteFavorite(userId, stockCode);
    }
}