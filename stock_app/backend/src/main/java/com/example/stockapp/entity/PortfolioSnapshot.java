package com.example.stockapp.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "portfolio_snapshots")
@Getter
@Setter
public class PortfolioSnapshot {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long userId;

    private LocalDateTime snapshotAt;

    @Column(precision = 15, scale = 2)
    private BigDecimal cash;

    @Column(precision = 15, scale = 2)
    private BigDecimal stockValue;

    @Column(precision = 15, scale = 2)
    private BigDecimal totalAsset;

    @Column(length = 100)
    private String eventLabel;

    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal marketValue = BigDecimal.ZERO;
}