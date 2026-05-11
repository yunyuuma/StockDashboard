package com.example.stockapp.service;

import com.example.stockapp.dto.ai.AiTradingReviewResponse;
import com.example.stockapp.entity.Trade;
import com.example.stockapp.repository.TradeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AiTradingReviewService {

    private final TradeRepository tradeRepository;

    @Transactional(readOnly = true)
    public AiTradingReviewResponse review(Long userId) {
        List<Trade> trades = tradeRepository.findByUserIdOrderByTradedAtDesc(userId);

        List<String> goodPoints = new ArrayList<>();
        List<String> weakPoints = new ArrayList<>();
        List<String> suggestions = new ArrayList<>();
        List<String> warnings = new ArrayList<>();

        if (trades.isEmpty()) {
            return new AiTradingReviewResponse(
                    "売買履歴がまだありません。まずは疑似売買で取引履歴を作ると、AIレビューができます。",
                    0,
                    0,
                    0,
                    List.of("まだ大きな損失リスクは発生していません。"),
                    List.of("売買履歴がないため、売買傾向の分析はできません。"),
                    List.of("まずは少額の疑似売買で、買い・売りの履歴を作ってください。"),
                    List.of("この分析は投資助言ではなく、疑似売買学習用のコメントです。")
            );
        }

        long buyCount = trades.stream()
                .filter(t -> "BUY".equalsIgnoreCase(t.getSide()))
                .count();

        long sellCount = trades.stream()
                .filter(t -> "SELL".equalsIgnoreCase(t.getSide()))
                .count();

        BigDecimal totalBuyAmount = trades.stream()
                .filter(t -> "BUY".equalsIgnoreCase(t.getSide()))
                .map(t -> t.getPrice().multiply(BigDecimal.valueOf(t.getQuantity())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalSellAmount = trades.stream()
                .filter(t -> "SELL".equalsIgnoreCase(t.getSide()))
                .map(t -> t.getPrice().multiply(BigDecimal.valueOf(t.getQuantity())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        if (trades.size() >= 5) {
            goodPoints.add("売買履歴が蓄積されており、取引傾向を分析しやすい状態です。");
        } else {
            weakPoints.add("売買回数が少ないため、まだ傾向分析の精度は高くありません。");
            suggestions.add("もう少し売買履歴を増やすと、買い癖・売り癖を分析しやすくなります。");
        }

        if (buyCount > 0) {
            goodPoints.add("買い注文の履歴があります。銘柄選定の練習ができています。");
        }

        if (sellCount > 0) {
            goodPoints.add("売り注文の履歴があります。出口戦略の練習ができています。");
        }

        if (buyCount > sellCount * 2 && buyCount >= 3) {
            weakPoints.add("買い注文に偏っています。利益確定や損切りの売却判断も記録していくと良いです。");
            suggestions.add("購入前に、利確価格と損切価格を決めてから注文すると判断が安定します。");
        }

        if (sellCount == 0 && buyCount > 0) {
            weakPoints.add("売却履歴がありません。出口戦略が不足している可能性があります。");
            suggestions.add("保有後にいつ売るかを決めるルールを作ってください。");
        }

        if (totalSellAmount.compareTo(totalBuyAmount) >= 0 && sellCount > 0) {
            goodPoints.add("売却金額が買付金額を上回っており、利益確定ができている可能性があります。");
        }

        if (totalBuyAmount.compareTo(BigDecimal.ZERO) > 0
                && totalSellAmount.compareTo(totalBuyAmount) < 0
                && sellCount > 0) {
            weakPoints.add("売却金額が買付金額を下回っています。損切りや利確タイミングの見直し余地があります。");
        }

        suggestions.add("売買後に、なぜ買ったか・なぜ売ったかをメモすると改善しやすくなります。");
        suggestions.add("成行・指値・逆指値・IFD/OCO/IFDOCOを使い分けると、売買判断の練習になります。");
        suggestions.add("買う前に、利確ライン・損切ライン・保有期間を決めておくと判断が安定します。");

        warnings.add("このAIレビューは投資助言ではなく、疑似売買データに基づく学習用コメントです。");
        warnings.add("実際の投資判断は自己責任で行ってください。");

        String summary;
        if (weakPoints.isEmpty()) {
            summary = "売買バランスは比較的良好です。今後は利確・損切ルールを明確にするとさらに改善できます。";
        } else {
            summary = "売買履歴から見ると、改善できるポイントがあります。特に出口戦略を意識すると良いです。";
        }

        return new AiTradingReviewResponse(
                summary,
                trades.size(),
                buyCount,
                sellCount,
                goodPoints,
                weakPoints,
                suggestions,
                warnings
        );
    }
}