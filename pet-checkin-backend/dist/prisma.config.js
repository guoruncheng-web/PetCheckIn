"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
require("dotenv/config");
const dotenv_1 = require("dotenv");
const config_1 = require("prisma/config");
(0, dotenv_1.config)({ path: `.env.${process.env.NODE_ENV || 'development'}` });
exports.default = (0, config_1.defineConfig)({
    schema: "prisma/schema.prisma",
    migrations: {
        path: "prisma/migrations",
    },
    datasource: {
        url: (0, config_1.env)("DATABASE_URL"),
    },
});
//# sourceMappingURL=prisma.config.js.map