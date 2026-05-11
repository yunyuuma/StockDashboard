package com.example.stockapp.service;

import com.example.stockapp.dto.ai.AiStockAdvisorResponse;
import com.example.stockapp.entity.Position;
import com.example.stockapp.entity.Stock;
import com.example.stockapp.entity.Trade;
import com.example.stockapp.repository.PositionRepository;
import com.example.stockapp.repository.StockRepository;
import com.example.stockapp.repository.TradeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AiStockAdvisorService {

    private final StockRepository stockRepository;
    private final PositionRepository positionRepository;
    private final TradeRepository tradeRepository;
    private final StockPriceService stockPriceService;

    @Transactional(readOnly = true)
    public AiStockAdvisorResponse analyze(Long userId, String code) {
        String stockCode = normalizeCode(code);

        Stock stock = stockRepository.findById(stockCode)
                .orElseThrow(() -> new IllegalArgumentException("銘柄が存在しません。"));

        BigDecimal currentPrice = stockPriceService.getCurrentPrice(stockCode);

        Position position = positionRepository
                .findByUserIdAndStockCode(userId, stockCode)
                .orElse(null);

        List<Trade> trades = tradeRepository.findByUserIdOrderByTradedAtDesc(userId)
                .stream()
                .filter(t -> stockCode.equals(t.getStockCode()))
                .toList();

        List<String> analysis = new ArrayList<>();
        List<String> checkPoints = new ArrayList<>();
        List<String> warnings = new ArrayList<>();

        analysis.add(stock.getName() + " は " + stock.getMarket() + " 市場の " + stock.getSector() + " に属する銘柄です。");

        if (currentPrice != null && currentPrice.compareTo(BigDecimal.ZERO) > 0) {
            analysis.add("現在価格は " + currentPrice.toPlainString() + " 円です。現在値を基準に売買判断を行えます。");
        } else {
            analysis.add("現在価格が取得できていません。価格情報がない状態での売買判断には注意が必要です。");
            warnings.add("現在価格が取得できないため、分析精度が下がっています。");
        }

        if (position != null && position.getQuantity() > 0) {
            BigDecimal averagePrice = position.getAveragePrice();
            BigDecimal quantity = BigDecimal.valueOf(position.getQuantity());

            BigDecimal valuationPrice = currentPrice != null && currentPrice.compareTo(BigDecimal.ZERO) > 0
                    ? currentPrice
                    : averagePrice;

            BigDecimal valuationAmount = valuationPrice.multiply(quantity);
            BigDecimal costAmount = averagePrice.multiply(quantity);
            BigDecimal profitLoss = valuationAmount.subtract(costAmount);

            analysis.add("この銘柄を " + position.getQuantity() + " 株保有しています。");
            analysis.add("平均取得単価は " + averagePrice.toPlainString() + " 円です。");

            if (profitLoss.compareTo(BigDecimal.ZERO) >= 0) {
                analysis.add("現在は含み益の状態です。利益確定ラインを決めておくと判断しやすくなります。");
            } else {
                analysis.add("現在は含み損の状態です。損切りラインや保有継続理由を確認してください。");
                warnings.add("含み損が出ているため、追加購入よりもリスク確認を優先してください。");
            }
        } else {
            analysis.add("この銘柄は現在保有していません。新規購入候補として確認できます。");
        }

        if (trades.isEmpty()) {
            analysis.add("この銘柄の売買履歴はまだありません。");
        } else {
            analysis.add("この銘柄の売買履歴は " + trades.size() + " 件あります。過去の売買タイミングを振り返れます。");
        }

        if (stock.getSector() != null && stock.getSector().contains("情報")) {
            checkPoints.add("情報・通信系は成長期待がある一方、業績変動やバリュエーションに注意が必要です。");
        } else if (stock.getSector() != null && stock.getSector().contains("水産")) {
            checkPoints.add("水産・農林業は景気敏感度が比較的低い一方、原材料価格や為替の影響に注意が必要です。");
        } else if (stock.getSector() != null && stock.getSector().contains("医薬")) {
            checkPoints.add("医薬品系は研究開発・承認・特許などの材料で株価が動きやすいです。");
        } else {
            checkPoints.add("同じ業種の銘柄と比較して、株価水準や成長性を確認してください。");
        }

        checkPoints.add("買う前に、現在価格・直近ニュース・業績指標・チャートの方向性を確認してください。");
        checkPoints.add("売買する場合は、利確価格と損切価格を先に決めておくと判断が安定します。");

        warnings.add("この分析は投資助言ではなく、疑似売買学習用のコメントです。");
        warnings.add("実際の投資判断は自己責任で行ってください。");

        String riskLevel = decideRiskLevel(stock, position, currentPrice);

        String summary = switch (riskLevel) {
            case "HIGH" -> "この銘柄は注意度が高めです。価格取得状況・含み損・業種リスクを確認してください。";
            case "MIDDLE" -> "この銘柄は標準的な確認が必要です。売買前にニュースとチャートを確認してください。";
            default -> "この銘柄は比較的確認しやすい状態です。基本情報と売買ルールを確認してください。";
        };

        return new AiStockAdvisorResponse(
                stock.getCode(),
                stock.getName(),
                stock.getMarket(),
                stock.getSector(),
                riskLevel,
                summary,
                analysis,
                checkPoints,
                warnings
        );
    }

    private String decideRiskLevel(Stock stock, Position position, BigDecimal currentPrice) {
        if (currentPrice == null || currentPrice.compareTo(BigDecimal.ZERO) <= 0) {
            return "HIGH";
        }

        if (position != null && position.getQuantity() > 0) {
            BigDecimal averagePrice = position.getAveragePrice();

            if (averagePrice != null && averagePrice.compareTo(BigDecimal.ZERO) > 0) {
                BigDecimal diffRate = currentPrice.subtract(averagePrice)
                        .multiply(BigDecimal.valueOf(100))
                        .divide(averagePrice, 2, java.math.RoundingMode.HALF_UP);

                if (diffRate.compareTo(BigDecimal.valueOf(-10)) <= 0) {
                    return "HIGH";
                }

                if (diffRate.compareTo(BigDecimal.valueOf(-5)) <= 0) {
                    return "MIDDLE";
                }
            }
        }

        if (stock.getMarket() != null && stock.getMarket().contains("グロース")) {
            return "MIDDLE";
        }

        return "LOW";
    }

    private String normalizeCode(String code) {
        if (code == null) return "";

        String value = code.trim().toUpperCase();

        if (value.length() == 5 && value.endsWith("0")) {
            return value.substring(0, 4);
        }

        return value;
    }
}