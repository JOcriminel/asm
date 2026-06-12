package com.asm.dux.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Slf4j
@Service
public class DuxDetailsDocService {

    private final RestTemplate restTemplate;
    private final DuxTokenService tokenService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${dux.details-doc-url}")
    private String detailsDocUrl;

    public DuxDetailsDocService(RestTemplate restTemplate, DuxTokenService tokenService) {
        this.restTemplate = restTemplate;
        this.tokenService = tokenService;
    }

    public String getDetailsDoc(String from, String to, String idTier, String repres, 
                                String codeDoc, String idEtat, String all, 
                                String allDocuments, String idArticle, String AffichAvanc, 
                                String stationId, String requestBody) {
        
        String token = tokenService.getAccessToken();

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(token);
        headers.add("token", token);
        headers.setContentType(MediaType.APPLICATION_JSON);

        if (requestBody == null || requestBody.trim().isEmpty()) {
            requestBody = "{\"idDocCommercial\":[],\"idTierModal\":null,\"event\":{\"first\":0,\"rows\":20,\"sortOrder\":1,\"filters\":{},\"globalFilter\":null}}";
        }

        HttpEntity<String> requestEntity = new HttpEntity<>(requestBody, headers);

        // Build the dynamic URL with all variables
        String fullUrl = detailsDocUrl + from + "/" + to + "/" + idTier + "/" + repres + "/" 
                         + codeDoc + "/" + idEtat + "/" + all + "/" + allDocuments + "/" 
                         + idArticle + "/" + AffichAvanc;

        ResponseEntity<String> response = restTemplate.exchange(
                fullUrl,
                HttpMethod.POST,
                requestEntity,
                String.class);

        String responseBody = response.getBody();
        
        if (responseBody == null || responseBody.trim().isEmpty()) {
            return responseBody;
        }

        try {
            JsonNode rootNode = objectMapper.readTree(responseBody);
            
            // Find the array to filter
            JsonNode dataNode = null;
            if (rootNode.isArray()) {
                dataNode = rootNode;
            } else if (rootNode.isObject()) {
                if (rootNode.has("data") && rootNode.get("data").isArray()) {
                    dataNode = rootNode.get("data");
                } else if (rootNode.has("content") && rootNode.get("content").isArray()) {
                    dataNode = rootNode.get("content");
                } else if (rootNode.has("results") && rootNode.get("results").isArray()) {
                    dataNode = rootNode.get("results");
                } else if (rootNode.has("documents") && rootNode.get("documents").isArray()) {
                    dataNode = rootNode.get("documents");
                }
            }
            
            if (dataNode != null && dataNode.isArray()) {
                ArrayNode filteredArray = objectMapper.createArrayNode();
                
                for (JsonNode item : dataNode) {
                    // Check stationId filtering
                    boolean keep = true;
                    if (stationId != null && !stationId.trim().isEmpty() && !"Default Station".equals(stationId)) {
                        String idStation = item.has("idStation") && !item.get("idStation").isNull() ? item.get("idStation").asText() : "";
                        String libelleStation = item.has("libelleStation") && !item.get("libelleStation").isNull() ? item.get("libelleStation").asText() : "";
                        String altStationName = item.has("stationName") && !item.get("stationName").isNull() ? item.get("stationName").asText() : "";
                        
                        keep = idStation.equals(stationId) || libelleStation.equals(stationId) || altStationName.equals(stationId);
                    }
                    
                    if (keep) {
                        // Project to basic information
                        ObjectNode basicInfo = objectMapper.createObjectNode();
                        
                        // ID
                        if (item.has("id")) basicInfo.set("id", item.get("id"));
                        else if (item.has("idDoc")) basicInfo.set("idDoc", item.get("idDoc"));
                        
                        // Code / Ref
                        if (item.has("code")) basicInfo.set("code", item.get("code"));
                        else if (item.has("documentCode")) basicInfo.set("documentCode", item.get("documentCode"));
                        else if (item.has("codeDoc")) basicInfo.set("codeDoc", item.get("codeDoc"));
                        else if (item.has("numDoc")) basicInfo.set("numDoc", item.get("numDoc"));
                        
                        // Date
                        if (item.has("dateDocument")) basicInfo.set("dateDocument", item.get("dateDocument"));
                        else if (item.has("dateCreation")) basicInfo.set("dateCreation", item.get("dateCreation"));
                        
                        // Title / Subject
                        if (item.has("libelleClasseDocument")) basicInfo.set("libelleClasseDocument", item.get("libelleClasseDocument"));
                        else if (item.has("documentType")) basicInfo.set("documentType", item.get("documentType"));
                        else if (item.has("titreImprimable")) basicInfo.set("titreImprimable", item.get("titreImprimable"));
                        
                        // Status
                        if (item.has("libelleEtatDoc")) basicInfo.set("libelleEtatDoc", item.get("libelleEtatDoc"));
                        if (item.has("couleurEtatDoc")) basicInfo.set("couleurEtatDoc", item.get("couleurEtatDoc"));
                        
                        // Station
                        if (item.has("idStation")) basicInfo.set("idStation", item.get("idStation"));
                        if (item.has("libelleStation")) basicInfo.set("libelleStation", item.get("libelleStation"));
                        
                        // Other fields required by frontend DTO
                        if (item.has("nomPrenomTier")) basicInfo.set("nomPrenomTier", item.get("nomPrenomTier"));
                        if (item.has("mntNetht")) basicInfo.set("mntNetht", item.get("mntNetht"));
                        if (item.has("mntTtc")) basicInfo.set("mntTtc", item.get("mntTtc"));
                        if (item.has("idTier")) basicInfo.set("idTier", item.get("idTier"));
                        if (item.has("nomPrenomRep")) basicInfo.set("nomPrenomRep", item.get("nomPrenomRep"));
                        if (item.has("symbole")) basicInfo.set("symbole", item.get("symbole"));
                        if (item.has("codeDev")) basicInfo.set("codeDev", item.get("codeDev"));
                        if (item.has("isVente")) basicInfo.set("isVente", item.get("isVente"));
                        
                        filteredArray.add(basicInfo);
                    }
                }
                
                // Replace the array in the root node
                if (rootNode.isArray()) {
                    return objectMapper.writeValueAsString(filteredArray);
                } else {
                    ObjectNode objNode = (ObjectNode) rootNode;
                    if (objNode.has("data")) objNode.set("data", filteredArray);
                    else if (objNode.has("content")) objNode.set("content", filteredArray);
                    else if (objNode.has("results")) objNode.set("results", filteredArray);
                    else if (objNode.has("documents")) objNode.set("documents", filteredArray);
                    
                    return objectMapper.writeValueAsString(objNode);
                }
            }
        } catch (Exception e) {
            log.error("Failed to parse or filter JSON: {}", e.getMessage());
        }

        return responseBody;
    }
}
