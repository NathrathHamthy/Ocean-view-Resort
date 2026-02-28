package com.oceanview.filter;

import jakarta.servlet.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;

/**
 * Character Encoding Filter
 * Ensures UTF-8 encoding for all requests and responses
 * URL Pattern: /* (configured in web.xml)
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class CharacterEncodingFilter implements Filter {
    
    private static final Logger logger = LoggerFactory.getLogger(CharacterEncodingFilter.class);
    private String encoding = "UTF-8";
    
    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        String encodingParam = filterConfig.getInitParameter("encoding");
        if (encodingParam != null) {
            encoding = encodingParam;
        }
        logger.info("CharacterEncodingFilter initialized with encoding: {}", encoding);
    }
    
    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        
        // Set request encoding
        request.setCharacterEncoding(encoding);
        
        // Set response encoding
        response.setCharacterEncoding(encoding);
        response.setContentType("text/html; charset=" + encoding);
        
        // Continue the filter chain
        chain.doFilter(request, response);
    }
    
    @Override
    public void destroy() {
        logger.info("CharacterEncodingFilter destroyed");
    }
}
