package com.oceanview.controller;

import com.oceanview.dao.UserDAO;
import com.oceanview.factory.DAOFactory;
import com.oceanview.factory.ServiceFactory;
import com.oceanview.model.HotelSetting;
import com.oceanview.model.User;
import com.oceanview.service.AuthenticationService;
import com.oceanview.service.SettingsService;
import com.oceanview.util.Constants;
import com.oceanview.util.ValidationUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.List;
import java.util.Map;

/**
 * SettingsServlet
 * Handles all admin settings operations (CRUD) backed by hotel_settings DB table.
 * URL: /admin/settings  and  /settings
 *
 * @author Ocean View Resort Development Team
 * @version 2.0.0
 */
public class SettingsServlet extends HttpServlet {

    private static final Logger logger = LoggerFactory.getLogger(SettingsServlet.class);

    private SettingsService    settingsService;
    private UserDAO            userDAO;
    private AuthenticationService authService;

    @Override
    public void init() throws ServletException {
        settingsService = ServiceFactory.getSettingsService();
        userDAO         = DAOFactory.getUserDAO();
        authService     = ServiceFactory.getAuthenticationService();
        logger.info("SettingsServlet v2 initialized");
    }

    // ── GET ─────────────────────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        User user = (User) session.getAttribute(Constants.SESSION_USER);

        if (user == null || !user.isAdmin()) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) action = "view";

        try {
            switch (action) {
                case "delete":
                    handleDelete(request, response, user);
                    return;
                default:
                    loadSettingsPage(request, response, user);
            }
        } catch (Exception e) {
            logger.error("Error in SettingsServlet GET", e);
            session.setAttribute(Constants.ATTR_ERROR, "Error loading settings: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/admin/settings");
        }
    }

    // ── POST ────────────────────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        User user = (User) session.getAttribute(Constants.SESSION_USER);

        if (user == null || !user.isAdmin()) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        String action = request.getParameter("action");
        if (action == null) action = "";

        try {
            switch (action) {
                case "updateGeneral":
                    updateCategory(request, response, user, "GENERAL", "general");
                    break;
                case "updateBilling":
                    updateCategory(request, response, user, "BILLING", "billing");
                    break;
                case "updateSecurity":
                    updateCategory(request, response, user, "SECURITY", "security");
                    break;
                case "updateFeatures":
                    updateCategory(request, response, user, "FEATURES", "features");
                    break;
                case "updateContact":
                    updateCategory(request, response, user, "CONTACT", "contact");
                    break;
                case "updateNotification":
                    updateCategory(request, response, user, "NOTIFICATION", "notification");
                    break;
                case "updateSession":
                    updateCategory(request, response, user, "SESSION", "general");
                    break;
                case "createSetting":
                    handleCreate(request, response, user);
                    break;
                case "changePassword":
                    handleChangePassword(request, response, user);
                    break;
                case "updateProfile":
                    handleUpdateProfile(request, response, user);
                    break;
                case "clearCache":
                    handleClearCache(request, response);
                    break;
                default:
                    session.setAttribute(Constants.ATTR_ERROR, "Unknown settings action.");
                    response.sendRedirect(request.getContextPath() + "/admin/settings");
            }
        } catch (Exception e) {
            logger.error("Error in SettingsServlet POST action={}", action, e);
            session.setAttribute(Constants.ATTR_ERROR, "Error: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/admin/settings");
        }
    }

    // ── LOAD PAGE ────────────────────────────────────────────────────────────

    private void loadSettingsPage(HttpServletRequest request, HttpServletResponse response, User user)
            throws ServletException, IOException {

        // All settings grouped by category
        Map<String, List<HotelSetting>> grouped = settingsService.getAllGrouped();
        request.setAttribute("settingsGrouped", grouped);

        // Flat map for easy lookups in JSP
        Map<String, String> settingsMap = settingsService.getAllAsMap();
        request.setAttribute("settingsMap", settingsMap);

        // System info
        request.setAttribute("systemInfo", settingsService.getSystemInfo());

        // Active tab (from param or default)
        String tab = request.getParameter("tab");
        request.setAttribute("activeTab", tab != null ? tab : "general");

        request.getRequestDispatcher("/views/admin/settings.jsp").forward(request, response);
    }

    // ── UPDATE CATEGORY ──────────────────────────────────────────────────────

    private void updateCategory(HttpServletRequest request, HttpServletResponse response,
                                 User user, String category, String tab)
            throws IOException {

        HttpSession session = request.getSession();
        boolean ok = settingsService.updateCategory(request.getParameterMap(), category, user.getUserId());

        if (ok) {
            session.setAttribute(Constants.ATTR_SUCCESS, category.charAt(0) + category.substring(1).toLowerCase() + " settings saved successfully.");
        } else {
            session.setAttribute(Constants.ATTR_ERROR, "Failed to save " + category.toLowerCase() + " settings.");
        }
        response.sendRedirect(request.getContextPath() + "/admin/settings?tab=" + tab);
    }

    // ── CREATE SETTING ───────────────────────────────────────────────────────

    private void handleCreate(HttpServletRequest request, HttpServletResponse response, User user)
            throws IOException {

        HttpSession session = request.getSession();
        String category    = request.getParameter("newCategory");
        String key         = request.getParameter("newKey");
        String value       = request.getParameter("newValue");
        String typeStr     = request.getParameter("newType");
        String description = request.getParameter("newDescription");

        if (key == null || key.trim().isEmpty()) {
            session.setAttribute(Constants.ATTR_ERROR, "Setting key is required.");
            response.sendRedirect(request.getContextPath() + "/admin/settings?tab=custom");
            return;
        }

        HotelSetting.SettingType type;
        try { type = HotelSetting.SettingType.valueOf(typeStr); }
        catch (Exception e) { type = HotelSetting.SettingType.STRING; }

        boolean ok = settingsService.createSetting(category, key, value, type, description);
        if (ok) {
            session.setAttribute(Constants.ATTR_SUCCESS, "Setting '" + key + "' created successfully.");
        } else {
            session.setAttribute(Constants.ATTR_ERROR, "Failed to create setting. Key may already exist.");
        }
        response.sendRedirect(request.getContextPath() + "/admin/settings?tab=custom");
    }

    // ── DELETE SETTING ───────────────────────────────────────────────────────

    private void handleDelete(HttpServletRequest request, HttpServletResponse response, User user)
            throws IOException {

        HttpSession session = request.getSession();
        String key = request.getParameter("key");

        if (key == null || key.trim().isEmpty()) {
            session.setAttribute(Constants.ATTR_ERROR, "No key specified for deletion.");
            response.sendRedirect(request.getContextPath() + "/admin/settings?tab=custom");
            return;
        }

        boolean ok = settingsService.deleteSetting(key);
        if (ok) {
            session.setAttribute(Constants.ATTR_SUCCESS, "Setting '" + key + "' deleted.");
        } else {
            session.setAttribute(Constants.ATTR_ERROR, "Failed to delete setting '" + key + "'.");
        }
        response.sendRedirect(request.getContextPath() + "/admin/settings?tab=custom");
    }

    // ── CHANGE PASSWORD ──────────────────────────────────────────────────────

    private void handleChangePassword(HttpServletRequest request, HttpServletResponse response, User user)
            throws IOException {

        HttpSession session = request.getSession();
        String currentPwd = request.getParameter("currentPassword");
        String newPwd     = request.getParameter("newPassword");
        String confirmPwd = request.getParameter("confirmPassword");

        if (ValidationUtil.isEmpty(currentPwd) || ValidationUtil.isEmpty(newPwd) || ValidationUtil.isEmpty(confirmPwd)) {
            session.setAttribute(Constants.ATTR_ERROR, "All password fields are required.");
            response.sendRedirect(request.getContextPath() + "/admin/settings?tab=password");
            return;
        }
        if (!newPwd.equals(confirmPwd)) {
            session.setAttribute(Constants.ATTR_ERROR, "New passwords do not match.");
            response.sendRedirect(request.getContextPath() + "/admin/settings?tab=password");
            return;
        }
        if (newPwd.length() < 8) {
            session.setAttribute(Constants.ATTR_ERROR, "Password must be at least 8 characters.");
            response.sendRedirect(request.getContextPath() + "/admin/settings?tab=password");
            return;
        }

        try {
            boolean changed = authService.changePassword(user.getUserId(), currentPwd, newPwd);
            if (changed) {
                logger.info("Password changed for admin userId={}", user.getUserId());
                session.setAttribute(Constants.ATTR_SUCCESS, "Password changed successfully!");
            } else {
                session.setAttribute(Constants.ATTR_ERROR, "Current password is incorrect.");
            }
        } catch (Exception e) {
            logger.error("Error changing password for userId={}", user.getUserId(), e);
            session.setAttribute(Constants.ATTR_ERROR, "Error changing password: " + e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/admin/settings?tab=password");
    }

    // ── UPDATE PROFILE ───────────────────────────────────────────────────────

    private void handleUpdateProfile(HttpServletRequest request, HttpServletResponse response, User user)
            throws IOException {

        HttpSession session = request.getSession();
        String fullName = request.getParameter("fullName");
        String email    = request.getParameter("email");
        String phone    = request.getParameter("phone");

        if (ValidationUtil.isEmpty(fullName) || ValidationUtil.isEmpty(email)) {
            session.setAttribute(Constants.ATTR_ERROR, "Full name and email are required.");
            response.sendRedirect(request.getContextPath() + "/admin/settings?tab=profile");
            return;
        }
        if (!ValidationUtil.isValidEmail(email)) {
            session.setAttribute(Constants.ATTR_ERROR, "Invalid email address.");
            response.sendRedirect(request.getContextPath() + "/admin/settings?tab=profile");
            return;
        }
        try {
            user.setFullName(fullName.trim());
            user.setEmail(email.trim());
            user.setPhone(phone != null ? phone.trim() : "");
            boolean updated = userDAO.update(user);
            if (updated) {
                session.setAttribute(Constants.SESSION_USER, user);
                session.setAttribute(Constants.ATTR_SUCCESS, "Profile updated successfully!");
                logger.info("Profile updated for admin userId={}", user.getUserId());
            } else {
                session.setAttribute(Constants.ATTR_ERROR, "Failed to update profile.");
            }
        } catch (Exception e) {
            logger.error("Error updating profile for userId={}", user.getUserId(), e);
            session.setAttribute(Constants.ATTR_ERROR, "Error updating profile: " + e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/admin/settings?tab=profile");
    }

    // ── CLEAR CACHE ──────────────────────────────────────────────────────────

    private void handleClearCache(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        // Clear servlet context attributes that act as cache
        getServletContext().getAttributeNames().asIterator().forEachRemaining(name -> {
            if (name.startsWith("cache.")) getServletContext().removeAttribute(name);
        });

        logger.info("Application cache cleared by admin");
        request.getSession().setAttribute(Constants.ATTR_SUCCESS, "Cache cleared successfully!");
        response.sendRedirect(request.getContextPath() + "/admin/settings?tab=system");
    }
}
