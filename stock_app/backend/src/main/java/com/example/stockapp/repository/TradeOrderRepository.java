package com.example.stockapp.repository;

import com.example.stockapp.entity.TradeOrder;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TradeOrderRepository extends JpaRepository<TradeOrder, Long> {

    List<TradeOrder> findByUserIdOrderByOrderedAtDesc(Long userId);

    List<TradeOrder> findByUserIdAndStatusOrderByOrderedAtDesc(Long userId, String status);

    List<TradeOrder> findByStatusOrderByOrderedAtAsc(String status);

    List<TradeOrder> findByGroupIdAndStatus(String groupId, String status);

    List<TradeOrder> findByParentOrderIdAndStatus(Long parentOrderId, String status);
}