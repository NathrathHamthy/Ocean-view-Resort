package com.oceanview.controller;

import com.oceanview.dao.UserDAO;
import com.oceanview.model.User;
import com.oceanview.util.Constants;
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
import java.io.PrintWriter;
import java.util.List;
import java.util.Optional;

/**
 * UserServlet — Admin User Management with full CRUD
 *
 * GET  /admin/users                     → list all users
 * GET  /admin/users?action=view&id=     → view user JSON (AJAX)
 * POST /admin/users  action=create      → create new user
 * POST /admin/users  action=update      → update user
 * POST /admin/users  action=delete      → delete user
 * POST /admin/users  action=toggleStatus→ toggle active/suspended
 * POST /admin/users  action=resetPassword → reset user password
 *
 * @author Ocean View Resort Dev Team
 * @version 2.0.0
 */
public class UserServlet extends HttpServlet {

    private static final Logger logger = LoggerFactory.getLogger(UserServlet.class);
    private UserDAO userDAO;

    @Override
    public void init() throws ServletException {
        userDAO = new UserDAO();
        logger.info("UserServlet initialized");
    }

    // ─────────────────────────── GET ────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!isAdmin(request, response)) return;

        String action = request.getParameter("action");
        if ("view".equals(action)) {
            handleViewJson(request, response);
        } else {
            listUsers(request, response);
        }
    }

    // ─────────────────────────── POST ───────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!isAdmin(request, response)) return;

        String action = request.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "create":        createUser(request, response);        break;
            case "update":        updateUser(request, response);        break;
            case "delete":        deleteUser(request, response);        break;
            case "toggleStatus":  toggleStatus(request, response);      break;
            case "resetPassword": resetPassword(request, response);     break;
            default:
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid action");
        }
    }

    // ─────────────────────────── LIST USERS ─────────────────────────────────

    private void listUsers(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            List<User> users = userDAO.findAll();

            // Stats
            long totalUsers   = users.size();
            long totalAdmins  = users.stream().filter(u -> u.getRole() == User.Role.ADMIN).count();
            long totalStaff   = users.stream().filter(u -> u.getRole() == User.Role.STAFF).count();
            long totalGuests  = users.stream().filter(u -> u.getRole() == User.Role.GUEST).count();
            long activeUsers  = users.stream().filter(u -> u.getStatus() == User.Status.ACTIVE).count();
            long suspended    = users.stream().filter(u -> u.getStatus() == User.Status.SUSPENDED).count();

            request.setAttribute("users",       users);
            request.setAttribute("totalUsers",  (int) totalUsers);
            request.setAttribute("totalAdmins", (int) totalAdmins);
            request.setAttribute("totalStaff",  (int) totalStaff);
            request.setAttribute("totalGuests", (int) totalGuests);
            request.setAttribute("activeUsers", (int) activeUsers);
            request.setAttribute("suspended",   (int) suspended);

            transferFlash(request);
            request.getRequestDispatcher("/views/admin/users.jsp").forward(request, response);

        } catch (Exception e) {
            logger.error("Error listing users", e);
            request.setAttribute(Constants.ATTR_ERROR, "Error loading users. Please try again.");
            request.getRequestDispatcher("/views/admin/users.jsp").forward(request, response);
        }
    }

    // ─────────────────────────── VIEW JSON (AJAX) ───────────────────────────

    private void handleViewJson(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        PrintWriter out = response.getWriter();
        String idStr = request.getParameter("id");

        if (!ValidationUtil.isValidInteger(idStr)) {
            response.setStatus(400); out.print("{\"error\":\"Invalid ID\"}"); return;
        }
        try {
            Optional<User> opt = userDAO.findById(Integer.parseInt(idStr));
            if (!opt.isPresent()) { response.setStatus(404); out.print("{\"error\":\"Not found\"}"); return; }
            User u = opt.get();
            out.print("{");
            out.print("\"id\":"           + u.getUserId()                                                         + ",");
            out.print("\"username\":\""   + esc(u.getUsername())                                                  + "\",");
            out.print("\"fullName\":\""   + esc(u.getFullName())                                                  + "\",");
            out.print("\"email\":\""      + esc(u.getEmail())                                                     + "\",");
            out.print("\"phone\":\""      + esc(u.getPhone())                                                     + "\",");
            out.print("\"role\":\""       + esc(u.getRole() != null ? u.getRole().name() : "")                   + "\",");
            out.print("\"status\":\""     + esc(u.getStatus() != null ? u.getStatus().name() : "")               + "\",");
            out.print("\"createdAt\":\""  + esc(u.getCreatedAt() != null ? u.getCreatedAt().toString() : "")     + "\",");
            out.print("\"lastLogin\":\""  + esc(u.getLastLogin() != null ? u.getLastLogin().toString() : "Never")+ "\"");
            out.print("}");
        } catch (Exception e) {
            logger.error("Error fetching user JSON", e);
            response.setStatus(500); out.print("{\"error\":\"Server error\"}");
        }
    }

    // ─────────────────────────── CREATE USER ────────────────────────────────

    private void createUser(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        HttpSession session = request.getSession();

        String username = sanitize(request.getParameter("username"));
        String fullName = sanitize(request.getParameter("fullName"));
        String email    = sanitize(request.getParameter("email"));
        String phone    = sanitize(request.getParameter("phone"));
        String password = request.getParameter("password");
        String roleStr  = request.getParameter("role");

        // Validate
        if (ValidationUtil.isEmpty(username) || ValidationUtil.isEmpty(fullName)
                || ValidationUtil.isEmpty(email) || ValidationUtil.isEmpty(password)) {
            session.setAttribute(Constants.ATTR_ERROR, "All required fields must be filled.");
            response.sendRedirect(request.getContextPath() + "/admin/users"); return;
        }
        if (!ValidationUtil.isValidEmail(email)) {
            session.setAttribute(Constants.ATTR_ERROR, "Invalid email address.");
            response.sendRedirect(request.getContextPath() + "/admin/users"); return;
        }
        if (password.length() < 6) {
            session.setAttribute(Constants.ATTR_ERROR, "Password must be at least 6 characters.");
            response.sendRedirect(request.getContextPath() + "/admin/users"); return;
        }

        try {
            if (userDAO.existsByUsername(username)) {
                session.setAttribute(Constants.ATTR_ERROR, "Username '" + username + "' is already taken.");
                response.sendRedirect(request.getContextPath() + "/admin/users"); return;
            }
            if (userDAO.existsByEmail(email)) {
                session.setAttribute(Constants.ATTR_ERROR, "Email '" + email + "' is already registered.");
                response.sendRedirect(request.getContextPath() + "/admin/users"); return;
            }

            User newUser = new User();
            newUser.setUsername(username);
            newUser.setFullName(fullName);
            newUser.setEmail(email);
            newUser.setPhone(phone);
            newUser.setPassword(PasswordUtil.hashPassword(password));
            newUser.setStatus(User.Status.ACTIVE);
            try { newUser.setRole(User.Role.valueOf(roleStr)); }
            catch (Exception e) { newUser.setRole(User.Role.GUEST); }

            int newId = userDAO.create(newUser);
            if (newId > 0) {
                logger.info("Admin created new user: {} (ID={})", username, newId);
                session.setAttribute(Constants.ATTR_SUCCESS, "✓ User '" + fullName + "' created successfully!");
            } else {
                session.setAttribute(Constants.ATTR_ERROR, "Failed to create user. Please try again.");
            }
        } catch (Exception e) {
            logger.error("Error creating user", e);
            session.setAttribute(Constants.ATTR_ERROR, "Server error creating user.");
        }
        response.sendRedirect(request.getContextPath() + "/admin/users");
    }

    // ─────────────────────────── UPDATE USER ────────────────────────────────

    private void updateUser(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        HttpSession session = request.getSession();
        String idStr = request.getParameter("userId");

        if (!ValidationUtil.isValidInteger(idStr)) {
            session.setAttribute(Constants.ATTR_ERROR, "Invalid user ID.");
            response.sendRedirect(request.getContextPath() + "/admin/users"); return;
        }

        int userId     = Integer.parseInt(idStr);
        String fullName = sanitize(request.getParameter("fullName"));
        String email    = sanitize(request.getParameter("email"));
        String phone    = sanitize(request.getParameter("phone"));
        String roleStr  = request.getParameter("role");
        String statusStr= request.getParameter("status");

        if (ValidationUtil.isEmpty(fullName) || ValidationUtil.isEmpty(email)) {
            session.setAttribute(Constants.ATTR_ERROR, "Full name and email are required.");
            response.sendRedirect(request.getContextPath() + "/admin/users"); return;
        }
        if (!ValidationUtil.isValidEmail(email)) {
            session.setAttribute(Constants.ATTR_ERROR, "Invalid email address.");
            response.sendRedirect(request.getContextPath() + "/admin/users"); return;
        }

        try {
            Optional<User> opt = userDAO.findById(userId);
            if (!opt.isPresent()) {
                session.setAttribute(Constants.ATTR_ERROR, "User not found.");
                response.sendRedirect(request.getContextPath() + "/admin/users"); return;
            }

            // Check email uniqueness (excluding current user)
            Optional<User> byEmail = userDAO.findByEmail(email);
            if (byEmail.isPresent() && byEmail.get().getUserId() != userId) {
                session.setAttribute(Constants.ATTR_ERROR, "Email '" + email + "' is already in use.");
                response.sendRedirect(request.getContextPath() + "/admin/users"); return;
            }

            User user = opt.get();
            user.setFullName(fullName);
            user.setEmail(email);
            user.setPhone(phone);
            try { user.setRole(User.Role.valueOf(roleStr)); } catch (Exception e) {}
            try { user.setStatus(User.Status.valueOf(statusStr)); } catch (Exception e) {}

            boolean success = userDAO.update(user);
            if (success) {
                logger.info("Admin updated user ID={}", userId);
                session.setAttribute(Constants.ATTR_SUCCESS, "✓ User '" + fullName + "' updated successfully!");
            } else {
                session.setAttribute(Constants.ATTR_ERROR, "Failed to update user.");
            }
        } catch (Exception e) {
            logger.error("Error updating user ID={}", userId, e);
            session.setAttribute(Constants.ATTR_ERROR, "Server error updating user.");
        }
        response.sendRedirect(request.getContextPath() + "/admin/users");
    }

    // ─────────────────────────── DELETE USER ────────────────────────────────

    private void deleteUser(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        HttpSession session = request.getSession();
        User currentUser = (User) session.getAttribute(Constants.SESSION_USER);
        String idStr = request.getParameter("userId");

        if (!ValidationUtil.isValidInteger(idStr)) {
            session.setAttribute(Constants.ATTR_ERROR, "Invalid user ID.");
            response.sendRedirect(request.getContextPath() + "/admin/users"); return;
        }

        int userId = Integer.parseInt(idStr);

        // Cannot delete yourself
        if (currentUser != null && currentUser.getUserId() == userId) {
            session.setAttribute(Constants.ATTR_ERROR, "You cannot delete your own account.");
            response.sendRedirect(request.getContextPath() + "/admin/users"); return;
        }

        try {
            Optional<User> opt = userDAO.findById(userId);
            if (!opt.isPresent()) {
                session.setAttribute(Constants.ATTR_ERROR, "User not found.");
                response.sendRedirect(request.getContextPath() + "/admin/users"); return;
            }
            String name = opt.get().getFullName();
            boolean success = userDAO.delete(userId);
            if (success) {
                logger.info("Admin deleted user ID={} ({})", userId, name);
                session.setAttribute(Constants.ATTR_SUCCESS, "✓ User '" + name + "' deleted successfully.");
            } else {
                session.setAttribute(Constants.ATTR_ERROR, "Failed to delete user. They may have active reservations.");
            }
        } catch (Exception e) {
            logger.error("Error deleting user ID={}", userId, e);
            session.setAttribute(Constants.ATTR_ERROR, "Cannot delete user — they may have associated records.");
        }
        response.sendRedirect(request.getContextPath() + "/admin/users");
    }

    // ─────────────────────────── TOGGLE STATUS ──────────────────────────────

    private void toggleStatus(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        HttpSession session = request.getSession();
        User currentUser = (User) session.getAttribute(Constants.SESSION_USER);
        String idStr = request.getParameter("userId");

        if (!ValidationUtil.isValidInteger(idStr)) {
            session.setAttribute(Constants.ATTR_ERROR, "Invalid user ID.");
            response.sendRedirect(request.getContextPath() + "/admin/users"); return;
        }

        int userId = Integer.parseInt(idStr);
        if (currentUser != null && currentUser.getUserId() == userId) {
            session.setAttribute(Constants.ATTR_ERROR, "You cannot change your own status.");
            response.sendRedirect(request.getContextPath() + "/admin/users"); return;
        }

        try {
            Optional<User> opt = userDAO.findById(userId);
            if (!opt.isPresent()) {
                session.setAttribute(Constants.ATTR_ERROR, "User not found.");
                response.sendRedirect(request.getContextPath() + "/admin/users"); return;
            }
            User user = opt.get();
            User.Status newStatus = (user.getStatus() == User.Status.ACTIVE)
                    ? User.Status.SUSPENDED : User.Status.ACTIVE;
            user.setStatus(newStatus);
            boolean success = userDAO.update(user);
            if (success) {
                session.setAttribute(Constants.ATTR_SUCCESS,
                    "✓ User '" + user.getFullName() + "' status changed to " + newStatus.name() + ".");
            } else {
                session.setAttribute(Constants.ATTR_ERROR, "Failed to update status.");
            }
        } catch (Exception e) {
            logger.error("Error toggling status for user ID={}", userId, e);
            session.setAttribute(Constants.ATTR_ERROR, "Server error changing status.");
        }
        response.sendRedirect(request.getContextPath() + "/admin/users");
    }

    // ─────────────────────────── RESET PASSWORD ─────────────────────────────

    private void resetPassword(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        HttpSession session = request.getSession();
        String idStr      = request.getParameter("userId");
        String newPassword = request.getParameter("newPassword");

        if (!ValidationUtil.isValidInteger(idStr)) {
            session.setAttribute(Constants.ATTR_ERROR, "Invalid user ID.");
            response.sendRedirect(request.getContextPath() + "/admin/users"); return;
        }
        if (ValidationUtil.isEmpty(newPassword) || newPassword.length() < 6) {
            session.setAttribute(Constants.ATTR_ERROR, "New password must be at least 6 characters.");
            response.sendRedirect(request.getContextPath() + "/admin/users"); return;
        }

        int userId = Integer.parseInt(idStr);
        try {
            Optional<User> opt = userDAO.findById(userId);
            if (!opt.isPresent()) {
                session.setAttribute(Constants.ATTR_ERROR, "User not found.");
                response.sendRedirect(request.getContextPath() + "/admin/users"); return;
            }
            String hashed = PasswordUtil.hashPassword(newPassword);
            boolean success = userDAO.updatePassword(userId, hashed);
            if (success) {
                logger.info("Admin reset password for user ID={}", userId);
                session.setAttribute(Constants.ATTR_SUCCESS,
                    "✓ Password reset successfully for '" + opt.get().getFullName() + "'.");
            } else {
                session.setAttribute(Constants.ATTR_ERROR, "Failed to reset password.");
            }
        } catch (Exception e) {
            logger.error("Error resetting password for user ID={}", userId, e);
            session.setAttribute(Constants.ATTR_ERROR, "Server error resetting password.");
        }
        response.sendRedirect(request.getContextPath() + "/admin/users");
    }

    // ─────────────────────────── UTILS ──────────────────────────────────────

    private boolean isAdmin(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute(Constants.SESSION_USER) == null) {
            response.sendRedirect(request.getContextPath() + "/login"); return false;
        }
        User u = (User) session.getAttribute(Constants.SESSION_USER);
        if (!u.isAdmin()) {
            try { response.sendError(HttpServletResponse.SC_FORBIDDEN); } catch (Exception ignored) {}
            return false;
        }
        return true;
    }

    private void transferFlash(HttpServletRequest request) {
        HttpSession s = request.getSession(false);
        if (s == null) return;
        String ok  = (String) s.getAttribute(Constants.ATTR_SUCCESS);
        String err = (String) s.getAttribute(Constants.ATTR_ERROR);
        if (ok  != null) { request.setAttribute(Constants.ATTR_SUCCESS, ok);  s.removeAttribute(Constants.ATTR_SUCCESS); }
        if (err != null) { request.setAttribute(Constants.ATTR_ERROR,   err); s.removeAttribute(Constants.ATTR_ERROR);   }
    }

    private String sanitize(String s) {
        return s != null ? ValidationUtil.sanitize(s.trim()) : "";
    }

    private String esc(String s) {
        if (s == null) return "";
        return s.replace("\\","\\\\").replace("\"","\\\"")
                .replace("\n","\\n").replace("\r","\\r").replace("\t","\\t");
    }
}
