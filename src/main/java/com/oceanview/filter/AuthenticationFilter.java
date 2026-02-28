package com.oceanview.filter;

import com.oceanview.util.Constants;
import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;

/**
 * Authentication Filter
 * Checks if user is logged in before accessing protected resources
 * URL Patterns: /admin/*, /staff/*, /guest/* (configured in web.xml)
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class AuthenticationFilter implements Filter {
    
    private static final Logger logger = LoggerFactory.getLogger(AuthenticationFilter.class);
    
    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        logger.info("AuthenticationFilter initialized");
    }
    
    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        HttpSession session = httpRequest.getSession(false);
        
        String requestURI = httpRequest.getRequestURI();
        
        // Check if user is logged in
        boolean isLoggedIn = (session != null && session.getAttribute(Constants.SESSION_USER) != null);
        
        if (isLoggedIn) {
            // User is authenticated, continue
            logger.debug("User authenticated for URI: {}", requestURI);
            chain.doFilter(request, response);
        } else {
            // User not authenticated, redirect to login
            logger.warn("Unauthorized access attempt to: {}", requestURI);
            
            // Store the original request URL to redirect after login
            session = httpRequest.getSession(true);
            session.setAttribute("redirectURL", requestURI);
            
            // Set error message
            session.setAttribute(Constants.ATTR_ERROR, Constants.MSG_SESSION_EXPIRED);
            
            // Redirect to login page
            String contextPath = httpRequest.getContextPath();
            httpResponse.sendRedirect(contextPath + "/login");
        }
    }
    
    @Override
    public void destroy() {
        logger.info("AuthenticationFilter destroyed");
    }
}
