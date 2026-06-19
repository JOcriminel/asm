package com.asm.dux.dto;

import java.util.List;

public class ScreenConfigDto {
    private String documentType;
    private String pageTitle;
    private String searchHint;
    private boolean enableBarcodeScanner;
    private boolean enablePdfPrinting;
    private boolean enableSerialNumberTracking;
    private List<String> visibleRoles;
    private String detailPageTitle;
    private boolean hidePricesForOperateurs;
    private List<String> allowedRolesToFinalize;
    private String primaryColor;
    private boolean requireSignature;
    private boolean requirePhoto;
    private String defaultSortField;
    private boolean enableSoundAlerts;
    private boolean enableVibrationAlerts;

    public ScreenConfigDto() {
    }

    public String getDocumentType() {
        return documentType;
    }

    public void setDocumentType(String documentType) {
        this.documentType = documentType;
    }

    public String getPageTitle() {
        return pageTitle;
    }

    public void setPageTitle(String pageTitle) {
        this.pageTitle = pageTitle;
    }

    public String getSearchHint() {
        return searchHint;
    }

    public void setSearchHint(String searchHint) {
        this.searchHint = searchHint;
    }

    public boolean isEnableBarcodeScanner() {
        return enableBarcodeScanner;
    }

    public void setEnableBarcodeScanner(boolean enableBarcodeScanner) {
        this.enableBarcodeScanner = enableBarcodeScanner;
    }

    public boolean isEnablePdfPrinting() {
        return enablePdfPrinting;
    }

    public void setEnablePdfPrinting(boolean enablePdfPrinting) {
        this.enablePdfPrinting = enablePdfPrinting;
    }

    public boolean isEnableSerialNumberTracking() {
        return enableSerialNumberTracking;
    }

    public void setEnableSerialNumberTracking(boolean enableSerialNumberTracking) {
        this.enableSerialNumberTracking = enableSerialNumberTracking;
    }

    public List<String> getVisibleRoles() {
        return visibleRoles;
    }

    public void setVisibleRoles(List<String> visibleRoles) {
        this.visibleRoles = visibleRoles;
    }

    public String getDetailPageTitle() {
        return detailPageTitle;
    }

    public void setDetailPageTitle(String detailPageTitle) {
        this.detailPageTitle = detailPageTitle;
    }

    public boolean isHidePricesForOperateurs() {
        return hidePricesForOperateurs;
    }

    public void setHidePricesForOperateurs(boolean hidePricesForOperateurs) {
        this.hidePricesForOperateurs = hidePricesForOperateurs;
    }

    public List<String> getAllowedRolesToFinalize() {
        return allowedRolesToFinalize;
    }

    public void setAllowedRolesToFinalize(List<String> allowedRolesToFinalize) {
        this.allowedRolesToFinalize = allowedRolesToFinalize;
    }

    public String getPrimaryColor() {
        return primaryColor;
    }

    public void setPrimaryColor(String primaryColor) {
        this.primaryColor = primaryColor;
    }

    public boolean isRequireSignature() {
        return requireSignature;
    }

    public void setRequireSignature(boolean requireSignature) {
        this.requireSignature = requireSignature;
    }

    public boolean isRequirePhoto() {
        return requirePhoto;
    }

    public void setRequirePhoto(boolean requirePhoto) {
        this.requirePhoto = requirePhoto;
    }

    public String getDefaultSortField() {
        return defaultSortField;
    }

    public void setDefaultSortField(String defaultSortField) {
        this.defaultSortField = defaultSortField;
    }

    public boolean isEnableSoundAlerts() {
        return enableSoundAlerts;
    }

    public void setEnableSoundAlerts(boolean enableSoundAlerts) {
        this.enableSoundAlerts = enableSoundAlerts;
    }

    public boolean isEnableVibrationAlerts() {
        return enableVibrationAlerts;
    }

    public void setEnableVibrationAlerts(boolean enableVibrationAlerts) {
        this.enableVibrationAlerts = enableVibrationAlerts;
    }
}
