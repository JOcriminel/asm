package com.asm.dux.timetree.config;

import com.asm.dux.timetree.security.WebSocketRateLimitingInterceptor;
import com.asm.dux.timetree.security.WebSocketSecurityInterceptor;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    private final WebSocketSecurityInterceptor securityInterceptor;
    private final WebSocketRateLimitingInterceptor rateLimitingInterceptor;

    @Value("${spring.websocket.broker.type:simple}")
    private String brokerType;

    @Value("${spring.rabbitmq.host:localhost}")
    private String rabbitHost;

    @Value("${spring.rabbitmq.username:guest}")
    private String rabbitUser;

    @Value("${spring.rabbitmq.password:guest}")
    private String rabbitPassword;

    @Value("${timetree.websocket.relay.stomp-port:61613}")
    private int stompRelayPort;

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.setApplicationDestinationPrefixes("/app");
        config.setUserDestinationPrefix("/user");

        if ("relay".equalsIgnoreCase(brokerType)) {
            // Full Broker Relay pointing to external message broker (RabbitMQ)
            config.enableStompBrokerRelay("/topic", "/queue")
                    .setRelayHost(rabbitHost)
                    .setRelayPort(stompRelayPort)
                    .setSystemLogin(rabbitUser)
                    .setSystemPasscode(rabbitPassword)
                    .setClientLogin(rabbitUser)
                    .setClientPasscode(rabbitPassword);
        } else {
            // In-memory Simple Message Broker for local development
            config.enableSimpleBroker("/topic", "/queue");
        }
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // Support both /ws and /ws-timetree endpoints with SockJS fallback and CORS permissioning
        registry.addEndpoint("/ws", "/ws-timetree")
                .setAllowedOriginPatterns("*")
                .withSockJS();
        
        registry.addEndpoint("/ws", "/ws-timetree")
                .setAllowedOriginPatterns("*"); // Plain WebSocket connection
    }

    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        // Register our security and rate limit interceptors
        registration.interceptors(securityInterceptor, rateLimitingInterceptor);
        registration.taskExecutor()
                .corePoolSize(32)
                .maxPoolSize(64)
                .keepAliveSeconds(60);
    }

    @Override
    public void configureClientOutboundChannel(ChannelRegistration registration) {
        registration.taskExecutor()
                .corePoolSize(32)
                .maxPoolSize(64)
                .keepAliveSeconds(60);
    }
}
