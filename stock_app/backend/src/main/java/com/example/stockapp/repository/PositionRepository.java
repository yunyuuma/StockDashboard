package com.example.stockapp.repository;

import com.example.stockapp.entity.Position;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PositionRepository extends JpaRepository<Position, Long> {
    List<Position> findByUserIdOrderByStockCodeAsc(Long userId);
    Optional<Position> findByUserIdAndStockCode(Long userId, String stockCode);
}