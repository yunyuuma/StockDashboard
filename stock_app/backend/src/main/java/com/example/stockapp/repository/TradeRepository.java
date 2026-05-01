package com.example.stockapp.repository;

import com.example.stockapp.entity.Trade;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TradeRepository extends JpaRepository<Trade, Long> {
    List<Trade> findByUserIdOrderByTradedAtDesc(Long userId);
}