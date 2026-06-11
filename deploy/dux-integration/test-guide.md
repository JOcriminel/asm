# DuxWeb Integration Test Guide

This guide explains how to test the DuxWeb integration API endpoints on port **`9090`**.

---

## 1. Run the Spring Boot Server
Start the application server locally:

```powershell
.\mvnw spring-boot:run
```
Once started, the server will listen on port **`9090`**.

---

## 2. Retrieve a Token from Keycloak
Since all endpoints are protected, you must acquire a bearer token first. Execute the following `curl` command in your terminal/PowerShell:

```powershell
curl -X POST "https://duxweb.pre-produx.asmtechtn.com/auth/realms/DuxWeb/protocol/openid-connect/token" `
  -H "Content-Type: application/x-www-form-urlencoded" `
  -d "grant_type=client_credentials" `
  -d "client_id=asm-apis" `
  -d "client_secret=WIIWVngUsQgSTyXB50AXm1YyeVtaog7V"
```

This will return a JSON response. Copy the value of the `"access_token"` field.

---

## 3. Test the Endpoints

### A. Test the User Endpoint (Existing API)
Query user details (defaulting to the `admin` login):
```powershell
curl -X GET "http://localhost:9090/api/dux/user?login=admin" `
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>"
```

### B. Test the Station Endpoint (New Dynamic API)
Query station details by replacing `{id}` with a dynamic station ID (e.g., `S1`, `123`):
```powershell
curl -X GET "http://localhost:9090/api/dux/station/{id}" `
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>"
```

### C. Test the Document Endpoint (New Dynamic API)
Query document details by replacing `{id}` with a dynamic document ID:
```powershell
curl -X GET "http://localhost:9090/api/dux/document/{id}" `
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>"
```

### D. Test the DetailsDoc2 Endpoint (New Dynamic POST API)
Submit a POST request to retrieve document details with dynamic variables in the path (e.g. date range, ids, codes, etc.) and an optional JSON body:
```powershell
curl -X POST "http://localhost:9090/api/dux/detailsDoc2/2026-06-01/2026-06-30%2023:59:59/11/11249/BCC/all/false/false/null/false" `
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" `
  -H "Content-Type: application/json" `
  -d '{}'
```
