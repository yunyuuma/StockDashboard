package com.example.stockapp.service;

import com.example.stockapp.dto.ai.AiPortfolioAdvisorResponse;
import com.example.stockapp.entity.Position;
import com.example.stockapp.entity.Stock;
import com.example.stockapp.repository.PositionRepository;
import com.example.stockapp.repository.StockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.*;

@Service
@RequiredArgsConstructor
public class AiPortfolioAdvisorService {

    private final PositionRepository positionRepository;
    private final StockRepository stockRepository;
    private final StockPriceService stockPriceService;

    public AiPortfolioAdvisorResponse analyze(Long userId) {
        List<Position> positions =
                positionRepository.findByUserIdOrderByStockCodeAsc(userId);

        List<String> strengths = new ArrayList<>();
        List<String> risks = new ArrayList<>();
        List<String> suggestions = new ArrayList<>();

        if (positions.isEmpty()) {
            return new AiPortfolioAdvisorResponse(
                    "LOW",
                    "現在はポジションがありません。",
                    List.of("現金管理ができています。"),
                    List.of(),
                    List.of("最初は1〜3銘柄程度から疑似売買を試してください。")
            );
        }

        Map<String, Integer> sectorCount = new HashMap<>();
        BigDecimal totalValue = BigDecimal.ZERO;

        for (Position p : positions) {
            BigDecimal currentPrice = stockPriceService.getCurrentPrice(p.getStockCode());

            if (currentPrice == null || currentPrice.compareTo(BigDecimal.ZERO) <= 0) {
                currentPrice = p.getAveragePrice();
            }

            BigDecimal value = currentPrice.multiply(BigDecimal.valueOf(p.getQuantity()));
            totalValue = totalValue.add(value);

            Stock stock = stockRepository.findById(p.getStockCode()).orElse(null);

            String sector = "未設定";
            if (stock != null && stock.getSector() != null && !stock.getSector().isBlank()) {
                sector = stock.getSector();
            }

            sectorCount.put(sector, sectorCount.getOrDefault(sector, 0) + 1);
        }

        if (positions.size() >= 5) {
            strengths.add("複数銘柄に分散されています。");
        } else {
            risks.add("保有銘柄数が少なく、集中投資傾向があります。");
            suggestions.add("3〜5銘柄程度に分散すると、個別銘柄リスクを下げやすくなります。");
        }

        if (sectorCount.size() <= 1) {
            risks.add("同一セクターへの偏りがあります。");
            suggestions.add("異なる業種へ分散すると、セクター集中リスクを軽減できます。");
        } else {
            strengths.add("セクター分散ができています。");
        }

        if (totalValue.compareTo(BigDecimal.valueOf(300000)) >= 0) {
            strengths.add("一定以上の投資規模があり、ポートフォリオ分析がしやすい状態です。");
        }

        suggestions.add("利確ラインと損切りラインを事前に決めておくと判断が安定します。");
        suggestions.add("ニュース・決算・出来高の変化も確認してください。");

        String riskLevel;
        if (positions.size() <= 2 || sectorCount.size() <= 1) {
            riskLevel = "HIGH";
        } else if (positions.size() <= 4) {
            riskLevel = "MIDDLE";
        } else {
            riskLevel = "LOW";
        }

        String summary;
        switch (riskLevel) {
            case "HIGH" ->
                    summary = "集中投資傾向があります。銘柄数やセクター分散を見直すと安定しやすくなります。";
            case "MIDDLE" ->
                    summary = "標準的なポートフォリオです。さらに分散や損切りルールを整えると安定します。";
            default ->
                    summary = "比較的安定した分散構成です。今後は利益確定やリバランスの基準を決めると良いです。";
        }

        return new AiPortfolioAdvisorResponse(
                riskLevel,
                summary,
                strengths,
                risks,
                suggestions
        );
    }
}