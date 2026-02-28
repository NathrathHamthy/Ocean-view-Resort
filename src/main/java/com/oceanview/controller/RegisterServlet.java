package com.oceanview.controller;

import com.oceanview.dao.GuestDAO;
import com.oceanview.model.Guest;
import com.oceanview.model.User;
import com.oceanview.service.AuthenticationService;
import com.oceanview.util.Constants;
import com.oceanview.util.ValidationUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;

/**
 * Register Servlet
 * Handles user registration
 * URL Mapping: /register (configured in web.xml)
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class RegisterServlet extends HttpServlet {
    
    private static final Logger logger = LoggerFactory.getLogger(RegisterServlet.class);
    private AuthenticationService authService;
    private GuestDAO guestDAO;
    
    @Override
    public void init() throws ServletException {
        authService = new AuthenticationService();
        guestDAO = new GuestDAO();
        logger.info("RegisterServlet initialized");
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Show registration page
        request.getRequestDispatcher("/views/auth/register.jsp").forward(request, response);
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Get form parameters
        String username = request.getParameter("username");
        String password = request.getParameter("password");
        String confirmPassword = request.getParameter("confirmPassword");
        String email = request.getParameter("email");
        String phone = request.getParameter("phone");
        
        // Get firstName and lastName, combine into fullName
        String firstName = request.getParameter("firstName");
        String lastName = request.getParameter("lastName");
        String fullName = null;
        if (firstName != null && lastName != null) {
            fullName = (firstName.trim() + " " + lastName.trim()).trim();
        }
        
        // Validate input
        String validationError = validateInput(username, password, confirmPassword, email, firstName, lastName);
        if (validationError != null) {
            request.setAttribute(Constants.ATTR_ERROR, validationError);
            request.getRequestDispatcher("/views/auth/register.jsp").forward(request, response);
            return;
        }
        
        // Create user object
        User user = new User();
        user.setUsername(username.trim());
        user.setPassword(password);
        user.setEmail(email.trim().toLowerCase());
        user.setFullName(fullName.trim());
        user.setPhone(phone != null ? phone.trim() : null);
        user.setRole(User.Role.GUEST);
        user.setStatus(User.Status.ACTIVE);
        
        // Register user
        int userId = authService.register(user);
        
        if (userId == -1) {
            request.setAttribute(Constants.ATTR_ERROR, "Username already exists");
            request.getRequestDispatcher("/views/auth/register.jsp").forward(request, response);
            return;
        } else if (userId == -2) {
            request.setAttribute(Constants.ATTR_ERROR, "Email already exists");
            request.getRequestDispatcher("/views/auth/register.jsp").forward(request, response);
            return;
        } else if (userId < 0) {
            request.setAttribute(Constants.ATTR_ERROR, "Registration failed. Please try again.");
            request.getRequestDispatcher("/views/auth/register.jsp").forward(request, response);
            return;
        }
        
        // Create guest profile
        try {
            Guest guest = new Guest();
            guest.setUserId(userId);
            guestDAO.create(guest);
            
            logger.info("Guest profile created for user: {}", username);
        } catch (Exception e) {
            logger.error("Error creating guest profile for user: {}", username, e);
        }
        
        logger.info("User registered successfully: {}", username);
        
        // Set success message
        request.setAttribute(Constants.ATTR_SUCCESS, 
            "Registration successful! Please login with your credentials.");
        
        // Forward to login page
        request.getRequestDispatcher("/views/auth/login.jsp").forward(request, response);
    }
    
    /**
     * Validate registration input
     */
    private String validateInput(String username, String password, String confirmPassword, 
                                 String email, String firstName, String lastName) {
        
        // Check required fields
        if (username == null || username.trim().isEmpty()) {
            return "Username is required";
        }
        
        if (password == null || password.isEmpty()) {
            return "Password is required";
        }
        
        if (confirmPassword == null || confirmPassword.isEmpty()) {
            return "Please confirm your password";
        }
        
        if (email == null || email.trim().isEmpty()) {
            return "Email is required";
        }
        
        if (firstName == null || firstName.trim().isEmpty()) {
            return "First name is required";
        }
        
        if (lastName == null || lastName.trim().isEmpty()) {
            return "Last name is required";
        }
        
        // Validate username format
        if (!username.matches(Constants.REGEX_USERNAME)) {
            return "Username must be 3-20 characters and contain only letters, numbers, dots, hyphens or underscores";
        }
        
        // Validate email format
        if (!email.matches(Constants.REGEX_EMAIL)) {
            return Constants.MSG_INVALID_EMAIL;
        }
        
        // Validate password length
        if (password.length() < 8) {
            return Constants.MSG_PASSWORD_TOO_SHORT;
        }
        
        // Check if passwords match
        if (!password.equals(confirmPassword)) {
            return "Passwords do not match";
        }
        
        return null; // All validations passed
    }
}
