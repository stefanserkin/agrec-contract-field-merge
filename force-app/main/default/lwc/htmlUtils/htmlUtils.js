/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 * 
 * @description
 * Utility functions for working with HTML in rich text merge templates.
 * 
 * @date 2025
 * @author
 * Asphalt Green Data and Information Systems
 ***********************************************************************/

export function unescapeAllowedHtml(content) {
    const whitelist = {
        '&lt;br&gt;': '<br>',
        '&lt;br/&gt;': '<br>',
        '&lt;br /&gt;': '<br>',
        '&lt;ul&gt;': '<ul>',
        '&lt;/ul&gt;': '</ul>',
        '&lt;li&gt;': '<li>',
        '&lt;/li&gt;': '</li>',
        '&lt;b&gt;': '<b>',
        '&lt;/b&gt;': '</b>',
        '&lt;i&gt;': '<i>',
        '&lt;/i&gt;': '</i>',
        '&lt;u&gt;': '<u>',
        '&lt;/u&gt;': '</u>',
        '&amp;bull;': '&bull;'
    };

    let output = content;
    for (const [escaped, tag] of Object.entries(whitelist)) {
        const regex = new RegExp(escaped, 'gi');
        output = output.replace(regex, tag);
    }

    return output;
}

export function normalizeHtml(input) {
    if (!input) return '';

    return input
        // Convert HTML entities to characters
        .replace(/&nbsp;/g, ' ')
        .replace(/\u00A0/g, ' ')
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&amp;/g, '&')
        .replace(/&quot;/g, '"')

        // Normalize whitespace and line breaks
        .replace(/<br\s*\/?>/gi, '<br>')
        .replace(/\s+/g, ' ')
        .trim();
}

export function convertHtmlForClipboard(input) {
    if (!input) return '';

    return input
        .replace(/&nbsp;/g, ' ')
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&amp;/g, '&')
        .replace(/&quot;/g, '"')
        .replace(/&bull;/gi, '•')
        .replace(/<br\s*\/?>/gi, '\n')
        .replace(/<\/?[^>]+(>|$)/g, '') // remove any remaining HTML tags
        .trim();
}

