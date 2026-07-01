package com.asm.dux.timetree.service;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import javax.annotation.PostConstruct;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;

@Slf4j
@Service
public class FcmService {

    private boolean initialized = false;

    @PostConstruct
    public void initialize() {
        try {
            File serviceAccountFile = new File("config/service-account.json");
            if (!serviceAccountFile.exists()) {
                log.warn("Firebase credentials file config/service-account.json not found. FCM will run in MOCK mode.");
                return;
            }

            FileInputStream serviceAccount = new FileInputStream(serviceAccountFile);
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
                log.info("Firebase Application has been initialized successfully.");
            }
            initialized = true;
        } catch (IOException e) {
            log.error("Failed to initialize Firebase Admin SDK", e);
        }
    }

    public void sendPushNotification(String token, String title, String body, java.util.Map<String, String> data) {
        if (!initialized) {
            log.info("[MOCK FCM PUSH] Token: {}, Title: '{}', Body: '{}', Data: {}", token, title, body, data);
            return;
        }

        Message message = Message.builder()
                .setToken(token)
                .setNotification(Notification.builder().setTitle(title).setBody(body).build())
                .setAndroidConfig(AndroidConfig.builder()
                        .setNotification(AndroidNotification.builder()
                                .setSound("default")
                                .setVibrateTimingsInMillis(new long[]{0, 500, 250, 500})
                                .build())
                        .build())
                .setApnsConfig(ApnsConfig.builder()
                        .setAps(Aps.builder()
                                .setSound("default")
                                .build())
                        .build())
                .putAllData(data)
                .build();
        try {
            String response = FirebaseMessaging.getInstance().send(message);
            log.info("Successfully sent FCM message: {}", response);
        } catch (FirebaseMessagingException e) {
            log.error("FCM Send failed for token: {}", token, e);
        }
    }
}
