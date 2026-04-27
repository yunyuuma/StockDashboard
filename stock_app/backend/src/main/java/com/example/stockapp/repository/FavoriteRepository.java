package com.example.stockapp.repository;

import com.example.stockapp.entity.Favorite;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface FavoriteRepository extends JpaRepository<Favorite, Integer> {

    List<Favorite> findByUserIdOrderByIdAsc(Integer userId);

    boolean existsByUserIdAndStockCode(Integer userId, String stockCode);

    Optional<Favorite> findByUserIdAndStockCode(Integer userId, String stockCode);

    long countBy();

    void deleteByUserId(Integer userId);

    void deleteByStockCode(String stockCode);
}