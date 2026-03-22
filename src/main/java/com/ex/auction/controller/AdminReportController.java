package com.ex.auction.controller;

import com.ex.auction.service.AdminReportService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.List;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class AdminReportController {

    private final AdminReportService reportService;

    /**
     * GET /api/admin/metadata - Get all entity schemas for report builder
     */
    @GetMapping("/metadata")
    public ResponseEntity<Map<String, Object>> getMetadata() {
        return ResponseEntity.ok(reportService.getMetadata());
    }

    /**
     * GET /api/admin/dashboard - Get overview stats
     */
    @GetMapping("/dashboard")
    public ResponseEntity<Map<String, Object>> getDashboard() {
        return ResponseEntity.ok(reportService.getDashboardStats());
    }

    /**
     * GET /api/admin/report - Execute dynamic report
     * Params: entity, fields (comma-separated), filter_xxx=value, sort, dir, page, size
     */
    @GetMapping("/report")
    public ResponseEntity<Map<String, Object>> getReport(
            @RequestParam String entity,
            @RequestParam(required = false) String fields,
            @RequestParam(required = false, defaultValue = "") String sort,
            @RequestParam(required = false, defaultValue = "DESC") String dir,
            @RequestParam(required = false, defaultValue = "0") int page,
            @RequestParam(required = false, defaultValue = "20") int size,
            @RequestParam Map<String, String> allParams) {

        List<String> fieldList = (fields != null && !fields.isEmpty())
                ? Arrays.asList(fields.split(","))
                : null;

        // Extract filters (params starting with "filter_")
        Map<String, String> filters = new LinkedHashMap<>();
        allParams.forEach((key, value) -> {
            if (key.startsWith("filter_") && !value.isEmpty()) {
                filters.put(key.substring(7), value);
            }
        });

        log.info("Report: entity={}, fields={}, filters={}, sort={}, page={}", entity, fieldList, filters, sort, page);

        Map<String, Object> result = reportService.executeReport(entity, fieldList, filters, sort, dir, page, size);
        return ResponseEntity.ok(result);
    }

    /**
     * GET /api/admin/rankings - List available ranking reports
     */
    @GetMapping("/rankings")
    public ResponseEntity<List<Map<String, Object>>> getRankings() {
        return ResponseEntity.ok(reportService.getRankingList());
    }

    /**
     * GET /api/admin/ranking/{key} - Execute a specific ranking report
     */
    @GetMapping("/ranking/{key}")
    public ResponseEntity<Map<String, Object>> getRanking(
            @PathVariable String key,
            @RequestParam(required = false, defaultValue = "10") int limit) {
        return ResponseEntity.ok(reportService.executeRanking(key, limit));
    }
}
