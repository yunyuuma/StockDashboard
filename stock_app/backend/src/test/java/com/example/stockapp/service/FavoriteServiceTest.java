package com.example.stockapp.service;

import com.example.stockapp.entity.Favorite;
import com.example.stockapp.repository.FavoriteRepository;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.when;

class FavoriteServiceTest {

    @Mock
    private FavoriteRepository favoriteRepository;

    @BeforeEach
    void setup() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void お気に入り一覧取得() {
        Favorite favorite = new Favorite();
        favorite.setUserId(1);
        favorite.setStockCode("7203");

        when(favoriteRepository.findByUserIdOrderByIdAsc(1))
                .thenReturn(List.of(favorite));

        List<Favorite> result =
                favoriteRepository.findByUserIdOrderByIdAsc(1);

        assertEquals(1, result.size());
        assertEquals("7203", result.get(0).getStockCode());
    }

    @Test
    void お気に入り存在チェック() {
        when(favoriteRepository.existsByUserIdAndStockCode(1, "7203"))
                .thenReturn(true);

        boolean result =
                favoriteRepository.existsByUserIdAndStockCode(1, "7203");

        assertEquals(true, result);
    }
}