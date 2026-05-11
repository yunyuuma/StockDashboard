package com.example.stockapp.repository;

import com.example.stockapp.entity.Trade;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TradeRepository extends JpaRepository<Trade, Long> {
    List<Trade> findByUserIdOrderByTradedAtDesc(Long userId);
    Optional<Trade> findTopByUserIdAndStockCodeOrderByTradedAtDesc(Long userId, String stockCode);
}