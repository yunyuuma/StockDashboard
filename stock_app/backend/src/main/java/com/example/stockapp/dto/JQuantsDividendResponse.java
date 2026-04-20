package com.example.stockapp.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class JQuantsDividendResponse {

    @JsonProperty("pagination_key")
    private String paginationKey;

    @JsonProperty("data")
    private List<Item> data;

    @Getter
    @Setter
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Item {

        @JsonAlias({"Code", "code"})
        private String code;

        @JsonAlias({"PubDate", "pubDate"})
        private String pubDate;

        @JsonAlias({"DivRate", "divRate"})
        private String divRate;

        @JsonAlias({"FRCode", "frCode"})
        private String frCode;
    }
}