package com.example.stockapp.service;

import com.example.stockapp.entity.Favorite;
import com.example.stockapp.repository.FavoriteRepository;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
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

    @Test
    void 重複お気に入り登録チェック() {

        when(favoriteRepository.existsByUserIdAndStockCode(1, "7203"))
                .thenReturn(true);

        boolean exists =
                favoriteRepository.existsByUserIdAndStockCode(1, "7203");

        assertTrue(exists);
    }

    @Test
    void お気に入り解除できること() {

        Favorite favorite = new Favorite();
        favorite.setId(1);
        favorite.setUserId(1);
        favorite.setStockCode("7203");

        when(favoriteRepository.findByUserIdAndStockCode(1, "7203"))
                .thenReturn(Optional.of(favorite));

        favoriteRepository.delete(favorite);

        verify(favoriteRepository, times(1))
                .delete(favorite);
    }

    @Test
    void 存在しないお気に入り解除でも落ちない() {

        when(favoriteRepository.findByUserIdAndStockCode(1, "9999"))
                .thenReturn(Optional.empty());

        Optional<Favorite> result =
                favoriteRepository.findByUserIdAndStockCode(1, "9999");

        assertTrue(result.isEmpty());
    }
}