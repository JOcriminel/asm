package com.asm.dux.timetree.service;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.DistributionSummary;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Service;

@Service
public class AttachmentMetricsService {

    private final MeterRegistry registry;
    private final DistributionSummary uploadSizeSummary;

    public AttachmentMetricsService(MeterRegistry registry) {
        this.registry = registry;
        this.uploadSizeSummary = DistributionSummary.builder("timetree.attachments.upload.bytes")
                .description("Distribution of uploaded file sizes in bytes")
                .baseUnit("bytes")
                .register(registry);
    }

    public void recordUploadAttempt(String outcome, String mimeType) {
        Counter.builder("timetree.attachments.upload.attempts")
                .description("Total attachment upload attempts")
                .tag("outcome", outcome)
                .tag("mime_type", mimeType != null ? mimeType : "unknown")
                .register(registry)
                .increment();
    }

    public void recordUploadSize(long bytes) {
        uploadSizeSummary.record(bytes);
    }

    public void recordDownloadAttempt(String outcome) {
        Counter.builder("timetree.attachments.download.attempts")
                .description("Total attachment download attempts")
                .tag("outcome", outcome)
                .register(registry)
                .increment();
    }

    public void recordDeleteAttempt(String outcome) {
        Counter.builder("timetree.attachments.delete.total")
                .description("Total attachment delete attempts")
                .tag("outcome", outcome)
                .register(registry)
                .increment();
    }
}
