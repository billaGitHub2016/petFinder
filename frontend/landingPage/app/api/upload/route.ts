import { NextResponse } from "next/server";
import { join } from "path";
import { writeFile } from "fs/promises";
import { createRouteHandlerClient } from "@supabase/auth-helpers-nextjs";
import { cookies } from "next/headers";

export async function POST(request: Request) {
    try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_CMS_URL}/api/upload`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${process.env.NEXT_PUBLIC_CMS_TOKEN}`
            },
            body: request.body
        })
        const data = await res.json()
        return NextResponse.json({ message: "ok", data }, { status: 200 })
    } catch (error) {
        console.error("上传文件失败:", error)
        return NextResponse.json({ error: "上传文件失败" }, { status: 500 })
    }
}
