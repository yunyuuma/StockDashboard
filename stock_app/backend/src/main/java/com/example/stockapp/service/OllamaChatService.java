package com.example.stockapp.service;

import com.example.stockapp.dto.ai.AiChatResponse;
import com.example.stockapp.dto.trading.PortfolioSummaryResponse;
import com.example.stockapp.entity.Stock;
import com.example.stockapp.repository.StockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class OllamaChatService {

    private final PortfolioService portfolioService;
    private final StockRepository stockRepository;
    private final StockPriceService stockPriceService;

    private final RestTemplate restTemplate = new RestTemplate();

    private static final String OLLAMA_URL = "http://localhost:11434/api/generate";
    private static final String MODEL_NAME = "qwen2.5:1.5b";

    @Transactional(readOnly = true)
    public AiChatResponse chat(Long userId, String message) {
        return chat(userId, message, null);
    }

    @Transactional(readOnly = true)
    public AiChatResponse chat(Long userId, String message, String stockCode) {
        if (message == null || message.isBlank()) {
            throw new IllegalArgumentException("メッセージを入力してください。");
        }

        PortfolioSummaryResponse portfolio = portfolioService.getPortfolio(userId);
        String stockContext = buildStockContext(stockCode);
        String prompt = buildPrompt(message, portfolio, stockContext);

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", MODEL_NAME);
        body.put("prompt", prompt);
        body.put("stream", false);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);

        try {
            ResponseEntity<Map> response = restTemplate.exchange(
                    OLLAMA_URL,
                    HttpMethod.POST,
                    entity,
                    Map.class
            );

            Map<?, ?> responseBody = response.getBody();

            if (responseBody == null || responseBody.get("response") == null) {
                return new AiChatResponse("AIから回答を取得できませんでした。");
            }

            String answer = responseBody.get("response").toString().trim();

            if (answer.isBlank()) {
                return new AiChatResponse("AIから空の回答が返されました。");
            }

            return new AiChatResponse(answer);

        } catch (Exception e) {
            return new AiChatResponse(
                    "AI接続に失敗しました。Ollamaが起動しているか確認してください。"
            );
        }
    }

    private String buildStockContext(String stockCode) {
        if (stockCode == null || stockCode.isBlank()) {
            return "銘柄指定なし";
        }

        String code = normalizeCode(stockCode);

        Stock stock = stockRepository.findById(code).orElse(null);

        if (stock == null) {
            return """
                    銘柄コード: %s
                    銘柄情報: DBに登録されていません。
                    """.formatted(code);
        }

        BigDecimal currentPrice = stockPriceService.getCurrentPrice(code);

        String priceText = currentPrice == null || currentPrice.compareTo(BigDecimal.ZERO) <= 0
                ? "取得不可"
                : currentPrice.toPlainString() + " 円";

        return """
                銘柄コード: %s
                銘柄名: %s
                市場: %s
                業種: %s
                現在価格: %s
                """.formatted(
                stock.getCode(),
                safe(stock.getName()),
                safe(stock.getMarket()),
                safe(stock.getSector()),
                priceText
        );
    }

    private String buildPrompt(
            String userMessage,
            PortfolioSummaryResponse portfolio,
            String stockContext
    ) {
        return """
                あなたは株価アプリ内のAI相談アシスタントです。
                投資助言ではなく、疑似売買学習用の分析補助として回答してください。
                断定的に「買うべき」「売るべき」とは言わず、確認ポイント・リスク・考え方を日本語で簡潔に説明してください。

                【現在表示中の銘柄情報】
                %s

                【ユーザーのポートフォリオ情報】
                総資産: %s 円
                現金: %s 円
                保有評価額: %s 円
                総損益: %s 円
                総損益率: %s %%
                日次損益: %s 円
                最大DD: %s 円
                最大DD率: %s %%

                【ユーザーの質問】
                %s

                【回答ルール】
                ・日本語で回答
                ・初心者にも分かりやすく
                ・投資判断を断定しない
                ・箇条書きを使って読みやすく
                ・最後に「※これは投資助言ではなく学習用コメントです。」を付ける
                """.formatted(
                stockContext,
                portfolio.getTotalAsset(),
                portfolio.getCash(),
                portfolio.getStockValue(),
                portfolio.getProfitLoss(),
                portfolio.getProfitLossRate(),
                portfolio.getDailyProfitLoss(),
                portfolio.getMaxDrawdown(),
                portfolio.getMaxDrawdownRate(),
                userMessage
        );
    }

    private String normalizeCode(String code) {
        if (code == null) {
            return "";
        }

        String value = code.trim().toUpperCase();

        if (value.length() == 5 && value.endsWith("0")) {
            return value.substring(0, 4);
        }

        return value;
    }

    private String safe(String value) {
        return value == null ? "" : value;
    }
}