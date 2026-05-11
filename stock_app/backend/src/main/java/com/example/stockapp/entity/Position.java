package com.example.stockapp.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Entity
@Table(name = "positions")
@Getter
@Setter
public class Position {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "stock_code", nullable = false, length = 10)
    private String stockCode;

    @Column(name = "quantity", nullable = false)
    private Integer quantity = 0;

    @Column(name = "average_price", nullable = false, precision = 15, scale = 2)
    private BigDecimal averagePrice = BigDecimal.ZERO;
}