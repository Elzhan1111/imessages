import express from "express";
import cors from "cors";
import cron from "node-cron";

import "dotenv/config";
import fs from "fs";
import path from "path";

import { clerkMiddleware } from '@clerk/express';
import User from "./models/User.js";
import { connectDB } from "./lib/db.js"; 

const app = express();
// Добавляем дефолтный порт на случай, если процесс не прочитал env
const PORT = process.env.PORT || 10000; 
const FRONTEND_URL = process.env.FRONTEND_URL;

const publicDir = path.join(process.cwd(), "public");

app.use(express.json());
app.use(cors({ origin: FRONTEND_URL, credentials: true }));
app.use(clerkMiddleware());

app.get("/health", (req, res) => {
    res.status(200).json({ ok: true });
});

if (fs.existsSync(publicDir)) {
    app.use(express.static(publicDir));

    // ИСПРАВЛЕНО: Изменен роутинг для SPA (Vite) и убрана опечатка в 'path'
    app.get("*", (req, res) => {
        res.sendFile(path.join(publicDir, "index.html"));
    });
}

// Было: app.listen(PORT, () => {
// Стало:
app.listen(PORT, "0.0.0.0", () => {
    connectDB();
    console.log("Server is up and running on PORT:", PORT);
    
    const job = cron.schedule("*/14 * * * *", () => {
        console.log("Пингуем сервер для предотвращения засыпания...");
    });

    if(process.env.NODE_ENV === "production") job.start();
});




// app.listen(PORT, () => {
//     connectDB();
//     console.log("Server is up and running on PORT:", PORT);
    
//     // ИСПРАВЛЕНО: Строка с неопределенным job полностью удалена
// });
