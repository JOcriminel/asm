# Sprint 10 Hardening & Observability Evidence and Deployment Guide

This document presents the reproducible evidence for the Sprint 10 deliverables, including test logs, load test metrics, Prometheus documentation, and deployment guides for Redis and RabbitMQ dependencies.

---

## 1. Commit Reference
- **Final Sign-off Commit**: `4b9e74d7d6a116d751f9b3bc289784c5cafd5b18`
- **Commit Message**: `perf(timetree): optimize WebSocket security authorization and connection pools to support non-mocked database load test within sub-second latencies`

To check out this commit:
```bash
git checkout 4b9e74d7d6a116d751f9b3bc289784c5cafd5b18
```

---

## 2. Maven Test Execution Results (`mvn test`)
Running the test suite on a clean machine executes all unit and integration tests including Redis and RabbitMQ Testcontainers tests.

### Execution Command
From the `dux-integration` directory:
```powershell
.\mvnw test
```

### Execution Output Summary
```text
[INFO] Scanning for projects...
...
[INFO] Running com.asm.dux.timetree.TimetreeWebSocketTests
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
[INFO] Running com.asm.dux.timetree.TimetreePresenceTests
[INFO] Tests run: 5, Failures: 0, Errors: 0, Skipped: 0
[INFO] Running com.asm.dux.timetree.TimetreeOfflineQueueTests
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0
[INFO] Running com.asm.dux.timetree.TimetreeBrokerRelayTests
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0
[INFO] Running com.asm.dux.timetree.TimetreeSecurityTests
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0
[INFO] Running com.asm.dux.timetree.TimetreeControllerTests
[INFO] Tests run: 7, Failures: 0, Errors: 0, Skipped: 0
[INFO] Running com.asm.dux.timetree.TimetreeLoadTests
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
[INFO] Running com.asm.dux.DuxIntegrationApplicationTests
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 2 (Skipped Keycloak external auth tests)
...
[INFO] Results:
[INFO] 
[INFO] Tests run: 32, Failures: 0, Errors: 0, Skipped: 2
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  02:14 min
```

---

## 3. Redis and RabbitMQ Testcontainers Integration Tests
Integration tests spin up Docker containers automatically via Testcontainers. The test definitions can be inspected at:
- **WebSocket / Broker Relay**: [TimetreeBrokerRelayTests.java](file:///c:/pfa/deploy/dux-integration/src/test/java/com/asm/dux/timetree/TimetreeBrokerRelayTests.java)
- **Offline Queuing**: [TimetreeOfflineQueueTests.java](file:///c:/pfa/deploy/dux-integration/src/test/java/com/asm/dux/timetree/TimetreeOfflineQueueTests.java)
- **Presence Tracking**: [TimetreePresenceTests.java](file:///c:/pfa/deploy/dux-integration/src/test/java/com/asm/dux/timetree/TimetreePresenceTests.java)

These tests execute over random, dynamically mapped ports to prevent port conflicts in CI/CD pipelines.

---

## 4. Load-Test Reports and Latency Metrics
A concurrency load test was run with 20 parallel STOMP connections executing 200 message sends under a real database and security interceptor configuration (without mocking repository layers or security filters).

### Test Configuration
- **Concurrent client sessions**: 20
- **Messages sent per session**: 10
- **Total expected ACKs**: 200

### Latency Performance Summary
```text
===================================================
    LOAD TEST RESULTS (REAL DB & SECURITY LAYER)
===================================================
    Concurrent sessions : 20
    Messages per session: 10
    Total expected ACKs : 200
    ACKs received       : 200
    Avg latency         : 193 ms
    P50 latency         : 83 ms
    P95 latency         : 779 ms      (Target: < 1000 ms - PASS)
    P99 latency         : 980 ms      (Target: < 1500 ms - PASS)
    Max latency         : 994 ms
===================================================
```

---

## 5. Prometheus Metrics Exposure and Documentation
WebSocket and real-time chat metrics are collected using Micrometer and exposed through Spring Boot Actuator.

### Exposed Endpoint
- **URL**: `http://localhost:9090/actuator/prometheus`

### Custom WebSocket Metrics Documented
1. **Active WebSocket Sessions** (`timetree_ws_sessions_active`): Gauge representing the number of active STOMP sessions currently connected.
2. **Connected Unique Users** (`timetree_ws_users_connected`): Gauge tracking unique usernames currently logged in and active.
3. **Sent Messages Count** (`timetree_ws_messages_sent_total`): Counter with tags `destination`, `messageType`, and `result` tracking sent messages.
4. **Message Routing Latency** (`timetree_ws_latency_ms`): Summary metric exposing quantiles (`0.5`, `0.95`, `0.99`) for end-to-end WebSocket message delivery latency.

---

## 6. Dependency Deployment & Configuration Guide

### Redis Configuration
Presence tracking, duplicate detection, and offline queue storage require a Redis instance.
- **Development / Tests**: Handled automatically via Testcontainers if Docker is running.
- **Production / Staging Setup**:
  1. Install Redis (version 7+ recommended).
  2. Configure connection details in `application.yml` (or override via environment variables):
     ```yaml
     spring:
       data:
         redis:
           host: ${REDIS_HOST:localhost}
           port: ${REDIS_PORT:6379}
           password: ${REDIS_PASSWORD:}
     ```
  3. Key structure format details:
     - `timetree:presence:{username}`: Stores `"ONLINE"` with a 30s TTL. Reset by 10s heartbeats.
     - `timetree:dup:{clientMessageId}`: Stores target event message ACK metadata. 24h expire TTL.
     - `timetree:offline:{username}`: List storing serialized offline payloads. 24h expire TTL.

### RabbitMQ Configuration
STOMP message relay routing uses RabbitMQ with the STOMP plugin enabled.
- **Staging / Production Installation**:
  1. Enable STOMP plugin: `rabbitmq-plugins enable rabbitmq_stomp`
  2. The STOMP relay port defaults to `61613`.
  3. Configure broker properties in `application.yml`:
     ```yaml
     spring:
       websocket:
         broker:
           type: relay # Change 'simple' to 'relay' for production
       rabbitmq:
         host: ${RABBITMQ_HOST:localhost}
         username: ${RABBITMQ_USERNAME:guest}
         password: ${RABBITMQ_PASSWORD:guest}
       timetree:
         websocket:
           relay:
             stomp-port: ${STOMP_PORT:61613}
     ```
