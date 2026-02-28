package com.oceanview.controller;

import com.oceanview.model.User;
import com.oceanview.service.AuthenticationService;
import com.oceanview.util.Constants;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.Optional;

/**
 * Login Servlet
 * Handles user authentication
 * URL Mapping: /login (configured in web.xml)
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class LoginServlet extends HttpServlet {
    
    private static final Logger logger = LoggerFactory.getLogger(LoginServlet.class);
    private AuthenticationService authService;
    
    @Override
    public void init() throws ServletException {
        authService = new AuthenticationService();
        logger.info("LoginServlet initialized");
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Check if user is already logged in
        HttpSession session = request.getSession(false);
        if (session != null && session.getAttribute(Constants.SESSION_USER) != null) {
            User user = (User) session.getAttribute(Constants.SESSION_USER);
            redirectToDashboard(request, response, user);
            return;
        }
        
        // Show login page
        request.getRequestDispatcher("/views/auth/login.jsp").forward(request, response);
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Accept both "email" and "username" parameters for flexibility
        String emailOrUsername = request.getParameter("email");
        if (emailOrUsername == null || emailOrUsername.trim().isEmpty()) {
            emailOrUsername = request.getParameter("username");
        }
        String password = request.getParameter("password");
        
        // Validate input
        if (emailOrUsername == null || emailOrUsername.trim().isEmpty() || 
            password == null || password.trim().isEmpty()) {
            
            request.setAttribute(Constants.ATTR_ERROR, "Email/Username and password are required");
            request.getRequestDispatcher("/views/auth/login.jsp").forward(request, response);
            return;
        }
        
        // Authenticate user
        Optional<User> userOpt = authService.authenticate(emailOrUsername.trim(), password);
        
        if (userOpt.isPresent()) {
            User user = userOpt.get();
            
            // Create session
            HttpSession session = request.getSession(true);
            session.setAttribute(Constants.SESSION_USER, user);
            session.setAttribute(Constants.SESSION_USER_ID, user.getUserId());
            session.setAttribute(Constants.SESSION_USERNAME, user.getUsername());
            session.setAttribute(Constants.SESSION_USER_ROLE, user.getRole().name());
            session.setAttribute(Constants.SESSION_USER_NAME, user.getFullName());
            
            // Set session timeout (30 minutes)
            session.setMaxInactiveInterval(30 * 60);
            
            logger.info("User logged in successfully: {}", emailOrUsername);
            
            // Check for redirect URL
            String redirectURL = (String) session.getAttribute("redirectURL");
            if (redirectURL != null) {
                session.removeAttribute("redirectURL");
                response.sendRedirect(redirectURL);
            } else {
                redirectToDashboard(request, response, user);
            }
            
        } else {
            // Authentication failed
            logger.warn("Login failed for username: {}", emailOrUsername);
            request.setAttribute(Constants.ATTR_ERROR, Constants.MSG_LOGIN_FAILED);
            request.getRequestDispatcher("/views/auth/login.jsp").forward(request, response);
        }
    }
    
    /**
     * Redirect to appropriate dashboard based on user role
     */
    private void redirectToDashboard(HttpServletRequest request, HttpServletResponse response, User user)
            throws IOException {
        
        String contextPath = request.getContextPath();
        
        if (user.isAdmin()) {
            response.sendRedirect(contextPath + "/dashboard");
        } else if (user.isStaff()) {
            response.sendRedirect(contextPath + "/dashboard");
        } else {
            response.sendRedirect(contextPath + "/guest/home");
        }
    }
}
