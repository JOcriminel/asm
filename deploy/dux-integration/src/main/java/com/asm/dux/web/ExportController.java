package com.asm.dux.web;

import com.asm.dux.timetree.domain.*;
import com.asm.dux.timetree.repository.EventRepository;
import com.asm.dux.timetree.service.TimetreeSecurityService;
import com.lowagie.text.*;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.ByteArrayOutputStream;
import java.io.StringWriter;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequestMapping({"/api/timetree/export", "/api/dux/api/timetree/export"})
@RequiredArgsConstructor
public class ExportController {

    private final EventRepository eventRepository;
    private final TimetreeSecurityService securityService;

    @GetMapping("/{format}")
    public ResponseEntity<?> exportEvents(
            @PathVariable String format,
            @RequestParam(required = false) List<Long> calendarIds,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime start,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime end) {

        log.info("GET /api/timetree/export/{} calendarIds={}, start={}, end={}", format, calendarIds, start, end);

        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        // Get allowed calendars
        List<Long> allowedCalendarIds = securityService.getAllowedCalendarIds(current);
        List<Long> queryIds = new ArrayList<>();
        if (calendarIds != null && !calendarIds.isEmpty()) {
            for (Long id : calendarIds) {
                if (allowedCalendarIds.contains(id)) {
                    queryIds.add(id);
                }
            }
        } else {
            queryIds.addAll(allowedCalendarIds);
        }

        if (queryIds.isEmpty()) {
            return ResponseEntity.ok("Aucune donnée à exporter.");
        }

        // Retrieve active events in the selected range or default range
        LocalDateTime rangeStart = start != null ? start : LocalDateTime.now().minusYears(1);
        LocalDateTime rangeEnd = end != null ? end : LocalDateTime.now().plusYears(1);

        List<Event> events = eventRepository.findActiveEventsInCalendars(queryIds, rangeStart, rangeEnd).stream()
                .filter(e -> !Boolean.TRUE.equals(e.getDeleted()))
                .filter(e -> securityService.canReadEvent(current, e))
                .sorted(Comparator.comparing(Event::getStartDate))
                .collect(Collectors.toList());

        try {
            switch (format.toLowerCase()) {
                case "csv":
                    return exportToCsv(events);
                case "ics":
                    return exportToIcs(events);
                case "excel":
                case "xlsx":
                    return exportToExcel(events);
                case "pdf":
                    return exportToPdf(events);
                default:
                    return ResponseEntity.badRequest().body("Format non supporté: " + format);
            }
        } catch (Exception e) {
            log.error("Export failed", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Erreur lors de l'export: " + e.getMessage());
        }
    }

    private ResponseEntity<?> exportToCsv(List<Event> events) {
        StringWriter sw = new StringWriter();
        sw.write("ID,Titre,Description,Date Debut,Date Fin,Toute la journee,Calendrier,Groupe,Statut,Priorite,Cree par\n");

        for (Event e : events) {
            sw.write(String.format("%d,%s,%s,%s,%s,%b,%s,%s,%s,%s,%s\n",
                    e.getId(),
                    escapeCsv(e.getTitle()),
                    escapeCsv(e.getDescription()),
                    e.getStartDate().toString(),
                    e.getEndDate().toString(),
                    e.getAllDay(),
                    escapeCsv(e.getCalendar().getName()),
                    e.getGroup() != null ? escapeCsv(e.getGroup().getName()) : "",
                    e.getStatus().name(),
                    e.getPriority().name(),
                    escapeCsv(e.getCreatedBy())
            ));
        }

        byte[] bytes = sw.toString().getBytes();
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.parseMediaType("text/csv"));
        headers.setContentDispositionFormData("attachment", "events.csv");
        headers.setContentLength(bytes.length);

        return new ResponseEntity<>(bytes, headers, HttpStatus.OK);
    }

    private ResponseEntity<?> exportToIcs(List<Event> events) {
        StringBuilder sb = new StringBuilder();
        sb.append("BEGIN:VCALENDAR\r\n");
        sb.append("VERSION:2.0\r\n");
        sb.append("PRODID:-//TimeTree//NONSGML Calendar Export//EN\r\n");
        sb.append("CALSCALE:GREGORIAN\r\n");

        DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyyMMdd'T'HHmmss");
        DateTimeFormatter dateOnlyFmt = DateTimeFormatter.ofPattern("yyyyMMdd");

        for (Event e : events) {
            sb.append("BEGIN:VEVENT\r\n");
            sb.append("UID:event-").append(e.getId()).append("@timetree.com\r\n");
            sb.append("SUMMARY:").append(escapeIcs(e.getTitle())).append("\r\n");
            if (e.getDescription() != null && !e.getDescription().isEmpty()) {
                sb.append("DESCRIPTION:").append(escapeIcs(e.getDescription())).append("\r\n");
            }
            if (Boolean.TRUE.equals(e.getAllDay())) {
                sb.append("DTSTART;VALUE=DATE:").append(e.getStartDate().format(dateOnlyFmt)).append("\r\n");
                sb.append("DTEND;VALUE=DATE:").append(e.getEndDate().format(dateOnlyFmt)).append("\r\n");
            } else {
                sb.append("DTSTART:").append(e.getStartDate().format(dtf)).append("\r\n");
                sb.append("DTEND:").append(e.getEndDate().format(dtf)).append("\r\n");
            }
            sb.append("PRIORITY:").append(e.getPriority() == EventPriority.CRITICAL ? "1" : e.getPriority() == EventPriority.HIGH ? "3" : "5").append("\r\n");
            sb.append("STATUS:").append(e.getStatus() == EventStatus.CANCELLED ? "CANCELLED" : e.getStatus() == EventStatus.COMPLETED ? "CONFIRMED" : "TENTATIVE").append("\r\n");
            sb.append("END:VEVENT\r\n");
        }
        sb.append("END:VCALENDAR\r\n");

        byte[] bytes = sb.toString().getBytes();
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.parseMediaType("text/calendar"));
        headers.setContentDispositionFormData("attachment", "events.ics");
        headers.setContentLength(bytes.length);

        return new ResponseEntity<>(bytes, headers, HttpStatus.OK);
    }

    private ResponseEntity<?> exportToExcel(List<Event> events) throws Exception {
        try (Workbook workbook = new XSSFWorkbook()) {
            Sheet sheet = workbook.createSheet("Evenements");

            // Header Style
            CellStyle headerStyle = workbook.createCellStyle();
            org.apache.poi.ss.usermodel.Font font = workbook.createFont();
            font.setBold(true);
            headerStyle.setFont(font);
            headerStyle.setFillForegroundColor(IndexedColors.GREY_25_PERCENT.getIndex());
            headerStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);

            // Create headers
            org.apache.poi.ss.usermodel.Row headerRow = sheet.createRow(0);
            String[] headers = {"ID", "Titre", "Description", "Date Debut", "Date Fin", "Toute la journee", "Calendrier", "Groupe", "Statut", "Priorite", "Cree par"};
            for (int i = 0; i < headers.length; i++) {
                org.apache.poi.ss.usermodel.Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
                cell.setCellStyle(headerStyle);
            }

            int rowIdx = 1;
            for (Event e : events) {
                org.apache.poi.ss.usermodel.Row row = sheet.createRow(rowIdx++);
                row.createCell(0).setCellValue(e.getId());
                row.createCell(1).setCellValue(e.getTitle());
                row.createCell(2).setCellValue(e.getDescription() != null ? e.getDescription() : "");
                row.createCell(3).setCellValue(e.getStartDate().toString());
                row.createCell(4).setCellValue(e.getEndDate().toString());
                row.createCell(5).setCellValue(e.getAllDay());
                row.createCell(6).setCellValue(e.getCalendar().getName());
                row.createCell(7).setCellValue(e.getGroup() != null ? e.getGroup().getName() : "");
                row.createCell(8).setCellValue(e.getStatus().name());
                row.createCell(9).setCellValue(e.getPriority().name());
                row.createCell(10).setCellValue(e.getCreatedBy() != null ? e.getCreatedBy() : "");
            }

            // Auto-size columns
            for (int i = 0; i < headers.length; i++) {
                sheet.autoSizeColumn(i);
            }

            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            workbook.write(bos);

            byte[] bytes = bos.toByteArray();
            HttpHeaders httpHeaders = new HttpHeaders();
            httpHeaders.setContentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"));
            httpHeaders.setContentDispositionFormData("attachment", "events.xlsx");
            httpHeaders.setContentLength(bytes.length);

            return new ResponseEntity<>(bytes, httpHeaders, HttpStatus.OK);
        }
    }

    private ResponseEntity<?> exportToPdf(List<Event> events) throws Exception {
        Document document = new Document(PageSize.A4.rotate());
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        PdfWriter.getInstance(document, bos);

        document.open();

        // Add title
        com.lowagie.text.Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18);
        Paragraph title = new Paragraph("TimeTree - Liste des Événements", titleFont);
        title.setAlignment(Element.ALIGN_CENTER);
        title.setSpacingAfter(20);
        document.add(title);

        // Create table
        PdfPTable table = new PdfPTable(7);
        table.setWidthPercentage(100);
        table.setWidths(new float[]{1.5f, 2.5f, 2.5f, 1.5f, 1.5f, 1.0f, 1.0f});

        com.lowagie.text.Font headerFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10);
        String[] headers = {"Titre", "Date Debut", "Date Fin", "Calendrier", "Groupe", "Statut", "Priorite"};

        for (String header : headers) {
            PdfPCell cell = new PdfPCell(new Paragraph(header, headerFont));
            cell.setBackgroundColor(java.awt.Color.LIGHT_GRAY);
            cell.setHorizontalAlignment(Element.ALIGN_CENTER);
            cell.setPadding(6);
            table.addCell(cell);
        }

        com.lowagie.text.Font rowFont = FontFactory.getFont(FontFactory.HELVETICA, 9);
        for (Event e : events) {
            table.addCell(new PdfPCell(new Paragraph(e.getTitle(), rowFont)));
            table.addCell(new PdfPCell(new Paragraph(e.getStartDate().toString(), rowFont)));
            table.addCell(new PdfPCell(new Paragraph(e.getEndDate().toString(), rowFont)));
            table.addCell(new PdfPCell(new Paragraph(e.getCalendar().getName(), rowFont)));
            table.addCell(new PdfPCell(new Paragraph(e.getGroup() != null ? e.getGroup().getName() : "", rowFont)));
            table.addCell(new PdfPCell(new Paragraph(e.getStatus().name(), rowFont)));
            table.addCell(new PdfPCell(new Paragraph(e.getPriority().name(), rowFont)));
        }

        document.add(table);
        document.close();

        byte[] bytes = bos.toByteArray();
        HttpHeaders httpHeaders = new HttpHeaders();
        httpHeaders.setContentType(MediaType.APPLICATION_PDF);
        httpHeaders.setContentDispositionFormData("attachment", "events.pdf");
        httpHeaders.setContentLength(bytes.length);

        return new ResponseEntity<>(bytes, httpHeaders, HttpStatus.OK);
    }

    private String escapeCsv(String value) {
        if (value == null) return "";
        if (value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r")) {
            return "\"" + value.replace("\"", "\"\"") + "\"";
        }
        return value;
    }

    private String escapeIcs(String value) {
        if (value == null) return "";
        return value.replace("\\", "\\\\")
                .replace(";", "\\;")
                .replace(",", "\\,")
                .replace("\n", "\\n")
                .replace("\r", "");
    }
}
