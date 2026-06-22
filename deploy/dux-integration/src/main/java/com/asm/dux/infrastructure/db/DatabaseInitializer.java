package com.asm.dux.infrastructure.db;

import com.asm.dux.domain.model.ScreenConfig;
import com.asm.dux.infrastructure.db.repository.ScreenConfigRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class DatabaseInitializer implements CommandLineRunner {

    private final ScreenConfigRepository screenConfigRepository;

    public DatabaseInitializer(ScreenConfigRepository screenConfigRepository) {
        this.screenConfigRepository = screenConfigRepository;
    }

    @Override
    public void run(String... args) throws Exception {
        log.info("Checking default screen configurations in database...");

        // BC
        initIfMissing("BC", "Bon de Commande", "#2196F3", false, true, false, "date", false, false, "BC-D", "Search code, customer or representative...");

        // BP
        initIfMissing("BP", "Bon de Préparation", "#4CAF50", true, false, true, "status", false, true, "BP-D", "Search code, customer or representative...");

        // BS
        initIfMissing("BS", "Bon de Sortie", "#FF9800", false, false, false, "date", true, false, "BS-D", "Rechercher code, client ou représentant...");

        // HOME / Accueil
        initIfMissing("HOME", "Accueil", "#2196F3", false, false, false, "date", false, false, "", "Search...");

        // KPI_DASHBOARD
        initIfMissing("KPI_DASHBOARD", "KPI Dashboard", "#009688", false, false, false, "date", false, false, "", "Search...");

        // CLIENTS
        initIfMissing("CLIENTS", "Clients", "#9C27B0", false, false, false, "date", false, false, "", "Search...");

        // ACTIVITY_FEED
        initIfMissing("ACTIVITY_FEED", "Journal d'Activité", "#607D8B", false, false, false, "date", false, false, "", "Search...");

        // STATION
        initIfMissing("STATION", "Station", "#FF5722", false, false, false, "date", false, false, "", "Search...");

        // PROFILE
        initIfMissing("PROFILE", "Profile", "#E91E63", false, false, false, "date", false, false, "", "Search...");

        // ADMIN_DASHBOARD
        initIfMissing("ADMIN_DASHBOARD", "Dashboard Admin", "#3F51B5", false, false, false, "date", false, false, "", "Search...");

        log.info("Screen configurations check completed.");
    }

    private void initIfMissing(String docType, String title, String primaryColor,
                               boolean enableBarcode, boolean enablePdf, boolean enableSerial,
                               String defaultSort, boolean requireSignature, boolean requirePhoto,
                               String detailPageTitle, String searchHint) {
        if (!screenConfigRepository.existsById(docType)) {
            log.info("Initializing missing screen config for: {}", docType);
            ScreenConfig config = new ScreenConfig();
            config.setDocumentType(docType);
            config.setPageTitle(title);
            config.setPrimaryColor(primaryColor);
            config.setEnableBarcodeScanner(enableBarcode);
            config.setEnablePdfPrinting(enablePdf);
            config.setEnableSerialNumberTracking(enableSerial);
            config.setVisibleRoles("admin,commercial,operateur");
            config.setDetailPageTitle(detailPageTitle);
            config.setHidePricesForOperateurs(false);
            config.setAllowedRolesToFinalize("admin,commercial,operateur,Administrateur,Commercial,Opérateur");
            config.setRequireSignature(requireSignature);
            config.setRequirePhoto(requirePhoto);
            config.setDefaultSortField(defaultSort);
            config.setSearchHint(searchHint);
            config.setActive(true);
            if ("BC".equals(docType) || "BP".equals(docType) || "BS".equals(docType)) {
                config.setStatusFilters("all:Tout,1:NT,2:PT,3:TT");
            } else {
                config.setStatusFilters("");
            }
            screenConfigRepository.save(config);
        }
    }
}
