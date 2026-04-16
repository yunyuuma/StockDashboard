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
public class JQuantsMasterResponse {

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

        @JsonAlias({"CoName", "coName", "CompanyName", "companyName"})
        private String companyName;

        @JsonAlias({"MktNm", "mktNm", "MarketCodeName", "marketCodeName"})
        private String marketCodeName;

        @JsonAlias({"S33Nm", "s33Nm", "Sector33CodeName", "sector33CodeName"})
        private String sector33CodeName;
    }
}