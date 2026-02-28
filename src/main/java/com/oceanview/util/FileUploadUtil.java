package com.oceanview.util;

import com.oceanview.config.AppConfig;
import jakarta.servlet.http.Part;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Arrays;
import java.util.UUID;

/**
 * File Upload Utility
 * Handles file upload operations
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class FileUploadUtil {
    
    private static final Logger logger = LoggerFactory.getLogger(FileUploadUtil.class);
    private static final AppConfig config = AppConfig.getInstance();
    
    // Private constructor to prevent instantiation
    private FileUploadUtil() {
        throw new IllegalStateException("Utility class");
    }
    
    /**
     * Save uploaded file
     * @param part File part from multipart request
     * @param uploadDirectory Upload directory path
     * @return Saved file name or null if failed
     */
    public static String saveFile(Part part, String uploadDirectory) {
        if (part == null) {
            logger.warn("File part is null");
            return null;
        }
        
        try {
            // Get original filename
            String originalFilename = getFileName(part);
            
            if (originalFilename == null || originalFilename.isEmpty()) {
                logger.warn("Original filename is empty");
                return null;
            }
            
            // Validate file size
            if (!isValidFileSize(part.getSize())) {
                logger.warn("File size exceeds maximum limit: {} bytes", part.getSize());
                return null;
            }
            
            // Validate file extension
            if (!isValidFileExtension(originalFilename)) {
                logger.warn("Invalid file extension: {}", getFileExtension(originalFilename));
                return null;
            }
            
            // Generate unique filename
            String newFilename = generateUniqueFilename(originalFilename);
            
            // Create upload directory if not exists
            File uploadDir = new File(uploadDirectory);
            if (!uploadDir.exists()) {
                uploadDir.mkdirs();
            }
            
            // Save file
            Path filePath = Paths.get(uploadDirectory, newFilename);
            try (InputStream input = part.getInputStream()) {
                Files.copy(input, filePath, StandardCopyOption.REPLACE_EXISTING);
            }
            
            logger.info("File uploaded successfully: {}", newFilename);
            return newFilename;
            
        } catch (IOException e) {
            logger.error("Error saving file", e);
            return null;
        }
    }
    
    /**
     * Get filename from Part
     * @param part File part
     * @return Filename
     */
    public static String getFileName(Part part) {
        String contentDisposition = part.getHeader("content-disposition");
        if (contentDisposition == null) {
            return null;
        }
        
        for (String content : contentDisposition.split(";")) {
            if (content.trim().startsWith("filename")) {
                return content.substring(content.indexOf("=") + 1)
                             .trim()
                             .replace("\"", "");
            }
        }
        return null;
    }
    
    /**
     * Generate unique filename
     * @param originalFilename Original filename
     * @return Unique filename
     */
    public static String generateUniqueFilename(String originalFilename) {
        String extension = getFileExtension(originalFilename);
        String uuid = UUID.randomUUID().toString();
        return uuid + (extension.isEmpty() ? "" : "." + extension);
    }
    
    /**
     * Get file extension
     * @param filename Filename
     * @return Extension (without dot)
     */
    public static String getFileExtension(String filename) {
        if (filename == null || filename.isEmpty()) {
            return "";
        }
        
        int lastDot = filename.lastIndexOf('.');
        if (lastDot == -1 || lastDot == filename.length() - 1) {
            return "";
        }
        
        return filename.substring(lastDot + 1).toLowerCase();
    }
    
    /**
     * Validate file size
     * @param fileSize File size in bytes
     * @return true if valid
     */
    public static boolean isValidFileSize(long fileSize) {
        long maxSize = config.getMaxFileSize();
        return fileSize > 0 && fileSize <= maxSize;
    }
    
    /**
     * Validate file extension
     * @param filename Filename
     * @return true if valid
     */
    public static boolean isValidFileExtension(String filename) {
        String extension = getFileExtension(filename);
        
        if (extension.isEmpty()) {
            return false;
        }
        
        // Check if extension is in allowed image extensions
        return Arrays.asList(Constants.ALLOWED_IMAGE_EXTENSIONS).contains(extension) ||
               Arrays.asList(Constants.ALLOWED_DOCUMENT_EXTENSIONS).contains(extension);
    }
    
    /**
     * Delete file
     * @param filePath File path
     * @return true if deleted successfully
     */
    public static boolean deleteFile(String filePath) {
        if (filePath == null || filePath.isEmpty()) {
            return false;
        }
        
        try {
            Path path = Paths.get(filePath);
            Files.deleteIfExists(path);
            logger.info("File deleted: {}", filePath);
            return true;
        } catch (IOException e) {
            logger.error("Error deleting file: {}", filePath, e);
            return false;
        }
    }
    
    /**
     * Check if file exists
     * @param filePath File path
     * @return true if exists
     */
    public static boolean fileExists(String filePath) {
        if (filePath == null || filePath.isEmpty()) {
            return false;
        }
        
        return Files.exists(Paths.get(filePath));
    }
    
    /**
     * Get file size in human-readable format
     * @param bytes File size in bytes
     * @return Formatted size string
     */
    public static String getReadableFileSize(long bytes) {
        if (bytes < 1024) {
            return bytes + " B";
        }
        
        int exp = (int) (Math.log(bytes) / Math.log(1024));
        String prefix = "KMGTPE".charAt(exp - 1) + "";
        return String.format("%.1f %sB", bytes / Math.pow(1024, exp), prefix);
    }
    
    /**
     * Validate image file
     * @param filename Filename
     * @return true if valid image
     */
    public static boolean isValidImageFile(String filename) {
        String extension = getFileExtension(filename);
        return Arrays.asList(Constants.ALLOWED_IMAGE_EXTENSIONS).contains(extension);
    }
    
    /**
     * Validate document file
     * @param filename Filename
     * @return true if valid document
     */
    public static boolean isValidDocumentFile(String filename) {
        String extension = getFileExtension(filename);
        return Arrays.asList(Constants.ALLOWED_DOCUMENT_EXTENSIONS).contains(extension);
    }
}
