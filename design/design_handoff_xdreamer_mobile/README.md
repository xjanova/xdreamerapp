# Handoff: X-DREAMER Mobile (แอปมือถือสร้างผลงาน AI)

## Overview
แอปมือถือ (Android-first) สำหรับแพลตฟอร์ม **X-DREAMER** (repo: `xjanova/aixman`, live: https://ai.xman4289.com)
ครอบคลุม 10 หน้าจอ: ออนบอร์ด, เข้าสู่ระบบ, สตูดิโอสร้างงาน (5 โหมด), สถานะกำลังสร้าง, ผลลัพธ์,
ผลงานของฉัน, แกลเลอรีชุมชน, โปรไฟล์+เครดิต, แพ็กเกจเครดิต, ชวนเพื่อน (referral).

เป้าหมาย: ย้ายประสบการณ์ 3-column studio ของเว็บ (`/generate`) มาเป็น flow มือถือแบบแท็บ + bottom sheet
โดยคงอัตลักษณ์ X-DREAMER ทั้งหมด (near-black #030612, fiber-threads canvas, glass surfaces,
gradient emerald → cyan → violet, Inter + Noto Sans Thai).

## About the Design Files
ไฟล์ในชุดนี้เป็น **design reference ที่เขียนด้วย HTML** — เป็นต้นแบบที่แสดงหน้าตาและพฤติกรรมที่ต้องการ
**ไม่ใช่ production code ที่ให้ copy ไปวางตรง ๆ**

งานที่ต้องทำคือ **สร้างหน้าจอเหล่านี้ขึ้นใหม่ในสภาพแวดล้อมของ codebase เป้าหมาย** ตาม pattern ที่มีอยู่แล้ว:
- ถ้าทำเป็น **PWA / mobile web ใน repo `aixman` เดิม** → Next.js 16 App Router + React 19,
  inline-style primitives ตามแบบ `src/components/xdreamer/shared.tsx`, Zustand สำหรับ state,
  Framer Motion สำหรับ transition (มีใน `package.json` อยู่แล้ว)
- ถ้าทำเป็น **native app** → React Native / Expo หรือ Kotlin Compose แล้วแมป token ตามตารางด้านล่าง
- ถ้ายังไม่มีสภาพแวดล้อม → เลือก framework ที่เหมาะสมที่สุดแล้ว implement ตามสเปกนี้

โครงสร้างในต้นแบบ (parent showcase + child app + device bezel) เป็นเพียงวิธีจัดแสดง 10 หน้าจอพร้อมกัน
ในแอปจริงมีแค่ **app เดียวที่มี router** — ไม่ต้องทำ bezel หรือ showcase page

## Fidelity
**High-fidelity (hifi).** สี ตัวอักษร ระยะ เงา และ interaction เป็นค่าจริงที่ต้องการใช้ ให้ทำตามให้ตรง
ค่าตัวเลขทั้งหมดในเอกสารนี้คือค่าที่ใช้ในต้นแบบจริง (หน่วย px, viewport 412×812 dp)

ยกเว้น: **ไอคอน** ในต้นแบบใช้ glyph ตัวอักษร (`◈ ▧ ⬡ ◍ ✦ ◧ ▶ ⧉ ✎ ⤢ ♥ ↓ ↗ ↻`) ตามที่ repo เดิมใช้อยู่
ถ้า codebase มี Lucide (`lucide-react` อยู่ใน package.json แล้ว) ให้แทนด้วยไอคอนที่ความหมายตรงกัน
ขนาด 16–20px สี `#a5f3fc` / `#64748b`

---

## Design Tokens

> **อัปเดต (Metal edition):** พื้นผิวทั้งแอปเปลี่ยนจาก flat glass → **ชิ้นโลหะกลึง** ทุกองค์ประกอบมีมิติจริง
> (bevel ขอบบนสว่าง/ขอบล่างมืด, ปุ่มนูนกดยุบ, ช่องควบคุมเซาะร่องลึก, ตัวอักษรสลัก)
> ใช้ **recipe 5 ตัวด้านล่างเป็นแกน** แล้วค่อยอ่านสเปกรายหน้า — ที่ใดในเอกสารเขียนว่า glass / `rgba(15,23,42,0.55)` ให้ใช้ `PLATE` แทน
>
> ```
> /* PLATE — การ์ด/แผ่นโลหะ (แทน glass ทุกที่) */
> background: linear-gradient(158deg,#1a2237 0%,#0d1322 46%,#111a2b 100%);
> box-shadow: inset 0 1.5px 0 rgba(255,255,255,0.13),   /* highlight ขอบบน */
>             inset 0 -1.5px 0 rgba(0,0,0,0.70),        /* เงาขอบล่าง */
>             0 14px 28px -20px rgba(0,0,0,0.98);       /* เงาลอย */
> /* แผ่นสำคัญเพิ่มลายขัด: repeating-linear-gradient(112deg,rgba(255,255,255,.02) 0 1px,transparent 1px 3px) ทับเป็น layer แรก */
>
> /* SUNK — ช่องเซาะร่อง (prompt, กลุ่มปุ่ม aspect/batch, progress track, tab ที่ active) */
> background: linear-gradient(180deg,#05080f,#0a1120);
> box-shadow: inset 0 3px 7px rgba(0,0,0,0.90), 0 1px 0 rgba(255,255,255,0.07);
>
> /* KEYCAP — ปุ่มโลหะนูน (ปุ่มรอง, chip ไม่ active, action bar) */
> background: linear-gradient(180deg,#2a3550,#161e33 55%,#0f1626);
> box-shadow: inset 0 1px 0 rgba(255,255,255,0.20), inset 0 -1px 0 rgba(0,0,0,0.70),
>             0 5px 12px -7px rgba(0,0,0,0.95);
>
> /* ANODIZED — ตัวเลือกที่ active (ผิวอโนไดซ์สีฟ้า) */
> background: linear-gradient(180deg,#2c8f9e,#155c73 50%,#0d3d55);
> box-shadow: inset 0 1.5px 0 rgba(255,255,255,0.45), inset 0 -2px 7px rgba(0,0,0,0.45),
>             0 6px 16px -7px rgba(6,182,212,0.85);
>
> /* BRAND KNOB — ปุ่มหลัก / FAB (โลหะเคลือบสีแบรนด์) */
> background: linear-gradient(180deg,#34d399 0%,#0ea5b7 42%,#7c4ddb 100%);
> box-shadow: inset 0 2px 0 rgba(255,255,255,0.55), inset 0 -4px 10px rgba(0,0,0,0.42),
>             0 18px 36px -12px rgba(124,77,219,0.95), 0 3px 0 rgba(0,0,0,0.65);
>
> /* ENGRAVE — ตัวอักษรสลัก (ใช้กับ label, หัวข้อ, ตัวเลข) */
> text-shadow: 0 1px 0 rgba(0,0,0,0.90), 0 -1px 0 rgba(255,255,255,0.06);
>
> /* BEVEL RING — กรอบโลหะรอบรูป/ไอคอน: element นอก padding 1.5–3px
>    background: linear-gradient(160deg,rgba(255,255,255,0.34),rgba(120,140,175,0.10) 45%,rgba(0,0,0,0.85)) */
> ```
>
> **press state ใหม่:** ทุกปุ่มกดแล้ว **จม** — `transform: translateY(2–3px)` + สลับเป็น `box-shadow: inset 0 2–3px 6–8px rgba(0,0,0,0.55)` (ไม่ใช่ scale เหมือนเวอร์ชันแรก)
> **สีพื้น** ปรับเป็น `#05080f` / scrim `#04070e` เพื่อให้ขอบ bevel อ่านออกชัดขึ้น (เดิม `#030612`)
> ไฟล์ `XdrApp v1 flat.dc.html` คือเวอร์ชัน flat glass เดิม เก็บไว้เทียบเท่านั้น


### Colors (ดึงจาก `src/components/xdreamer/shared.tsx` และ landing ของ repo)
| Token | Value | ใช้ที่ |
|---|---|---|
| `bg/base` | `#030612` | พื้นหลังแอปทั้งหมด |
| `bg/page-desk` | `#05070f` | พื้นหลังหน้า showcase (ไม่ใช้ในแอป) |
| `surface/glass` | `rgba(15,23,42,0.55)` | การ์ด, panel (คู่กับ `backdrop-filter: blur(18px)`) |
| `surface/glass-strong` | `rgba(15,23,42,0.70)` | panel กำลังสร้าง, dropdown |
| `surface/sheet` | `rgba(11,16,32,0.97)` | bottom sheet |
| `surface/subtle` | `rgba(255,255,255,0.04)` | field, chip ไม่ active |
| `border/hairline` | `rgba(255,255,255,0.08)` | ขอบการ์ดมาตรฐาน |
| `border/strong` | `rgba(255,255,255,0.14)` | ปุ่ม ghost |
| `border/accent` | `rgba(165,243,252,0.40)` | chip/field ที่ active |
| `text/primary` | `#ffffff` | หัวข้อ |
| `text/body` | `#e2e8f0` | เนื้อความ |
| `text/muted` | `#94a3b8` | label, meta |
| `text/dim` | `#64748b` | ตัวเลขรอง, chevron |
| `accent/emerald` | `#10b981` | จุดเริ่ม gradient, stat WORKS |
| `accent/cyan` | `#06b6d4` | กลาง gradient, stat USED |
| `accent/violet` | `#8b5cf6` | ปลาย gradient, stat BONUS, glow |
| `accent/ice` | `#a5f3fc` | สีตัวอักษร accent, ค่าที่ active, เครดิต |
| `accent/lilac` | `#c4b5fd` | ตัวเอียง gradient, badge |
| `accent/mint` | `#6ee7b7` | โบนัส, สถานะสำเร็จ |
| `accent/danger` | `#fca5a5` | ออกจากระบบ, ยอดไลก์ |
| `gradient/brand` | `linear-gradient(135deg,#10b981 0%,#06b6d4 50%,#8b5cf6 100%)` | ปุ่มหลัก, FAB, avatar ring |
| `gradient/text` | `linear-gradient(100deg,#a5f3fc,#c4b5fd)` | ตัวเอียงเน้น (background-clip:text) |
| `gradient/active-chip` | `linear-gradient(135deg,rgba(16,185,129,0.20),rgba(139,92,246,0.28))` | chip โหมดที่เลือก |

### Typography
- **Latin / ตัวเลข:** Inter — weights 200,300,400,500,600,700,800,900
- **ไทย:** Noto Sans Thai — weights 200–700
- font stack: `'Noto Sans Thai','Inter',system-ui,sans-serif` (ไทยมาก่อนเพื่อให้ glyph ไทยถูกต้อง; ใน repo ใช้ `next/font/google` CSS variable — ให้ทำแบบเดียวกัน)
- scale ที่ใช้จริง:

| Role | Size / Weight / LS | หมายเหตุ |
|---|---|---|
| Hero (onboard) | 33px / 300 / -0.01em / line-height 1.28 | ตัวเอียงเน้น weight 200 + gradient text |
| Page title | 21–26px / 300–400 | เช่น "ผลงานของฉัน", "เติมเครดิต" |
| Card title | 14–16px / 500–600 | |
| Body | 13–14.5px / 400 / line-height 1.6 | prompt ใช้ 14.5px/1.62 |
| Label (uppercase) | 10–11px / 400–600 / letter-spacing 0.14em | Inter, สี `#94a3b8` หรือ `#a5f3fc` |
| Brand wordmark | 11–15px / 900 / letter-spacing 0.20–0.26em | Inter, uppercase "X-DREAMER" |
| Tab label | 9.5px / 400 | |
| Stat value | 20–26px / 700 | Inter + `text-shadow: 0 0 22px <color>55` |
| ราคา | 21px / 700 · เครดิต 26px / 200 | Inter |

### Spacing / Radius / Shadow
- spacing scale: 4, 6, 8, 10, 11, 13, 14, 16, 18, 22, 26 (px) — screen padding มาตรฐาน **14px** ซ้าย/ขวา
- radius: chip 999 (pill) · ปุ่มเล็ก/field 11–14 · การ์ด 16–18 · panel 20–22 · sheet `26px 26px 0 0` · FAB 20 · logo tile 9/19/22/26
- shadow:
  - ปุ่มหลัก `0 20px 44px -16px rgba(139,92,246,0.90)`
  - FAB `0 14px 34px -10px rgba(139,92,246,0.95), inset 0 1px 0 rgba(255,255,255,0.35)`
  - การ์ด popular `0 24px 56px -28px rgba(139,92,246,0.95)`
  - โลโก้ `0 0 42px rgba(139,92,246,0.50)`
  - glass panel กำลังสร้าง `0 0 44px -14px rgba(139,92,246,0.60)`
- hit target: ทุกปุ่ม/แท็บ ≥ 44px

### Background system (ทุกหน้าจอ)
ซ้อน 3 ชั้นที่ root ของแอป:
1. `#030612` สีพื้น
2. `<canvas>` fiber-threads (absolute inset:0, `opacity:0.5`, `pointer-events:none`)
3. overlay `radial-gradient(ellipse at 50% 22%, rgba(3,6,18,0.35) 0%, rgba(3,6,18,0.82) 58%, rgba(3,6,18,0.96) 100%)`

**Fiber-threads spec** (ย่อจาก `FiberThreads` ใน repo เพื่อประสิทธิภาพบนมือถือ):
- 16 เส้น bezier, palette HSL `[160,85,55] [180,80,60] [210,90,65] [250,75,68] [275,70,65] [295,65,68]` **+ hueShift 70°**
- แต่ละเส้นสุ่ม: จุดต้น/ปลาย/control 2 จุด, ความถี่ f1 0.0004–0.0012 / f2 0.0003–0.0010 / f3 0.0002–0.0008, phase 0–2π, ความหนา 0.3–1.6px, alpha 0.25–0.75
- ต่อเฟรม: เติม `rgba(3,6,18,0.09)` ทับ (trail) → `globalCompositeOperation='lighter'` → วาดทุกเส้นด้วย linear gradient 5 stop (โปร่งใส → alpha×0.5 → alpha×0.55 ที่ hue+20 → alpha×0.5 → โปร่งใส)
- จุด control ขยับ ±120px, จุดปลาย ±70px ตาม sin/cos ของ f1..f3
- **cap 26fps, DPR cap 1.5, หยุดวาดเมื่อไม่อยู่ใน viewport (IntersectionObserver)** — สำคัญกับแบตมือถือ
- ไม่ต้องมี mouse-interaction บนมือถือ (เวอร์ชันเว็บมี)
- ถ้า framework ไม่มี canvas ที่ถูก (เช่น native) ให้ใช้ภาพนิ่ง/Skia shader แทน แต่ต้องคุมความสว่างระดับเดียวกัน

### Animations (keyframes ที่ใช้)
| ชื่อ | นิยาม | ใช้ที่ |
|---|---|---|
| `xdrUp` | opacity 0→1, translateY 14px→0 · **420ms cubic-bezier(.16,1,.3,1)** | เข้าหน้าจอทุกหน้า |
| `xdrSheet` | translateY 100%→0 · 320ms cubic-bezier(.16,1,.3,1) | bottom sheet |
| `xdrSpin` | rotate 0→360° · 1.5s linear infinite | วงแหวน conic-gradient ตอนกำลังสร้าง |
| `xdrShim` | background-position 130%→-130% · 1.5s linear infinite (stagger 0/.2/.4/.6s) | skeleton 4 ช่อง |
| `xdrSheen` | left -45%→135% · 3s ease-in-out infinite | แถบแสงวิ่งบนปุ่มหลัก |
| `xdrPulse` | opacity .45→.9, scale 1→1.12 · 2.4s ease-in-out infinite | halo หลัง FAB |
| `xdrFloat` | translateY 0→-10px · 6s ease-in-out infinite | โลโก้หน้าออนบอร์ด |
| `xdrBlink` | opacity 1/0 · 1.1s steps(1) infinite | caret ท้าย prompt |
| press state | `transform: scale(0.92–0.975)` ตอน `:active` | ทุกปุ่ม/การ์ดที่กดได้ |

---

## Navigation

**Bottom tab bar + center FAB** (ผู้ใช้เลือกโครงนี้)
- container: height 64px, `padding-bottom:2px`, `background:rgba(3,6,18,0.88)`, `backdrop-filter:blur(20px) saturate(1.3)`, `border-top:1px solid rgba(255,255,255,0.07)`, `display:grid; grid-template-columns:repeat(5,1fr)`
- 4 แท็บ: **สตูดิโอ** `◈` /studio · **ผลงาน** `▧` /works · (ช่องกลางว่างไว้ให้ FAB) · **ชุมชน** `⬡` /community · **โปรไฟล์** `◍` /profile
- แท็บ active: สี `#a5f3fc` + `text-shadow:0 0 14px rgba(165,243,252,0.6)`; ไม่ active `#64748b`
- **FAB**: 58×58, radius 20, `gradient/brand`, glyph `✦` 23px, absolute `top:-24px; left:50%` — มี halo `radial-gradient(circle,rgba(139,92,246,0.45),transparent 70%)` inset -8px วน `xdrPulse`
- FAB → เปิด bottom sheet "สร้างผลงานใหม่" (grid 2 คอลัมน์ 5 โหมด) → เลือกโหมดแล้วไปหน้าสตูดิโอพร้อม mode นั้น
- Pricing และ Referral **ไม่อยู่ใน tab bar** — เข้าจากโปรไฟล์ (เมนู) และจาก credit pill บน top bar
- Onboard / Login **ไม่มี** top bar และ tab bar

**Top bar (ทุกหน้าที่ล็อกอินแล้ว)**
height ~48px, `padding:10px 14px 8px`, `background:linear-gradient(180deg,rgba(3,6,18,0.85),rgba(3,6,18,0.15))`, blur 16px, `border-bottom:1px solid rgba(255,255,255,0.06)`
เนื้อหา: โลโก้ 30×30 radius 9 (glow violet 18px) · wordmark "X-DREAMER" 11px/900/0.20em · spacer ·
credit pill `✦ 1,280` (padding 5/11, radius 999, bg `rgba(165,243,252,0.08)`, border `rgba(165,243,252,0.22)`, สี `#a5f3fc`, 11.5px/600 → ไป pricing) · avatar 32px วงกลม `conic-gradient(from 180deg,#10b981,#06b6d4,#8b5cf6,#10b981)` + อักษรแรก 12px/800 สี `#030612`

---

## Screens / Views

### 01 · Onboarding (`route: onboard`)
**Purpose:** ขายไอเดียใน 3 วินาที แล้วพาไป login
**Layout:** full-bleed `hero-reel.jpg` (`opacity:0.55`) + scrim `linear-gradient(180deg,rgba(3,6,18,0.35) 0%,rgba(3,6,18,0.75) 45%,#030612 88%)`; เนื้อหา anchor ล่าง `padding:0 26px 34px; gap:18px`
**Components**
- โลโก้ 96×96 radius 26, `box-shadow:0 24px 60px -18px rgba(139,92,246,0.75), 0 0 0 1px rgba(255,255,255,0.09)`, `xdrFloat`
- wordmark "X-DREAMER" 15px/900/0.24em, margin-bottom 14
- headline 33px/300: "ทอความฝันจาก" + บรรทัดใหม่ "เส้นใยแห่งความคิด" (weight 200, italic, gradient text)
- sub 13px/1.6 `rgba(226,232,240,0.66)`: "Weave your dreams from threads of thought. 9 providers · 40+ models · image, video, edit, upscale."
- pager dots: active 22×3 `linear-gradient(90deg,#06b6d4,#8b5cf6)` · inactive 7×3 `rgba(255,255,255,0.2)` (3 หน้า)
- CTA หลัก: padding 16, radius 16, `gradient/brand`, 15px/700, shadow `0 18px 40px -14px rgba(139,92,246,0.85)`, มีแถบ `xdrSheen` — ข้อความ "เริ่มสร้างฟรี · Start free"
- CTA รอง: padding 15, radius 16, border `rgba(255,255,255,0.14)`, 14px — "มีบัญชีแล้ว · Sign in"

### 02 · Login (`route: login`)
**Purpose:** เข้าสู่ระบบด้วยบัญชีเดียวกับ xman4289.com (NextAuth credentials)
**Layout:** จัดกลาง `padding:28px 22px 40px; gap:18px`; พื้นหลัง `login-panel.jpg` `opacity:0.28` + `radial-gradient(ellipse at 50% 40%,rgba(3,6,18,0.55),#030612 78%)`
**Components**
- โลโก้ 64×64 radius 19 + wordmark 12px/900/0.22em
- glass card: `padding:22px 20px 20px`, radius 22, `rgba(15,23,42,0.62)`, blur 22, border `rgba(255,255,255,0.09)`, shadow `0 30px 70px -30px rgba(0,0,0,0.9)`, gap 14
  - หัวข้อ "เข้าสู่ระบบ" 19px/500 + sub 12px `#94a3b8` "ใช้บัญชีเดียวกับ xman4289.com"
  - field: label uppercase 11px/0.08em `#94a3b8` + input `padding:14px`, radius 13, bg `rgba(255,255,255,0.04)`, border `rgba(255,255,255,0.10)`, 14px
  - **focus state:** border `rgba(6,182,212,0.35)` + `box-shadow:0 0 0 3px rgba(6,182,212,0.09)`
  - password มีลิงก์ "แสดง" 11px `#a5f3fc` ชิดขวา, ค่า mask `letter-spacing:0.22em`
  - ปุ่มหลัก padding 15 radius 14 `gradient/brand` 15px/700
  - divider "หรือ" — เส้น `rgba(255,255,255,0.08)` สองข้าง, ตัวอักษร 11px
  - ปุ่ม ghost "ดำเนินการต่อด้วย XMAN Studio"
- ท้าย: "ยังไม่มีบัญชี? **สมัครฟรี รับ 50 เครดิต**" (ส่วนหลังสี `#a5f3fc`)
**Validation:** email format + password ≥ 8; error ใต้ field 11px `#fca5a5`, border field เปลี่ยนเป็น `rgba(252,165,165,0.45)`

### 03 · Studio (`route: studio`, `phase: idle`) — หน้าหลัก
**Purpose:** ตั้ง prompt + พารามิเตอร์ แล้วสั่งสร้าง
**Layout:** column `padding:14px 14px 20px; gap:14px`, `xdrUp` ตอนเข้า, scroll ในตัว
**Components (บนลงล่าง)**
1. **Mode rail** — แถวเลื่อนแนวนอน (bleed ออกขอบ: `margin:0 -14px; padding:0 14px`), gap 7
   - 5 โหมด: `◧ ภาพ / TEXT → IMAGE / 12✦` · `▶ วิดีโอ / TEXT → VIDEO / 65✦` · `⧉ ภาพ → วิดีโอ / IMAGE → VIDEO / 80✦` · `✎ แก้ไขภาพ / EDIT / INPAINT / 18✦` · `⤢ อัปสเกล / UPSCALE 4K / 6✦`
   - chip: `padding:9px 13px`, radius 14, gap 8, ไอคอน 13px, ชื่อไทย 12.5px/600, EN 9px/0.06em opacity .6
   - **active:** `gradient/active-chip` + border `rgba(165,243,252,0.42)` + สี `#fff` + shadow `0 8px 22px -10px rgba(139,92,246,0.9)`
   - **inactive:** bg `rgba(15,23,42,0.55)`, border hairline, สี `#94a3b8`
2. **Prompt card** — radius 20, glass, blur 18, `padding:15px; gap:11px`
   - หัว: "PROMPT" 10.5px/0.14em `#a5f3fc` — ขวา ตัวนับ `148/2000` 10.5px `#64748b`
   - ข้อความ 14.5px/1.62 `#e2e8f0`, min-height 72px + caret 2×15px `#a5f3fc` วน `xdrBlink`
   - copy ตัวอย่างที่ใช้: `แสงนีออนสีม่วงสาดผ่านสายฝนในซอยเยาวราช ยามค่ำคืน — cinematic wide shot, 85mm, volumetric light, reflective wet asphalt`
   - ปุ่มเล็ก 2 อัน: `✦ ปรับ prompt ด้วย AI` (bg `rgba(139,92,246,0.14)`, border `rgba(139,92,246,0.32)`, สี `#c4b5fd`) และ `▣ อ้างอิงภาพ` (subtle) — ทั้งคู่ 11.5px, radius 11, padding 8/12
3. **Model row** (กดเพื่อเปิด model picker) — radius 18, glass, `padding:13px 15px`, gap 12
   - tile 38×38 radius 12 `linear-gradient(135deg,rgba(16,185,129,0.25),rgba(139,92,246,0.30))` + `◈` 15px `#a5f3fc`
   - ชื่อโมเดล 13.5px/600 · provider + เวลา 10.5px `#94a3b8`
   - badge ราคา `{cost} ✦` = ราคาโหมด × batch (pill สี ice) · chevron `›` `#64748b`
   - แมปโหมด → โมเดล: t2i `Seedream 5.0 / BytePlus / ~8s` · t2v `Seedance 2.0 / BytePlus / ~40s` · i2v `Kling 2.5 Pro / Kling AI / ~60s` · edit `Stable Image Ultra / Stability AI / ~10s` · up `Creative Upscaler / fal.ai / ~15s`
4. **Style presets** — label "STYLE PRESET" + pill rail เลื่อนได้: Photorealistic, Cinematic(default), Anime, Cyberpunk, Oil painting, 3D Isometric (ของจริงมี 15 ตัวจาก `ai_styles`)
   - pill active: bg `rgba(165,243,252,0.13)`, border `rgba(165,243,252,0.40)`, สี `#a5f3fc`, 600
5. **Aspect + Batch** — สองการ์ดข้างกัน (flex:1 / gap 11 / radius 18 / padding 13)
   - Aspect: 4 ตัวเลือก 1:1, 3:4, 9:16, 16:9 — แต่ละอันมีสี่เหลี่ยมสัดส่วนจริง (16×16 / 13×17 / 10×18 / 20×11, border 1.5px) + ป้าย 9px
   - Batch: 1–4 (default 4) — ปุ่ม flex:1 radius 11 13px/600
   - active: bg `rgba(165,243,252,0.12)`, border `rgba(165,243,252,0.40)`, สี `#a5f3fc`
6. **ปุ่มสร้าง** — padding 17, radius 18, `gradient/brand`, 15.5px/700, shadow `0 20px 44px -16px rgba(139,92,246,0.9)`, `xdrSheen` — "✦ สร้างผลงาน · Generate"

### 04 · Generating (`phase: generating`)
แทนที่ปุ่มสร้างด้วย panel: radius 22, `rgba(15,23,42,0.70)`, blur 20, border `rgba(139,92,246,0.28)`, glow `0 0 44px -14px rgba(139,92,246,0.6)`, `xdrUp`
- วงแหวน 52×52: `conic-gradient(from 0deg,#10b981,#06b6d4,#8b5cf6,#10b981)` หมุน `xdrSpin`; วงในทึบ 42px `#0b1020` + `{pct}%` 12px/700 `#a5f3fc`
- ข้อความ "กำลังทอความฝัน…" 14px + "Weaving 4 frames · Seedream 5.0" 11px `#94a3b8`
- ปุ่ม "ยกเลิก" ghost 11.5px → กลับ `phase: idle`, refund เครดิต (repo มี auto-refund on failure)
- skeleton grid 2×2 (aspect 1:1, radius 14) — `linear-gradient(100deg,rgba(255,255,255,0.03) 30%,rgba(165,243,252,0.13) 50%,rgba(255,255,255,0.03) 70%)`, `background-size:220% 100%`, `xdrShim` stagger 0/.2/.4/.6s
- ของจริงต่อกับ polling `GET /api/generate?id=` (repo มี async generation + real-time polling)

### 05 · Result (`phase: result`)
- หัว "ผลลัพธ์ · 4 frames · 12s" + ลิงก์ "ล้าง" 11.5px `#a5f3fc`
- ภาพหลัก aspect 1:1 radius 20 border hairline shadow `0 26px 60px -26px rgba(139,92,246,0.7)`; overlay ซ้ายบน badge "2048 × 2048" (10px/0.08em, bg `rgba(3,6,18,0.65)` blur 8, border ice)
- thumbnail 4 ช่อง (grid 4 คอลัมน์ gap 8, aspect 1:1, radius 11) — ตัวที่เลือก border 1.5px `#a5f3fc` + `box-shadow:0 0 16px rgba(165,243,252,0.35)`
- action bar 5 ปุ่ม (grid 5 คอลัมน์ gap 8): `↓ ดาวน์โหลด` `♥ บันทึก` `↗ แชร์` `⤢ อัปสเกล` `↻ สร้างใหม่` — แต่ละปุ่ม column, gap 5, `padding:11px 2px`, radius 14, glass, ไอคอน 15px, label 9.5px
- "สร้างใหม่" = เรียก generate ซ้ำด้วยพารามิเตอร์เดิม · "อัปสเกล" = `POST /api/upscale`

### 06 · My works (`route: works`)
- หัว "ผลงานของฉัน" 21px/400 + "248 items" 11px `#94a3b8`
- filter pill rail: ทั้งหมด / ภาพ / วิดีโอ / ที่ชื่นชอบ / อัปสเกลแล้ว
- grid 2 คอลัมน์ gap 10, การ์ด radius 16 border hairline; รูปสูงสลับ 146–196px (ให้จังหวะแบบ masonry); press `scale(0.975)`
- overlay ล่างการ์ด: `padding:22px 10px 9px`, `linear-gradient(180deg,transparent,rgba(3,6,18,0.9))` — ชื่อ 11px ตัดด้วย ellipsis + badge kind (IMAGE/VIDEO/4K, 9px/0.06em, bg `rgba(165,243,252,0.12)`, สี ice) + เวลา 9.5px `#94a3b8`
- ท้าย: ปุ่ม ghost "โหลดเพิ่ม · Load more" (paginated load-more เหมือน `/gallery` ของเว็บ)

### 07 · Community (`route: community`)
- แท็บบน: ยอดนิยม (active) / ล่าสุด / ติดตาม — 13.5px, active `#fff` 600 + ขีดใต้ 2px `linear-gradient(90deg,#06b6d4,#8b5cf6)`, เส้นคั่น hairline
- การ์ดเด่น: รูปสูง 210px radius 20; scrim `linear-gradient(180deg,transparent 35%,rgba(3,6,18,0.92))`; badge "✦ ผลงานเด่นวันนี้" (bg `rgba(139,92,246,0.28)` blur 8, border `rgba(196,181,253,0.35)`, สี `#ddd6fe`); ชื่อเรื่อง 14.5px/500; แถวผู้สร้าง: จุด 22px conic-gradient + `@handle` 11px + `♥ 2.4k` `#fca5a5` + `↻ 318` `#94a3b8`
- masonry จริง: `columns:2; column-gap:10px` + `break-inside:avoid; margin-bottom:10px` (เว็บใช้ 4→3→2 คอลัมน์; มือถือ 2)
- การ์ดย่อย: รูป 140–200px, overlay ล่างมี avatar 16px + handle 10px + ยอดไลก์ 10px

### 08 · Profile (`route: profile`)
- banner `profile-banner.jpg` สูง 132px `opacity:0.75` + `linear-gradient(180deg,rgba(3,6,18,0.15),#030612)`
- เนื้อหา `margin-top:-42px; padding:0 14px 20px; gap:14px`
- avatar 78×78 radius 24: padding 2px `conic-gradient(from 200deg,#10b981,#06b6d4,#8b5cf6,#10b981)` ครอบวงใน radius 22 `#0b1020` + อักษร 28px/800 `#a5f3fc`; shadow `0 14px 36px -12px rgba(139,92,246,0.8)`
- ชื่อ 18px/500 + `@handle · Creator plan` 11.5px `#94a3b8` + ปุ่ม "แก้ไข" pill border ice
- **stat cards** grid 2×2 gap 10 (radius 18, glass, `inset 0 1px 0 rgba(255,255,255,0.04)`): CREDITS 1,280 (ice) · WORKS 248 (emerald) · USED 3,420 (cyan) · BONUS 150 (violet) — ค่า 24px/700 + `text-shadow:0 0 22px <สี>55`, label 10px/0.12em, sub 10.5px
- **credit usage:** "เครดิตที่ใช้เดือนนี้" + `720 / 2,000` ice; bar height 8 radius 999 bg `rgba(255,255,255,0.06)`, fill 36% `linear-gradient(90deg,#10b981,#06b6d4,#8b5cf6)` + `box-shadow:0 0 16px rgba(6,182,212,0.7)`; ปุ่ม "เติมเครดิต · Top up"
- **เมนู** (การ์ดเดียว radius 20, รายการ `padding:14px 15px`, เส้นคั่น `rgba(255,255,255,0.05)`, press bg `rgba(255,255,255,0.04)`):
  `✦ แพ็กเกจเครดิต → Creator` · `♢ ชวนเพื่อน · Referral → +150 ✦` · `▧ ผลงานที่บันทึกไว้ → 32` · `◈ ประวัติธุรกรรม` · `⎋ ออกจากระบบ` (ไอคอน 18px ice, label 13.5px, hint 11px dim, chevron `›`)

### 09 · Pricing (`route: pricing`)
- hero `pricing-hero.jpg` `opacity:0.30` + scrim; หัว "เติมเครดิต" 26px/300 + sub "จ่ายครั้งเดียว ใช้ได้ทุกโมเดล ไม่มีรายเดือน"
- **currency toggle** THB/USD: แคปซูล padding 3 radius 999 bg `rgba(255,255,255,0.06)`; ตัวเลือก active `linear-gradient(135deg,#a5f3fc,#c4b5fd)` + ตัวอักษร `#030612` 12px/600
- **tier cards** (radius 22, padding 17, gap 11):
  | Tier | THB | USD | เครดิต | โบนัส | perks |
  |---|---|---|---|---|---|
  | Starter | ฿149 | $4.5 | 500 | — | ทุกโมเดลภาพ · ความละเอียด 2K · เก็บผลงาน 90 วัน |
  | **Creator (ยอดนิยม)** | ฿590 | $17 | 2,500 | +250 | ทุกโมเดล ภาพ+วิดีโอ · 4K upscale · คิวลัดเวลาเร่งด่วน · เก็บผลงานถาวร |
  | Studio | ฿1,890 | $54 | 9,000 | +1,500 | สิทธิ์ใช้เชิงพาณิชย์ · API access · ทีมสูงสุด 5 คน |
  - popular: bg `linear-gradient(150deg,rgba(16,185,129,0.12),rgba(139,92,246,0.20))`, border `rgba(165,243,252,0.38)`, shadow popular, badge "ยอดนิยม" (`gradient/text` bg + `#030612` 9.5px/700/0.1em), CTA `gradient/brand` "✦ เติมเลย"
  - อื่น ๆ: glass + CTA ghost "เลือกแพ็กเกจนี้"
  - เลย์เอาต์ในการ์ด: ชื่อ+badge / desc 11.5px ซ้าย — ราคา 21px/700 + "ครั้งเดียว" 10px ขวา; บรรทัดถัดมา เครดิต 26px/200 ice + "เครดิต" 12px + โบนัส 11px `#6ee7b7`; hairline; perks chips 11px radius 9 bg `rgba(255,255,255,0.05)`
- **ตารางราคาต่อการสร้าง** (label "ราคาต่อการสร้าง"): Seedream 5.0 image 12 · FLUX 1.1 Pro image 15 · Seedance 2.0 video 5s 65 · Kling 2.5 Pro video 5s 80 · Creative Upscaler 4K 6 — แถว `padding:7px 0` + เส้น `rgba(255,255,255,0.04)`
- **สำคัญ:** CTA ของ tier แบบจ่ายเงินต้อง redirect ไป `https://xman4289.com/checkout/ai-credits/{slug}?ref=ai` แล้วรอ webhook `POST /api/webhooks/xman-credit` มาเติมเครดิต (ดู README ของ repo)

### 10 · Referral (`route: referral`)
- hero `referral-art.jpg` `opacity:0.34`; หัว "ชวนเพื่อน รับเครดิต" 25px/300 + sub "เพื่อนได้ 50 เครดิต คุณได้ 100 เครดิตเมื่อเพื่อนสร้างผลงานแรก"
- **code card:** radius 22, `linear-gradient(135deg,rgba(16,185,129,0.14),rgba(139,92,246,0.20))`, border `rgba(255,255,255,0.12)`, shadow `0 22px 50px -26px rgba(139,92,246,0.9)`
  - "YOUR CODE" 10.5px/0.14em ice; โค้ด 26px/800/0.12em `#fff` (เช่น `NARA-4289`); ปุ่ม "คัดลอก" → เปลี่ยนเป็น "คัดลอกแล้ว" 1.6s (bg `rgba(16,185,129,0.22)`, border `rgba(110,231,183,0.5)`, สี `#6ee7b7`)
  - ปุ่มคู่ "แชร์ลิงก์" / "QR code" (bg `rgba(3,6,18,0.45)`, radius 12) — ใช้ Web Share API บนมือถือ
- stat 3 ช่อง (grid 3 gap 9, radius 16): 12 เพื่อนที่ชวน · 8 สร้างงานแล้ว · 800 เครดิตที่ได้ (ค่า 20px/700)
- "วิธีการทำงาน" 3 ขั้น: หมายเลข 30×30 radius 11 gradient `#6ee7b7→#a5f3fc` / `#67e8f9→#a5f3fc` / `#c4b5fd→#a5f3fc` + glow 22px, ตัวเลข `#030612` 13px/700
  1. แชร์โค้ดของคุณ — ส่งลิงก์หรือ QR ให้เพื่อนผ่านแอปไหนก็ได้
  2. เพื่อนสมัครและใส่โค้ด — เพื่อนรับ 50 เครดิตทันทีที่สมัคร
  3. คุณได้ 100 เครดิต — เข้าบัญชีอัตโนมัติเมื่อเพื่อนสร้างผลงานแรก

---

## Interactions & Behavior
- **นำทาง:** แตะแท็บ → เปลี่ยน route + รีเซ็ต scroll ไปบนสุด + `xdrUp` 420ms
- **FAB:** แตะ → bottom sheet ขึ้นจากล่าง 320ms; แตะ backdrop (`rgba(3,6,18,0.72)` + blur 6) เพื่อปิด; เลือกโหมด → ปิด sheet + ไป studio + set mode + `phase: idle`
- **สร้างผลงาน:** แตะปุ่ม → `phase: generating`, pct เดินขึ้นทีละ 4–11 ทุก ~110ms (ต้นแบบ; ของจริงใช้ค่าจาก polling) → ถึง 100 → `phase: result`
- **เลือก thumbnail** → เปลี่ยนภาพหลัก (ring ice ย้ายตาม)
- **ยกเลิก** → กลับ idle, pct 0
- **คัดลอกโค้ด** → feedback 1.6s แล้วกลับสภาพเดิม
- **press feedback:** ทุกองค์ประกอบที่กดได้ `scale(0.92–0.975)` ทันที (transition ~120ms)
- **empty state:** ผลงาน/แกลเลอรีว่าง ใช้ภาพ `gallery-empty.jpg` ใน repo + ข้อความชวนไปสตูดิโอ
- **error state:** สร้างไม่สำเร็จ → toast/panel border `rgba(252,165,165,0.4)` + ข้อความ `#fca5a5` + ปุ่มลองใหม่; เครดิตคืนอัตโนมัติ
- **การเลื่อน:** ซ่อน scrollbar (`scrollbar-width:none` + `::-webkit-scrollbar{width:0}`) — top bar และ tab bar ตรึงอยู่ ไม่เลื่อนตาม
- **ประสิทธิภาพ:** canvas 26fps + หยุดเมื่อไม่เห็นจอ; ถ้าอุปกรณ์ตั้ง `prefers-reduced-motion` ให้ปิด xdrSheen / xdrPulse / xdrFloat และหยุด canvas (แสดงเฟรมนิ่ง)

## State Management
State ที่ต้องมี (ในต้นแบบเป็น state เดียวของแอป; ในของจริงแนะนำ Zustand ตาม `src/lib/store`):
| State | ค่า | เปลี่ยนเมื่อ |
|---|---|---|
| `route` | onboard · login · studio · works · community · profile · pricing · referral | แตะแท็บ/เมนู/CTA |
| `phase` | idle · generating · result | กดสร้าง / เสร็จ / ยกเลิก / ล้าง |
| `mode` | t2i · t2v · i2v · edit · up | mode rail หรือ sheet |
| `styleId` | 1 ใน 15 style presets | แตะ pill |
| `aspect` | 1:1 · 3:4 · 9:16 · 16:9 | แตะตัวเลือก |
| `batch` | 1–4 (default 4) | แตะตัวเลข |
| `pct` | 0–100 | polling สถานะงาน |
| `sheetOpen` | boolean | FAB / backdrop |
| `filter` | all · img · vid · fav · up | filter rail |
| `cur` | THB · USD | toggle |
| `selectedFrame` | url ของภาพที่เลือก | แตะ thumbnail |
| `copied` | boolean (auto-reset 1.6s) | ปุ่มคัดลอก |

**Data fetching (endpoint ที่มีอยู่แล้วใน repo):**
`GET /api/credits` (ยอดเครดิตบน top bar) · `GET /api/models` · `GET /api/styles` · `GET /api/packages` ·
`POST /api/generate` + poll สถานะ · `GET /api/gallery?filter=&page=` · `POST /api/favorites` ·
`POST /api/upscale` · `GET|POST /api/referral` · auth ผ่าน NextAuth v5 (credentials)

## Assets
ทั้งหมดมาจาก repo `xjanova/aixman` (branch `main`) — อยู่ในโฟลเดอร์ `assets/` ของชุดนี้
| ไฟล์ | ที่มาใน repo | ใช้ที่ |
|---|---|---|
| `logo.webp` | `public/logo.webp` | โลโก้ทุกที่ (repo มี `xdreamer-logo.png` 4.3MB เป็นต้นฉบับความละเอียดสูง — ใช้ตัวนั้นถ้าต้องการ) |
| `showcase/hero-reel.jpg` | `public/showcase/hero-reel.jpg` | ออนบอร์ด |
| `showcase/login-panel.jpg` | เดียวกัน | หน้าเข้าสู่ระบบ |
| `showcase/profile-banner.jpg` | เดียวกัน | banner โปรไฟล์ |
| `showcase/pricing-hero.jpg` | เดียวกัน | hero pricing |
| `showcase/referral-art.jpg` | เดียวกัน | hero referral |
| `showcase/city.jpg` `anime.jpg` `creature.jpg` `portrait.jpg` `dancer.jpg` `macro.jpg` `product.jpg` | เดียวกัน | ผลลัพธ์, ผลงานของฉัน, แกลเลอรีชุมชน |

ในของจริง รูปในแกลเลอรีมาจาก DB (`ai_generations`) ผ่าน S3/`@aws-sdk/client-s3` — ภาพชุดนี้ใช้เป็น placeholder เท่านั้น
โลโก้/แบรนด์ X-DREAMER เป็นของ XMAN Studio (private, all rights reserved) — ใช้ภายในโปรเจกต์นี้เท่านั้น

## Files (ในชุดนี้)
| ไฟล์ | เนื้อหา |
|---|---|
| `X-DREAMER Mobile.dc.html` | หน้า showcase — โทเคนสี + เครื่อง Android 10 เครื่อง (เปิดในเบราว์เซอร์ได้เลย) |
| `XdrApp.dc.html` | **ตัวแอปจริง** — markup ทุกหน้าจอ (template) + logic/state + fiber-threads canvas (class `Component`) |
| `android-frame.jsx` | bezel Android Material 3 (status bar + gesture nav) — ใช้เฉพาะการจัดแสดง ไม่ต้องพอร์ต |
| `github.md` | บันทึกความเชื่อมโยงกับ repo ต้นทาง + screen map |
| `assets/` | โลโก้ + ภาพ showcase |

**วิธีอ่านต้นแบบ:** เปิด `X-DREAMER Mobile.dc.html` ในเบราว์เซอร์เพื่อดูและกดเล่นทั้ง 10 หน้าจอ
โค้ดหน้าจอทั้งหมดอยู่ใน `XdrApp.dc.html` — ส่วน template คือ markup + inline style (ค่าตรงกับเอกสารนี้)
ส่วน `class Component` คือ state, handler, ข้อมูลตัวอย่าง และ generator ของสไตล์ที่ขึ้นกับ state (`chip()`, `pill()`)

## หมายเหตุสำหรับผู้ implement
1. ถ้าลงใน repo `aixman` เดิม: ทำเป็น route group ใหม่หรือ responsive breakpoint ของ `(main)` — ธีมและฟอนต์ถูกโหลดที่ root layout อยู่แล้ว ใช้ `XdrThemeStyles` / `FiberThreads` ที่มีได้ทันที (ลด density เป็น 16 และ cap 26fps สำหรับมือถือ)
2. อย่าลืม `viewport-fit=cover` + `env(safe-area-inset-bottom)` ใต้ tab bar สำหรับเครื่องที่มี gesture bar
3. `public/manifest.json` ปัจจุบันตั้ง `theme_color: #3B82F6` ซึ่งไม่ตรงธีมแล้ว — ควรเปลี่ยนเป็น `#030612` และ `name` เป็น X-DREAMER
4. ตัวเลขทั้งหมดในต้นแบบ (1,280 เครดิต, 248 ผลงาน, ราคา tier) เป็นข้อมูลตัวอย่าง ให้ดึงจาก DB จริง
