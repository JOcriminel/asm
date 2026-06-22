package com.asm.dux;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class DuxIntegrationApplicationTests {

	@org.springframework.beans.factory.annotation.Autowired
	private com.asm.dux.infrastructure.dux.DuxHttpClient client;

	@Test
	void contextLoads() {
	}

	@Test
	void testFindAll() {
		try {
			String res = client.get("https://duxweb.pre-produx.asmtechtn.com/api/classeDoc/findAll/");
			com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
			com.fasterxml.jackson.databind.JsonNode root = mapper.readTree(res);
			System.out.println("--- ALL CODES ---");
			for (com.fasterxml.jackson.databind.JsonNode node : root) {
				String code = node.path("code").asText();
				String libelle = node.path("libelle").asText();
				boolean isReservation = node.path("isReservation").asBoolean();
				boolean isPreparation = node.path("isPreparation").asBoolean();
				System.out.println("Code: " + code + " | Libelle: " + libelle + " | isRes: " + isReservation + " | isPrep: " + isPreparation);
			}
			System.out.println("-----------------");
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
}
