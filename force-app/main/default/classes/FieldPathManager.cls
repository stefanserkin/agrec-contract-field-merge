/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 * 
 * @description Utilities for handling field paths in fields to merge
 * 
 * @date 2025
 * @author Asphalt Green Data and Information Systems
 ***********************************************************************/
public with sharing class FieldPathManager {
    
    /**
     * @description Normalizes a merge field path to standard format (lowercase)
     * @param fieldPath Raw field API path (e.g., 'Account.Owner.Name')
     * @return Normalized field path (e.g., 'account.owner.name')
     */
    public static String normalize(String fieldPath) {
        if (String.isBlank(fieldPath)) {
            return '';
        }
        return fieldPath.trim().toLowerCase();
    }

    /**
     * @description Validates whether a merge field path is syntactically safe
     *              (Allows alphanumeric, underscores, dots. No spaces, no special characters)
     * @param fieldPath Field path to validate
     * @return True if valid, False otherwise
     */
    public static Boolean isValid(String fieldPath) {
        if (String.isBlank(fieldPath)) {
            return false;
        }
        // Allow only letters, numbers, underscores, and dots
        Pattern validPattern = Pattern.compile('^[a-zA-Z0-9_.]+$');
        Matcher m = validPattern.matcher(fieldPath);
        return m.matches();
    }

}