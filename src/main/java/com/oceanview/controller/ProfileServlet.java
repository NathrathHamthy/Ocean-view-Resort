package com.oceanview.controller;

import com.oceanview.dao.GuestDAO;
import com.oceanview.dao.UserDAO;
import com.oceanview.model.Guest;
import com.oceanview.model.User;
import com.oceanview.util.PasswordUtil;
import com.oceanview.util.ValidationUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.Optional;

/**
 * Profile Servlet
 * Handles guest profile view and update operations (CRUD)
 * URL Mapping: /guest/profile (configured in web.xml)
 * 
 * Features:
 * - View profile (GET)
 * - Update profile (POST with action=update)
 * - Change password (POST with action=changePassword)
 * - Delete account (POST with action=delete)
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class ProfileServlet extends HttpServlet {
    
    private static final Logger logger = LoggerFactory.getLogger(ProfileServlet.class);
    private final UserDAO userDAO;
    private final GuestDAO guestDAO;
    
    public ProfileServlet() {
        this.userDAO = new UserDAO();
        this.guestDAO = new GuestDAO();
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        
        // Check authentication
        if (session == null || session.getAttribute("loggedInUser") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        
        User user = (User) session.getAttribute("loggedInUser");
        
        // Check if user has GUEST role
        if (!"GUEST".equals(user.getRole().toString())) {
            logger.warn("Unauthorized access attempt to guest profile by user: {} with role: {}", 
                       user.getUsername(), user.getRole());
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }
        
        try {
            // Fetch fresh user data from database
            Optional<User> freshUser = userDAO.findById(user.getUserId());
            if (freshUser.isPresent()) {
                request.setAttribute("user", freshUser.get());
                
                // Fetch guest data if exists
                Optional<Guest> guest = guestDAO.findByUserId(user.getUserId());
                request.setAttribute("guest", guest.orElse(null));
                request.setAttribute("hasGuestProfile", guest.isPresent());
                
                logger.info("Profile page accessed by: {}", user.getUsername());
            } else {
                request.setAttribute("error", "User data not found.");
                logger.error("User not found in database: {}", user.getUserId());
            }
            
        } catch (SQLException e) {
            logger.error("Error loading profile data for user: {}", user.getUsername(), e);
            request.setAttribute("error", "Unable to load profile data. Please try again later.");
        }
        
        String queryError = request.getParameter("error");
        if (queryError != null && !queryError.isEmpty()) {
            request.setAttribute("error", queryError);
        }
        
        request.getRequestDispatcher("/views/guest/profile.jsp").forward(request, response);
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        
        // Check authentication
        if (session == null || session.getAttribute("loggedInUser") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        
        User user = (User) session.getAttribute("loggedInUser");
        
        // Check role
        if (!"GUEST".equals(user.getRole().toString())) {
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }
        
        String action = request.getParameter("action");
        
        if (action == null) {
            action = "update";
        }
        
        switch (action) {
            case "update":
                handleUpdateProfile(request, response, user);
                break;
            case "changePassword":
                handleChangePassword(request, response, user);
                break;
            case "delete":
                handleDeleteAccount(request, response, user);
                break;
            default:
                response.sendRedirect(request.getContextPath() + "/guest/profile");
        }
    }
    
    /**
     * Handle profile update
     */
    private void handleUpdateProfile(HttpServletRequest request, HttpServletResponse response, User currentUser)
            throws ServletException, IOException {
        
        try {
            // Get form parameters
            String fullName = request.getParameter("fullName");
            String email = request.getParameter("email");
            String phone = request.getParameter("phone");
            
            // Guest-specific fields
            String address = request.getParameter("address");
            String city = request.getParameter("city");
            String country = request.getParameter("country");
            String postalCode = request.getParameter("postalCode");
            String idType = request.getParameter("idType");
            String idNumber = request.getParameter("idNumber");
            String dateOfBirthStr = request.getParameter("dateOfBirth");
            String genderStr = request.getParameter("gender");
            String preferences = request.getParameter("preferences");
            
            // Validate required fields
            if (ValidationUtil.isEmpty(fullName)) {
                request.setAttribute("error", "Full name is required.");
                doGet(request, response);
                return;
            }
            
            if (!ValidationUtil.isValidEmail(email)) {
                request.setAttribute("error", "Valid email is required.");
                doGet(request, response);
                return;
            }
            
            if (phone != null && !phone.trim().isEmpty() && !ValidationUtil.isValidPhone(phone)) {
                request.setAttribute("error", "Invalid phone number format.");
                doGet(request, response);
                return;
            }
            
            // Check if email is already taken by another user
            Optional<User> existingUser = userDAO.findByEmail(email);
            if (existingUser.isPresent() && !existingUser.get().getUserId().equals(currentUser.getUserId())) {
                request.setAttribute("error", "Email is already registered to another account.");
                doGet(request, response);
                return;
            }
            
            // Update User object
            currentUser.setFullName(fullName.trim());
            currentUser.setEmail(email.trim());
            currentUser.setPhone(phone != null ? phone.trim() : null);
            
            // Parse names from full name
            String[] names = fullName.trim().split("\\s+", 2);
            currentUser.setFirstName(names[0]);
            currentUser.setLastName(names.length > 1 ? names[1] : "");
            
            // Update user in database
            boolean userUpdated = userDAO.update(currentUser);
            
            if (!userUpdated) {
                request.setAttribute("error", "Failed to update profile. Please try again.");
                doGet(request, response);
                return;
            }
            
            // Update or create guest profile
            Optional<Guest> existingGuest = guestDAO.findByUserId(currentUser.getUserId());
            Guest guest;
            boolean guestUpdated = false;
            
            if (existingGuest.isPresent()) {
                // Update existing guest
                guest = existingGuest.get();
                guest.setAddress(address != null ? address.trim() : null);
                guest.setCity(city != null ? city.trim() : null);
                guest.setCountry(country != null ? country.trim() : null);
                guest.setPostalCode(postalCode != null ? postalCode.trim() : null);
                guest.setIdType(idType != null ? idType.trim() : null);
                guest.setIdNumber(idNumber != null ? idNumber.trim() : null);
                guest.setPreferences(preferences != null ? preferences.trim() : null);
                
                // Parse date of birth
                if (dateOfBirthStr != null && !dateOfBirthStr.trim().isEmpty()) {
                    try {
                        guest.setDateOfBirth(LocalDate.parse(dateOfBirthStr));
                    } catch (DateTimeParseException e) {
                        logger.warn("Invalid date format: {}", dateOfBirthStr);
                    }
                }
                
                // Parse gender
                if (genderStr != null && !genderStr.trim().isEmpty()) {
                    try {
                        guest.setGender(Guest.Gender.valueOf(genderStr.toUpperCase()));
                    } catch (IllegalArgumentException e) {
                        logger.warn("Invalid gender value: {}", genderStr);
                    }
                }
                
                guestUpdated = guestDAO.update(guest);
                
            } else {
                // Create new guest profile
                guest = new Guest(currentUser.getUserId());
                guest.setAddress(address != null ? address.trim() : null);
                guest.setCity(city != null ? city.trim() : null);
                guest.setCountry(country != null ? country.trim() : null);
                guest.setPostalCode(postalCode != null ? postalCode.trim() : null);
                guest.setIdType(idType != null ? idType.trim() : null);
                guest.setIdNumber(idNumber != null ? idNumber.trim() : null);
                guest.setPreferences(preferences != null ? preferences.trim() : null);
                
                // Parse date of birth
                if (dateOfBirthStr != null && !dateOfBirthStr.trim().isEmpty()) {
                    try {
                        guest.setDateOfBirth(LocalDate.parse(dateOfBirthStr));
                    } catch (DateTimeParseException e) {
                        logger.warn("Invalid date format: {}", dateOfBirthStr);
                    }
                }
                
                // Parse gender
                if (genderStr != null && !genderStr.trim().isEmpty()) {
                    try {
                        guest.setGender(Guest.Gender.valueOf(genderStr.toUpperCase()));
                    } catch (IllegalArgumentException e) {
                        logger.warn("Invalid gender value: {}", genderStr);
                    }
                }
                
                int guestId = guestDAO.create(guest);
                guestUpdated = guestId > 0;
            }
            
            // Update session
            HttpSession session = request.getSession(false);
            if (session != null) {
                session.setAttribute("loggedInUser", currentUser);
            }
            
            logger.info("Profile updated successfully for user: {}", currentUser.getUsername());
            request.setAttribute("success", "Profile updated successfully!");
            
        } catch (SQLException e) {
            logger.error("Error updating profile for user: {}", currentUser.getUsername(), e);
            request.setAttribute("error", "Database error. Please try again later.");
        }
        
        doGet(request, response);
    }
    
    /**
     * Handle password change
     */
    private void handleChangePassword(HttpServletRequest request, HttpServletResponse response, User currentUser)
            throws ServletException, IOException {
        
        try {
            String currentPassword = request.getParameter("currentPassword");
            String newPassword = request.getParameter("newPassword");
            String confirmPassword = request.getParameter("confirmPassword");
            
            // Validate inputs
            if (currentPassword == null || currentPassword.trim().isEmpty()) {
                String message = "Current password is required.";
                response.sendRedirect(request.getContextPath() + "/guest/profile?modal=password&error=" + URLEncoder.encode(message, StandardCharsets.UTF_8.name()));
                return;
            }
            
            if (newPassword == null || newPassword.trim().isEmpty()) {
                String message = "New password is required.";
                response.sendRedirect(request.getContextPath() + "/guest/profile?modal=password&error=" + URLEncoder.encode(message, StandardCharsets.UTF_8.name()));
                return;
            }
            
            if (!newPassword.equals(confirmPassword)) {
                String message = "New passwords do not match.";
                response.sendRedirect(request.getContextPath() + "/guest/profile?modal=password&error=" + URLEncoder.encode(message, StandardCharsets.UTF_8.name()));
                return;
            }
            
            if (newPassword.length() < 6) {
                String message = "Password must be at least 6 characters long.";
                response.sendRedirect(request.getContextPath() + "/guest/profile?modal=password&error=" + URLEncoder.encode(message, StandardCharsets.UTF_8.name()));
                return;
            }
            
            // Verify current password
            Optional<User> dbUser = userDAO.findById(currentUser.getUserId());
            if (!dbUser.isPresent()) {
                String message = "User not found.";
                response.sendRedirect(request.getContextPath() + "/guest/profile?modal=password&error=" + URLEncoder.encode(message, StandardCharsets.UTF_8.name()));
                return;
            }
            
            if (!PasswordUtil.verifyPassword(currentPassword, dbUser.get().getPassword())) {
                String message = "Current password is incorrect.";
                response.sendRedirect(request.getContextPath() + "/guest/profile?modal=password&error=" + URLEncoder.encode(message, StandardCharsets.UTF_8.name()));
                return;
            }
            
            // Hash and update new password
            String hashedPassword = PasswordUtil.hashPassword(newPassword);
            boolean updated = userDAO.updatePassword(currentUser.getUserId(), hashedPassword);
            
            if (updated) {
                logger.info("Password changed successfully for user: {}", currentUser.getUsername());
                request.setAttribute("success", "Password changed successfully!");
            } else {
                String message = "Failed to change password. Please try again.";
                response.sendRedirect(request.getContextPath() + "/guest/profile?modal=password&error=" + URLEncoder.encode(message, StandardCharsets.UTF_8.name()));
                return;
            }
            
        } catch (SQLException e) {
            logger.error("Error changing password for user: {}", currentUser.getUsername(), e);
            try {
                String message = "Database error. Please try again later.";
                response.sendRedirect(request.getContextPath() + "/guest/profile?modal=password&error=" + URLEncoder.encode(message, StandardCharsets.UTF_8.name()));
            } catch (IOException ioEx) {
                logger.error("Redirect failed after password change error", ioEx);
            }
            return;
        }
        
        doGet(request, response);
    }
    
    /**
     * Handle account deletion
     */
    private void handleDeleteAccount(HttpServletRequest request, HttpServletResponse response, User currentUser)
            throws ServletException, IOException {
        
        try {
            String confirmPassword = request.getParameter("confirmPassword");
            String confirmText = request.getParameter("confirmText");

            // Validate confirmation — redirect back so the delete modal auto-reopens
            if (confirmPassword == null || confirmPassword.trim().isEmpty()) {
                String message = "Password is required to delete account.";
                response.sendRedirect(request.getContextPath() + "/guest/profile?modal=delete&error=" + URLEncoder.encode(message, StandardCharsets.UTF_8.name()));
                return;
            }

            if (!"DELETE".equals(confirmText)) {
                String message = "Please type 'DELETE' to confirm account deletion.";
                response.sendRedirect(request.getContextPath() + "/guest/profile?modal=delete&error=" + URLEncoder.encode(message, StandardCharsets.UTF_8.name()));
                return;
            }

            // Verify password
            Optional<User> dbUser = userDAO.findById(currentUser.getUserId());
            if (!dbUser.isPresent()) {
                String message = "User not found.";
                response.sendRedirect(request.getContextPath() + "/guest/profile?modal=delete&error=" + URLEncoder.encode(message, StandardCharsets.UTF_8.name()));
                return;
            }

            if (!PasswordUtil.verifyPassword(confirmPassword, dbUser.get().getPassword())) {
                String message = "Password is incorrect.";
                response.sendRedirect(request.getContextPath() + "/guest/profile?modal=delete&error=" + URLEncoder.encode(message, StandardCharsets.UTF_8.name()));
                return;
            }

            // Delete guest profile first (if exists)
            Optional<Guest> guest = guestDAO.findByUserId(currentUser.getUserId());
            if (guest.isPresent()) {
                guestDAO.delete(guest.get().getGuestId());
            }

            // Delete user account
            boolean deleted = userDAO.delete(currentUser.getUserId());

            if (deleted) {
                logger.info("Account deleted successfully for user: {}", currentUser.getUsername());

                // Invalidate session and redirect to home
                HttpSession session = request.getSession(false);
                if (session != null) {
                    session.invalidate();
                }

                response.sendRedirect(request.getContextPath() + "/?deleted=true");
            } else {
                String message = "Failed to delete account. Please try again.";
                response.sendRedirect(request.getContextPath() + "/guest/profile?modal=delete&error=" + URLEncoder.encode(message, StandardCharsets.UTF_8.name()));
            }

        } catch (SQLException e) {
            logger.error("Error deleting account for user: {}", currentUser.getUsername(), e);
            try {
                String message = "Database error. Please try again later.";
                response.sendRedirect(request.getContextPath() + "/guest/profile?modal=delete&error=" + URLEncoder.encode(message, StandardCharsets.UTF_8.name()));
            } catch (IOException ioEx) {
                logger.error("Redirect failed after account deletion error", ioEx);
            }
        }
    }
}
