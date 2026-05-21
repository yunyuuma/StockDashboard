package com.example.stockapp.service;

import com.example.stockapp.dto.ai.AiAdvisorResponse;
import com.example.stockapp.dto.trading.PortfolioSummaryResponse;
import com.example.stockapp.dto.trading.SectorAllocationResponse;
import com.example.stockapp.repository.TradeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AiAdvisorService {

    private final PortfolioService portfolioService;
    private final TradeRepository tradeRepository;

    @Transactional(readOnly = true)
    public AiAdvisorResponse analyze(Long userId) {
        PortfolioSummaryResponse portfolio = portfolioService.getPortfolio(userId);

        List<String> portfolioAdvice = new ArrayList<>();
        List<String> tradingAdvice = new ArrayList<>();
        List<String> warnings = new ArrayList<>();

        BigDecimal totalAsset = safe(portfolio.getTotalAsset());
        BigDecimal cash = safe(portfolio.getCash());
        BigDecimal stockValue = safe(portfolio.getStockValue());
        BigDecimal profitLoss = safe(portfolio.getProfitLoss());
        BigDecimal dailyProfitLoss = safe(portfolio.getDailyProfitLoss());
        BigDecimal maxDrawdownRate = safe(portfolio.getMaxDrawdownRate());

        BigDecimal cashRate = percent(cash, totalAsset);
        BigDecimal stockRate = percent(stockValue, totalAsset);

        if (profitLoss.compareTo(BigDecimal.ZERO) >= 0) {
            portfolioAdvice.add("総損益はプラスです。現在の運用成績は比較的良好です。");
        } else {
            portfolioAdvice.add("総損益はマイナスです。銘柄選定や売買タイミングの見直し余地があります。");
        }

        if (dailyProfitLoss.compareTo(BigDecimal.ZERO) >= 0) {
            portfolioAdvice.add("日次損益はプラスです。短期的には資産が増加しています。");
        } else {
            portfolioAdvice.add("日次損益はマイナスです。直近の値動きには注意が必要です。");
        }

        if (cashRate.compareTo(BigDecimal.valueOf(20)) < 0) {
            portfolioAdvice.add("現金比率が低めです。追加投資や急落時の買付余力が少ない状態です。");
            warnings.add("現金比率が低いため、リスク許容度を超えた投資になっていないか確認してください。");
        } else if (cashRate.compareTo(BigDecimal.valueOf(50)) > 0) {
            portfolioAdvice.add("現金比率が高めです。リスクは抑えられていますが、投資効率は低くなる可能性があります。");
        } else {
            portfolioAdvice.add("現金比率は比較的バランスが取れています。");
        }

        if (stockRate.compareTo(BigDecimal.valueOf(80)) > 0) {
            portfolioAdvice.add("株式比率が高く、相場変動の影響を受けやすい状態です。");
        }

        if (maxDrawdownRate.compareTo(BigDecimal.valueOf(10)) >= 0) {
            portfolioAdvice.add("最大ドローダウンが大きめです。損切りラインや分散投資を検討してください。");
            warnings.add("最大DDが10%以上です。資産変動リスクが高めです。");
        } else {
            portfolioAdvice.add("最大ドローダウンは比較的小さく、資産変動は抑えられています。");
        }

        List<SectorAllocationResponse> sectors = portfolio.getSectorAllocations();

        if (sectors != null && !sectors.isEmpty()) {
            SectorAllocationResponse top = sectors.get(0);

            if (safe(top.getRate()).compareTo(BigDecimal.valueOf(50)) >= 0) {
                portfolioAdvice.add(
                        top.getSector() + " の比率が高く、セクター集中リスクがあります。"
                );
                warnings.add("特定セクターへの偏りが大きいです。");
            } else {
                portfolioAdvice.add("セクター配分は極端な偏りが少ない状態です。");
            }
        } else {
            portfolioAdvice.add("保有銘柄がないため、セクター分析はできません。");
        }

        int tradeCount = tradeRepository.findByUserIdOrderByTradedAtDesc(userId).size();

        if (tradeCount == 0) {
            tradingAdvice.add("売買履歴がまだありません。まずは少額の疑似売買で履歴を作ると分析精度が上がります。");
        } else if (tradeCount < 5) {
            tradingAdvice.add("売買履歴が少なめです。もう少し取引データが増えると傾向分析しやすくなります。");
        } else {
            tradingAdvice.add("売買履歴が蓄積されています。今後は勝率・損切り頻度・利益確定タイミングの分析が可能です。");
        }

        warnings.add("このAI分析は投資助言ではなく、疑似売買データに基づく学習用コメントです。");

        String riskLevel = decideRiskLevel(cashRate, maxDrawdownRate, sectors);

        String summary = switch (riskLevel) {
            case "HIGH" -> "現在のポートフォリオはリスク高めです。現金比率・セクター集中・最大DDを確認してください。";
            case "MIDDLE" -> "現在のポートフォリオは標準的なリスク水準です。分散と損切りルールを意識すると安定します。";
            default -> "現在のポートフォリオは比較的安定しています。リスクを抑えた運用状態です。";
        };

        return new AiAdvisorResponse(
                riskLevel,
                summary,
                portfolioAdvice,
                tradingAdvice,
                warnings
        );
    }

    private String decideRiskLevel(
            BigDecimal cashRate,
            BigDecimal maxDrawdownRate,
            List<SectorAllocationResponse> sectors
    ) {
        boolean sectorRisk = false;

        if (sectors != null && !sectors.isEmpty()) {
            sectorRisk = safe(sectors.get(0).getRate()).compareTo(BigDecimal.valueOf(50)) >= 0;
        }

        if (cashRate.compareTo(BigDecimal.valueOf(15)) < 0
                || maxDrawdownRate.compareTo(BigDecimal.valueOf(10)) >= 0
                || sectorRisk) {
            return "HIGH";
        }

        if (cashRate.compareTo(BigDecimal.valueOf(30)) < 0
                || maxDrawdownRate.compareTo(BigDecimal.valueOf(5)) >= 0) {
            return "MIDDLE";
        }

        return "LOW";
    }

    private BigDecimal safe(BigDecimal value) {
        return value == null ? BigDecimal.ZERO : value;
    }

    private BigDecimal percent(BigDecimal numerator, BigDecimal denominator) {
        if (denominator == null || denominator.compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ZERO;
        }

        return numerator
                .multiply(BigDecimal.valueOf(100))
                .divide(denominator, 2, java.math.RoundingMode.HALF_UP);
    }
}