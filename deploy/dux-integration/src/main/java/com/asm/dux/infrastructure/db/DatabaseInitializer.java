package com.asm.dux.infrastructure.db;

import com.asm.dux.domain.model.ScreenConfig;
import com.asm.dux.infrastructure.db.repository.ScreenConfigRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

@Slf4j
@Component
public class DatabaseInitializer implements CommandLineRunner {

    private final ScreenConfigRepository screenConfigRepository;

    public DatabaseInitializer(ScreenConfigRepository screenConfigRepository) {
        this.screenConfigRepository = screenConfigRepository;
    }

    @Override
    public void run(String... args) throws Exception {
        if (screenConfigRepository.count() == 0) {
            log.info("No screen configurations found in database. Initializing defaults on startup...");
            List<ScreenConfig> defaults = new ArrayList<>();

            // BC
            ScreenConfig bc = new ScreenConfig();
            bc.setDocumentType("BC");
            bc.setPageTitle("Bon de Commande");
            bc.setSearchHint("Search code, customer or representative...");
            bc.setEnableBarcodeScanner(false);
            bc.setEnablePdfPrinting(true);
            bc.setEnableSerialNumberTracking(false);
            bc.setVisibleRoles("admin,commercial,operateur");
            bc.setDetailPageTitle("BC-D");
            bc.setHidePricesForOperateurs(false);
            bc.setAllowedRolesToFinalize("admin,commercial,operateur,Administrateur,Commercial,Opérateur");
            bc.setPrimaryColor("#2196F3"); // Blue
            bc.setRequireSignature(false);
            bc.setRequirePhoto(false);
            bc.setDefaultSortField("date");
            defaults.add(bc);

            // BP
            ScreenConfig bp = new ScreenConfig();
            bp.setDocumentType("BP");
            bp.setPageTitle("Bon de Préparation");
            bp.setSearchHint("Search code, customer or representative...");
            bp.setEnableBarcodeScanner(true);
            bp.setEnablePdfPrinting(false);
            bp.setEnableSerialNumberTracking(true);
            bp.setVisibleRoles("admin,commercial,operateur");
            bp.setDetailPageTitle("BP-D");
            bp.setHidePricesForOperateurs(false);
            bp.setAllowedRolesToFinalize("admin,commercial,operateur,Administrateur,Commercial,Opérateur");
            bp.setPrimaryColor("#4CAF50"); // Green
            bp.setRequireSignature(false);
            bp.setRequirePhoto(true); // require photo proof by default
            bp.setDefaultSortField("status");
            defaults.add(bp);

            // BS
            ScreenConfig bs = new ScreenConfig();
            bs.setDocumentType("BS");
            bs.setPageTitle("Bon de Sortie");
            bs.setSearchHint("Rechercher code, client ou représentant...");
            bs.setEnableBarcodeScanner(false);
            bs.setEnablePdfPrinting(false);
            bs.setEnableSerialNumberTracking(false);
            bs.setVisibleRoles("admin,commercial,operateur");
            bs.setDetailPageTitle("BS-D");
            bs.setHidePricesForOperateurs(false);
            bs.setAllowedRolesToFinalize("admin,commercial,operateur,Administrateur,Commercial,Opérateur");
            bs.setPrimaryColor("#FF9800"); // Orange
            bs.setRequireSignature(true); // require signature on exit by default
            bs.setRequirePhoto(false);
            bs.setDefaultSortField("date");
            defaults.add(bs);

            screenConfigRepository.saveAll(defaults);
            log.info("Default screen configurations initialized successfully.");
        } else {
            log.info("Screen configurations already exist in database. Skipping initialization.");
        }
    }
}
