import { NextResponse } from "next/server";
import { join } from "path";
import { writeFile } from "fs/promises";
import { createRouteHandlerClient } from "@supabase/auth-helpers-nextjs";
import { cookies } from "next/headers";

export async function GET(request: Request) {
    try {
        const res = await fetch(`${process.env.NEXT_PUBLIC_CMS_URL}/api/pets`, {
            method: "GET",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${process.env.NEXT_PUBLIC_CMS_TOKEN}`
            }
        })
        const pets = await res.json()

        console.log('pets = ', pets)

        return NextResponse.json({ message: "ok", data: pets }, { status: 200 })
    } catch (error) {
        console.error("查询任务详情失败:", error)
        return NextResponse.json({ error: "查询任务详情失败" }, { status: 500 })
    }
}
