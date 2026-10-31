(() => {
    const RESOURCE = location.hostname.startsWith("cfx-nui-")
        ? location.hostname.slice("cfx-nui-".length)
        : "luudi_korekortapp";

    const IN_GAME = location.hostname.startsWith("cfx-nui-") || !!window.invokeNative;

    // ─── Testdata til browser (bruges kun udenfor spillet) ────────────────────
    const MOCK = {
        getCard: () => ({
            status: "valid", firstName: "Marc", lastName: "Polo", dob: "07. 06. 1999", age: 27,
            cardNumber: "31657372", issuedAt: 1786435200, updatedAt: 1786435200,
            categories: [{ code: "B", label: "Personbil", icon: "car" }],
            points: 0, maxPoints: 12, issuer: "Byens Trafikkontor", country: "DK", serverId: 1,
        }),
        isPolice: () => ({ police: new URLSearchParams(location.search).has("police") }),
        getPhoto: () => ({ url: null }),
        getNearbyPolice: () => (new URLSearchParams(location.search).has("nearby") ? [{ id: 2, name: "Jens Hansen", distance: 3 }] : []),
        getReceived: () => [],
        sendNearest: () => ({ ok: false, message: "Ingen politi i nærheden." }),
        airshare: () => ({ ok: true, message: "Kørekort delt via AirShare." }),
        clearReceived: () => [],
    };

    // ─── Ikoner ───────────────────────────────────────────────────────────────
    const ICONS = {
        car: '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M5 11l1.5-4.5A2 2 0 0 1 8.4 5h7.2a2 2 0 0 1 1.9 1.5L19 11a2 2 0 0 1 2 2v4h-2v2h-3v-2H8v2H5v-2H3v-4a2 2 0 0 1 2-2zm2.1 0h9.8l-1.1-3.4a.6.6 0 0 0-.6-.4H8.8a.6.6 0 0 0-.6.4zM6.5 15.5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3zm11 0a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3z"/></svg>',
        bike: '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M15 5h3l2.2 6.1A4 4 0 1 1 17 16a4 4 0 0 1 1.4-3l-.5-1.3L14 16h-3.1A4 4 0 1 1 7 11h3.2l1.6-2H8V7h5.2l-1.6 2.1L13 11l3.3-4H15zM5 15a2 2 0 1 0 4 0 2 2 0 0 0-4 0zm12 0a2 2 0 1 0 4 0 2 2 0 0 0-4 0z"/></svg>',
        truck: '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M2 5h12v9h1V8h4l3 4v5h-2a2.5 2.5 0 0 1-5 0H9a2.5 2.5 0 0 1-5 0H2zm14 5v2h4l-1.5-2zM6.5 18.5a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm11 0a1 1 0 1 0 0-2 1 1 0 0 0 0 2z"/></svg>',
        person: '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M12 12a4.5 4.5 0 1 0 0-9 4.5 4.5 0 0 0 0 9zm0 2c-4.4 0-8 2.2-8 5v2h16v-2c0-2.8-3.6-5-8-5z"/></svg>',
        share: '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M12 3a9 9 0 0 1 9 9h-2a7 7 0 1 0-7 7v2a9 9 0 0 1 0-18zm0 4a5 5 0 0 1 5 5h-2a3 3 0 1 0-3 3v2a5 5 0 0 1 0-10zm0 4a1 1 0 1 1 0 2 1 1 0 0 1 0-2z"/></svg>',
        inbox: '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M4 4h16l2 9v6a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1v-6zm1.6 2-1.5 7H9l1 2h4l1-2h4.9l-1.5-7z"/></svg>',
        logo: '<svg viewBox="0 0 26 30" class="dl-logo"><path d="M13 1 2 5v8c0 7.2 4.6 13 11 16 6.4-3 11-8.8 11-16V5z" fill="#1d2577"/><path d="M13 4 5 7v6c0 5.6 3.3 10.2 8 12.6 4.7-2.4 8-7 8-12.6V7z" fill="#f4c64a"/><path d="M13 7.5 8 9.4v3.8c0 3.7 2 6.9 5 8.8z" fill="#1d2577"/><circle cx="16.3" cy="12.4" r="1.8" fill="#c8202f"/></svg>',
    };

    const MONTHS_SHORT = ["jan.", "feb.", "mar.", "apr.", "maj", "jun.", "jul.", "aug.", "sep.", "okt.", "nov.", "dec."];
    const MONTHS_LONG = ["januar", "februar", "marts", "april", "maj", "juni", "juli", "august", "september", "oktober", "november", "december"];

    const fmtShort = (unix) => { const d = new Date(unix * 1000); return `${d.getDate()}. ${MONTHS_SHORT[d.getMonth()]} ${d.getFullYear()}`; };
    const fmtLong = (unix) => { const d = new Date(unix * 1000); return `${d.getDate()}. ${MONTHS_LONG[d.getMonth()]} ${d.getFullYear()}`; };
    const fmtTime = (unix) => { const d = new Date(unix * 1000); return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`; };
    const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

    // ─── NUI ──────────────────────────────────────────────────────────────────
    async function nui(event, data = {}) {
        if (!IN_GAME) return MOCK[event] ? MOCK[event](data) : null;
        try {
            const res = await fetch(`https://${RESOURCE}/${event}`, {
                method: "POST",
                headers: { "Content-Type": "application/json; charset=UTF-8" },
                body: JSON.stringify(data),
            });
            return await res.json();
        } catch (err) {
            console.error(`[korekort] ${event}`, err);
            return null;
        }
    }

    // ─── State ────────────────────────────────────────────────────────────────
    const state = { card: null, photo: null, police: false, received: [], seenReceived: 0, nearby: [] };
    const $ = (id) => document.getElementById(id);

    // ─── Render: kort ─────────────────────────────────────────────────────────
    function clipHtml(card) {
        if (card.points == null) return "";
        const max = card.maxPoints || 12;
        const pts = Math.max(0, card.points);
        const perDot = max / 3;
        const filled = Math.min(3, Math.floor(pts / perDot));
        const dots = [0, 1, 2].map((i) => `<i class="${i < filled ? "on" : ""}"></i>`).join("");
        return `<div class="dl-clip"><span class="pill">KLIP</span><span class="clip-dots">${dots}</span><span class="clip-text">${pts}/${max} point</span></div>`;
    }

    function cardHtml(card, photo, opts = {}) {
        if (!card) return `<div class="dl-card"><div class="void-banner">Indlæser kørekort…</div></div>`;

        const valid = card.status === "valid";
        const photoStyle = photo ? ` style="background-image:url('${esc(photo)}')"` : "";
        const issued = card.issuedAt ? fmtShort(card.issuedAt) : "";
        const updated = card.updatedAt ? fmtLong(card.updatedAt) : "";

        let body;
        if (valid) {
            body = `
                <div class="dl-fields">
                    <div><span class="pill">FØDT</span><div class="dl-value">${esc(card.dob)}</div></div>
                    <div><span class="pill">ALDER</span><div class="dl-value">${card.age != null ? `${card.age} år` : "Ukendt"}</div></div>
                    <div><span class="pill">KORTNR.</span><div class="dl-value">${esc(card.cardNumber)}</div></div>
                </div>
                ${clipHtml(card)}
                <div class="dl-cats">
                    ${card.categories.map((c) => `<div class="cat" title="${esc(c.label)}">${ICONS[c.icon] || ICONS.car}${esc(c.code)}</div>`).join("")}
                </div>`;
        } else if (card.status === "revoked") {
            body = `<div class="void-banner">Kørekortet er frakendt<small>Kontakt politiet for at generhverve det.</small></div>`;
        } else {
            body = `<div class="void-banner">Du har ikke et kørekort<small>Når du får et kørekort, vises det her.</small></div>`;
        }

        return `
            <div class="dl-card ${valid ? "" : "void"} ${opts.compact ? "compact" : ""}">
                <div class="dl-head">
                    ${ICONS.logo}
                    <div class="dl-issuer">${esc(card.issuer)}<small>${issued}</small></div>
                </div>
                <div class="dl-country">${esc(card.country)}</div>
                <div class="dl-photo ${photo ? "has-img" : ""}"${photoStyle}>${ICONS.person}</div>
                <div class="dl-name">${esc(card.firstName)}<br>${esc(card.lastName)}</div>
                ${body}
                <div class="dl-foot">Sidst opdateret: ${updated}</div>
            </div>`;
    }

    function renderCard() {
        $("myCard").innerHTML = cardHtml(state.card, state.photo);
        const valid = state.card?.status === "valid";
        $("sendNearestBtn").disabled = !valid;
        $("airshareBtn").disabled = !valid;
    }

    // ─── Render: Kortinfo ─────────────────────────────────────────────────────
    function renderInfo() {
        const c = state.card;
        if (!c) { $("view-info").innerHTML = ""; return; }

        const statusTag = { valid: ["valid", "Gyldigt"], revoked: ["revoked", "Frakendt"], none: ["none", "Intet kørekort"] }[c.status];
        const cats = c.categories.length
            ? c.categories.map((k) => `<div class="row"><div class="cat-row"><div class="cat">${ICONS[k.icon] || ICONS.car}${esc(k.code)}</div><span>${esc(k.label)}</span></div><span class="v">Kategori ${esc(k.code)}</span></div>`).join("")
            : `<div class="row"><span class="k">Ingen kategorier</span></div>`;

        let points = "";
        if (c.points != null) {
            const pct = Math.min(100, (c.points / c.maxPoints) * 100);
            const cls = pct >= 75 ? "crit" : pct >= 50 ? "warn" : "";
            points = `
                <p class="h2">Klip</p>
                <div class="panel">
                    <div class="row"><span class="k">Strafpoint</span><span class="v">${c.points} / ${c.maxPoints}</span></div>
                    <div class="bar"><i class="${cls}" style="width:${pct}%"></i></div>
                    <p class="note">Point gives af politiet sammen med bøder for færdselsforseelser. Når du når ${c.maxPoints} point, frakendes kørekortet automatisk. Hver prik på kortet svarer til ${Math.round(c.maxPoints / 3)} point.</p>
                </div>`;
        }

        $("view-info").innerHTML = `
            <p class="h2">Oplysninger</p>
            <div class="panel">
                <div class="row"><span class="k">Status</span><span class="tag ${statusTag[0]}">${statusTag[1]}</span></div>
                <div class="row"><span class="k">Navn</span><span class="v">${esc(c.firstName)} ${esc(c.lastName)}</span></div>
                <div class="row"><span class="k">Født</span><span class="v">${esc(c.dob)}</span></div>
                ${c.cardNumber ? `<div class="row"><span class="k">Kortnummer</span><span class="v">${esc(c.cardNumber)}</span></div>` : ""}
                ${c.issuedAt ? `<div class="row"><span class="k">Udstedt</span><span class="v">${fmtLong(c.issuedAt)}</span></div>` : ""}
                <div class="row"><span class="k">Udsteder</span><span class="v">${esc(c.issuer)}</span></div>
            </div>
            <p class="h2">Kategorier</p>
            <div class="panel">${cats}</div>
            ${points}`;
    }

    // ─── Render: Modtaget ─────────────────────────────────────────────────────
    function renderReceived() {
        const list = state.received || [];
        const badge = $("receivedBadge");
        const unseen = list.length - state.seenReceived;
        badge.textContent = unseen;
        badge.classList.toggle("hidden", unseen <= 0 || currentView === "received");

        if (!list.length) {
            $("view-received").innerHTML = `<div class="empty">${ICONS.inbox}<br>Ingen modtagne kørekort endnu.<br>Når en borger deler sit kort, vises det her.</div>`;
            return;
        }

        $("view-received").innerHTML = list.map((e) => `
            <div class="rx-item">
                <div class="rx-meta"><span>${e.method === "airshare" ? "AirShare" : "Sendt direkte"}</span><span>Modtaget kl. ${fmtTime(e.receivedAt)}</span></div>
                ${cardHtml(e.card, e.photo, { compact: true })}
            </div>`).join("") + `<button class="btn danger" id="clearReceivedBtn">Ryd liste</button>`;

        $("clearReceivedBtn").onclick = async () => {
            state.received = (await nui("clearReceived")) || [];
            state.seenReceived = 0;
            renderReceived();
        };
    }

    // ─── Navigation ───────────────────────────────────────────────────────────
    let currentView = "card";
    function showView(name) {
        currentView = name;
        document.querySelectorAll(".view").forEach((v) => v.classList.toggle("active", v.id === `view-${name}`));
        document.querySelectorAll(".tab").forEach((t) => t.classList.toggle("active", t.dataset.view === name));
        if (name === "received") { state.seenReceived = state.received.length; renderReceived(); }
    }
    document.querySelectorAll(".tab").forEach((t) => t.addEventListener("click", () => showView(t.dataset.view)));

    // ─── Status linje (politi i nærheden) ─────────────────────────────────────
    let statusLock = 0;
    function setStatus(text, kind = "") {
        const el = $("statusLine");
        el.textContent = text;
        el.className = `status ${kind}`;
    }
    function flashStatus(text, kind) {
        statusLock = Date.now() + 4000;
        setStatus(text, kind);
    }

    async function refreshNearby() {
        state.nearby = (await nui("getNearbyPolice")) || [];
        if (Date.now() < statusLock) return;
        if (state.card && state.card.status !== "valid") return setStatus("Du skal have et gyldigt kørekort for at dele det.", "muted");
        const n = state.nearby.length;
        if (!n) setStatus("Ingen politi i nærheden.");
        else setStatus(n === 1 ? "1 betjent i nærheden." : `${n} betjente i nærheden.`, "ok");
    }

    // ─── Ark ──────────────────────────────────────────────────────────────────
    function openSheet(html) { $("sheetContent").innerHTML = html; $("app").classList.add("sheet-open"); }
    function closeSheet() { $("app").classList.remove("sheet-open"); }
    $("sheetBackdrop").addEventListener("click", closeSheet);

    async function openAirShare() {
        openSheet(`<div class="radar">${ICONS.share}</div><h3>AirShare</h3><p class="sub">Søger efter politi i nærheden…</p>`);
        await refreshNearby();
        const list = state.nearby;

        if (!list.length) {
            openSheet(`<div class="radar">${ICONS.share}</div><h3>AirShare</h3><p class="sub">Ingen betjente i nærheden. Gå tættere på og prøv igen.</p><button class="btn outline" id="sheetClose">Luk</button>`);
            $("sheetClose").onclick = closeSheet;
            return;
        }

        openSheet(`
            <h3>AirShare</h3>
            <p class="sub">Vælg den betjent du vil dele dit kørekort med</p>
            <div class="airshare-list">
                ${list.map((o) => `
                    <button class="officer" data-id="${o.id}">
                        <span class="avatar">${esc(initials(o.name))}</span>
                        <span><div class="name">${esc(o.name)}</div><div class="dist">${o.distance} m væk</div></span>
                        <span class="state"></span>
                    </button>`).join("")}
            </div>
            <button class="btn outline" id="sheetClose">Annuller</button>`);

        $("sheetClose").onclick = closeSheet;
        document.querySelectorAll(".officer").forEach((btn) => {
            btn.onclick = async () => {
                document.querySelectorAll(".officer").forEach((b) => (b.disabled = true));
                btn.querySelector(".state").textContent = "Venter…";
                const res = await nui("airshare", { target: Number(btn.dataset.id) });
                closeSheet();
                flashStatus(res?.message || "Noget gik galt.", res?.ok ? "ok" : "");
            };
        });
    }

    function initials(name) {
        return String(name || "?").split(" ").filter(Boolean).slice(0, 2).map((p) => p[0].toUpperCase()).join("");
    }

    function openSettings() {
        openSheet(`
            <h3>Indstillinger</h3>
            <p class="sub">Kortet opdateres automatisk, når du åbner appen.</p>
            <div class="actions">
                <button class="btn primary" id="refreshBtn">Opdater kort og billede</button>
                <button class="btn outline" id="sheetClose">Luk</button>
            </div>`);
        $("sheetClose").onclick = closeSheet;
        $("refreshBtn").onclick = async () => { closeSheet(); await loadAll(true); flashStatus("Kortet er opdateret.", "ok"); };
    }

    $("settingsBtn").addEventListener("click", openSettings);
    $("airshareBtn").addEventListener("click", openAirShare);
    $("sendNearestBtn").addEventListener("click", async () => {
        $("sendNearestBtn").disabled = true;
        const res = await nui("sendNearest");
        $("sendNearestBtn").disabled = state.card?.status !== "valid";
        flashStatus(res?.message || "Noget gik galt.", res?.ok ? "ok" : "");
    });

    // ─── Data ─────────────────────────────────────────────────────────────────
    async function loadAll(withPhoto = true) {
        const [card, police] = await Promise.all([nui("getCard"), nui("isPolice")]);
        state.card = card;
        state.police = !!police?.police;
        $("receivedTab").classList.toggle("hidden", !state.police);
        if (!state.police && currentView === "received") showView("card");

        renderCard();
        renderInfo();

        if (withPhoto) {
            const photo = await nui("getPhoto");
            state.photo = photo?.url || null;
            renderCard();
        }

        if (state.police) {
            state.received = (await nui("getReceived")) || [];
            renderReceived();
        }
        refreshNearby();
    }

    window.addEventListener("message", (event) => {
        const msg = event.data || {};
        if (msg.action === "appOpened") { enterPhone(); loadAll(true); }
        if (msg.action === "received") {
            state.received = msg.data || [];
            renderReceived();
        }
    });

    // Vis kun appen når den kører i telefonen. Fuldskærms siden (fra ui_page) er bred,
    // telefonens vindue er smalt. "appOpened" kommer kun til telefonens vindue.
    let started = false;
    function enterPhone() {
        document.documentElement.classList.add("in-phone");
        if (started) return;
        started = true;
        setInterval(() => { if (!document.hidden) refreshNearby(); }, 4000);
    }

    if (!IN_GAME || window.innerWidth <= 700) {
        enterPhone();
        loadAll(true);
    }

})();
