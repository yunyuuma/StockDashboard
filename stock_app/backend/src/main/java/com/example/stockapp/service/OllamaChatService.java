package com.example.stockapp.service;

import com.example.stockapp.dto.ai.AiChatResponse;
import com.example.stockapp.dto.trading.PortfolioSummaryResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.util.LinkedHashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class OllamaChatService {

    private final PortfolioService portfolioService;

    private final RestTemplate restTemplate = new RestTemplate();

    private static final String OLLAMA_URL = "http://localhost:11434/api/generate";

    // 軽量で動いたモデル名に合わせる
    private static final String MODEL_NAME = "qwen2.5:1.5b";

    @Transactional(readOnly = true)
    public AiChatResponse chat(Long userId, String message) {
        if (message == null || message.isBlank()) {
            throw new IllegalArgumentException("メッセージを入力してください。");
        }

        PortfolioSummaryResponse portfolio = portfolioService.getPortfolio(userId);

        String prompt = buildPrompt(message, portfolio);

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

            String answer = responseBody.get("response").toString();

            return new AiChatResponse(answer.trim());

        } catch (Exception e) {
            return new AiChatResponse(
                    "AI接続に失敗しました。Ollamaが起動しているか確認してください。"
            );
        }
    }

    private String buildPrompt(String userMessage, PortfolioSummaryResponse portfolio) {
        return """
                あなたは株価アプリ内のAI相談アシスタントです。
                投資助言ではなく、疑似売買学習用の分析補助として回答してください。
                断定的に「買うべき」「売るべき」とは言わず、確認ポイント・リスク・考え方を日本語で簡潔に説明してください。

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
                ・最後に「※これは投資助言ではなく学習用コメントです。」を付ける
                """.formatted(
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
}