package com.example.stockapp.repository;

import com.example.stockapp.entity.Favorite;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FavoriteRepository extends JpaRepository<Favorite, Long> {
    List<Favorite> findByUserIdOrderByIdAsc(Long userId);

    Optional<Favorite> findByUserIdAndStock_Code(Long userId, String stockCode);

    boolean existsByUserIdAndStock_Code(Long userId, String stockCode);
}