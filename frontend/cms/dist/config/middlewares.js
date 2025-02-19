"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
function default_1({ env }) {
    return [
        'strapi::logger',
        'strapi::errors',
        'strapi::cors',
        'strapi::poweredBy',
        'strapi::query',
        'strapi::body',
        'strapi::session',
        'strapi::favicon',
        'strapi::public',
        {
            name: "strapi::security",
            config: {
                contentSecurityPolicy: {
                    useDefaults: true,
                    directives: {
                        "connect-src": ["'self'", "https:"],
                        "img-src": [
                            "'self'",
                            "data:",
                            "blob:",
                            "market-assets.strapi.io",
                            env("CF_PUBLIC_ACCESS_URL") ? env("CF_PUBLIC_ACCESS_URL").replace(/^https?:\/\//, "") : "",
                        ],
                        "media-src": [
                            "'self'",
                            "data:",
                            "blob:",
                            "market-assets.strapi.io",
                            env("CF_PUBLIC_ACCESS_URL") ? env("CF_PUBLIC_ACCESS_URL").replace(/^https?:\/\//, "") : "",
                        ],
                        upgradeInsecureRequests: null,
                    },
                },
            },
        }
    ];
}
exports.default = default_1;
