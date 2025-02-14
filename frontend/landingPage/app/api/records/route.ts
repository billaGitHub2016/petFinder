import { NextResponse } from "next/server";

export async function GET(request: Request) {
    try {
        const query = request.url.split('?')[1];
        const res = await fetch(`${process.env.NEXT_PUBLIC_CMS_URL}/api/records?${query}`, {
            method: "GET",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${process.env.NEXT_PUBLIC_CMS_TOKEN}`
            }
        })
        const pets = await res.json()
        return NextResponse.json({ message: "ok", data: pets }, { status: 200 })
    } catch (error) {
        console.error("查询回访记录失败:", error)
        return NextResponse.json({ error: "查询回访记录失败" }, { status: 500 })
    }
}

