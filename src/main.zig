//! MagiMDM HTTP entry: console + agent API.

const std = @import("std");
const httpz = @import("httpz");
const auth = @import("auth.zig");
const config = @import("config.zig");
const db = @import("db.zig");
const enroll_pc = @import("enroll_pc.zig");
const poll_extras = @import("poll_extras.zig");
const comms_log = @import("comms_log.zig");

const login_html =
    \
<!DOCTYPE html><html><head><meta charset="utf-8"/><title>MagiMDM login</title>
    \
<script src="https://cdn.tailwindcss.com"></script></head>
    \
<body class="bg-slate-950 text-slate-100 min-h-screen flex items-center justify-center">
    \
<form method="post" action="/login" class="bg-slate-900 p-6 rounded w-80 space-y-3">
    \
<h1 class="text-lg">MagiMDM</h1>
    \
<input name="username" placeholder="username" class="w-full bg-slate-800 p-2 rounded"/>
    \
<input name="password" type="password" placeholder="password" class="w-full bg-slate-800 p-2 rounded"/>
    \
<button class="w-full bg-sky-700 rounded p-2">Sign in</button>
    \
<p class="text-xs text-slate-500">Change admin/changeme on first login.</p>
    \
</form></body></html>
;

const home_html =
    \
<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"/><title>MagiMDM home</title>
    \
<script src="https://cdn.tailwindcss.com"></script></head>
    \
<body class="bg-slate-950 text-slate-100 p-6">
    \
<h1 class="text-2xl mb-2">Homeschool desk</h1>
    \
<div class="grid grid-cols-2 md:grid-cols-4 gap-3 mb-8">
    \
<form method="post" action="/devices/bulk"><input type="hidden" name="policy" value="SchoolDay"/><button class="w-full bg-sky-700 rounded p-4">School</button></form>
    \
<form method="post" action="/devices/bulk"><input type="hidden" name="policy" value="AfterHours"/><button class="w-full bg-slate-700 rounded p-4">Free</button></form>
    \
<form method="post" action="/devices/bulk"><input type="hidden" name="policy" value="ExamLock"/><button class="w-full bg-amber-700 rounded p-4">Exam</button></form>
    \
<form method="post" action="/devices/bulk"><input type="hidden" name="command" value="lock"/><button class="w-full bg-rose-800 rounded p-4">Lock</button></form>
    \
</div>
    \
<p class="text-sm"><a class="underline" href="/enroll/pc">Enroll PC</a> · <a class="underline" href="/enroll">Tokens</a> · <a class="underline" href="/comms">Comms</a> · <a class="underline" href="/logout">Logout</a></p>
    \
<pre id="devs" class="mt-6 text-xs text-slate-300 whitespace-pre-wrap"></pre>
    \
<script>fetch("/api/parent/devices").then(r=>r.json()).then(j=>{document.getElementById("devs").textContent=JSON.stringify(j,null,2)}).catch(()=>{});</script>
    \
</body></html>
;

const enroll_pc_html =
    \
<!DOCTYPE html><html><head><meta charset="utf-8"/><title>Enroll PC</title>
    \
<script src="https://cdn.tailwindcss.com"></script></head>
    \
<body class="bg-slate-950 text-slate-100 p-8 max-w-xl mx-auto">
    \
<h1 class="text-2xl mb-4">Enroll PC</h1>
    \
<form method="post" action="/enroll/pc" class="space-y-4">
    \
<label class="block text-sm">Platform
    \
<select name="platform" class="mt-1 w-full bg-slate-900 p-2 rounded">
    \
<option value="linux">Linux</option><option value="windows">Windows</option></select></label>
    \
<label class="block text-sm">Image
    \
<select name="image_slug" class="mt-1 w-full bg-slate-900 p-2 rounded">
    \
<option value="linux-debian12-student">linux-debian12-student</option>
    \
<option value="windows11-student">windows11-student</option></select></label>
    \
<label class="block text-sm">Label
    \
<input name="label" value="student-laptop" class="mt-1 w-full bg-slate-900 p-2 rounded"/></label>
    \
<button class="bg-sky-600 rounded px-4 py-2">Create token</button>
    \
</form>
    \
<p class="mt-6"><a class="underline" href="/">Home</a></p>
    \
</body></html>
;

pub const App = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    cfg: config.Config,
    db: *db.Conn,
};

pub fn main() !void {
    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_state.deinit();
    const gpa = gpa_state.allocator();

    var threaded = std.Io.Threaded.init(gpa);
    defer threaded.deinit();
    const io = threaded.io();

    const cfg = try config.Config.fromEnv(gpa);
    var conn = try db.Conn.open(cfg.db_path);
    defer conn.close();
    try conn.bootstrapAdmin(cfg.bootstrap_username, cfg.bootstrap_password);

    var app = App{ .allocator = gpa, .io = io, .cfg = cfg, .db = &conn };

    var server = try httpz.Server(*App).init(io, gpa, .{
        .address = .localhost(cfg.port),
        .request = .{ .max_form_count = 32 },
    }, &app);
    defer {
        server.stop();
        server.deinit();
    }

    var router = try server.router(.{});
    router.get("/login", getLogin, .{});
    router.post("/login", postLogin, .{});
    router.get("/logout", getLogout, .{});
    router.get("/", getHome, .{});
    router.get("/home", getHome, .{});
    router.get("/comms", getComms, .{});
    router.get("/enroll", getEnroll, .{});
    router.post("/enroll", postEnrollToken, .{});
    router.get("/enroll/pc", getEnrollPc, .{});
    router.post("/enroll/pc", postEnrollPc, .{});
    router.post("/devices/bulk", postBulk, .{});
    router.get("/api/parent/devices", getParentDevices, .{});
    router.get("/api/parent/comms", getParentComms, .{});
    router.post("/api/agent/enroll", postAgentEnroll, .{});
    router.post("/api/agent/poll", postAgentPoll, .{});
    router.post("/api/agent/ack", postAgentAck, .{});
    router.post("/api/agent/comms-log", postAgentComms, .{});

    std.log.info("MagiMDM listening on http://{s}:{d}", .{ cfg.host, cfg.port });
    try server.listen();
}

fn currentUser(app: *App, req: *httpz.Request) !?i64 {
    const cookies = req.cookies();
    const sid = cookies.get(app.cfg.session_cookie) orelse return null;
    return app.db.sessionUser(sid);
}

fn requireUser(app: *App, req: *httpz.Request, res: *httpz.Response) !?i64 {
    if (try currentUser(app, req)) |id| return id;
    res.status = 302;
    res.header("Location", "/login");
    res.body = "login";
    return null;
}

fn getLogin(_: *App, _: *httpz.Request, res: *httpz.Response) !void {
    res.content_type = .HTML;
    res.body = login_html;
}

fn postLogin(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    const form = try req.formData();
    const username = form.get("username") orelse "";
    const password = form.get("password") orelse "";
    const user = try app.db.userByName(req.arena, username) orelse {
        res.status = 401;
        res.body = "bad login";
        return;
    };
    if (!auth.verifyPassword(app.allocator, app.io, password, user.hash)) {
        res.status = 401;
        res.body = "bad login";
        return;
    }
    const sid = try auth.generateSessionToken(req.arena);
    try app.db.createSession(sid, user.id, app.cfg.session_ttl_secs);
    try res.setCookie(app.cfg.session_cookie, sid, .{
        .path = "/",
        .http_only = true,
        .same_site = .lax,
        .secure = app.cfg.secure_cookies,
        .max_age = app.cfg.session_ttl_secs,
    });
    res.status = 302;
    res.header("Location", "/");
}

fn getLogout(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    if (req.cookies().get(app.cfg.session_cookie)) |sid| {
        try app.db.deleteSession(sid);
    }
    try res.setCookie(app.cfg.session_cookie, "", .{
        .path = "/",
        .http_only = true,
        .max_age = 0,
    });
    res.status = 302;
    res.header("Location", "/login");
}

fn getHome(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    if (try requireUser(app, req, res) == null) return;
    res.content_type = .HTML;
    res.body = home_html;
}

fn getComms(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    if (try requireUser(app, req, res) == null) return;
    res.content_type = .HTML;
    res.body = "<html><body><p>Comms archive. JSON at /api/parent/comms</p><p><a href=/>Home</a></p></body></html>";
}

fn getEnroll(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    if (try requireUser(app, req, res) == null) return;
    const list = try app.db.tokensHtml(req.arena);
    res.content_type = .HTML;
    res.body = try std.fmt.allocPrint(req.arena,
        \\
<!DOCTYPE html><html><body class="p-6">
        \\
<h1>Tokens</h1>
        \\
<form method="post" action="/enroll">
        \\
<input name="label" value="phone"/>
        \\
<button>New token</button></form>
        \\
{s}<p><a href="/">Home</a></p></body></html>
    , .{list});
}

fn postEnrollToken(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    const uid = try requireUser(app, req, res) orelse return;
    const form = try req.formData();
    const label = form.get("label") orelse "device";
    const token = try auth.generateSessionToken(req.arena);
    try app.db.insertToken(token, label, uid);
    res.status = 302;
    res.header("Location", "/enroll");
}

fn getEnrollPc(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    if (try requireUser(app, req, res) == null) return;
    res.content_type = .HTML;
    res.body = enroll_pc_html;
}

fn postEnrollPc(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    const uid = try requireUser(app, req, res) orelse return;
    const form = try req.formData();
    const platform = enroll_pc.normalizePlatform(form.get("platform") orelse "linux");
    const slug = form.get("image_slug") orelse "";
    const label = form.get("label") orelse "student-laptop";
    const token = try auth.generateSessionToken(req.arena);
    try app.db.insertToken(token, label, uid);
    const folder = if (std.mem.eql(u8, platform, "windows")) "agent-pc/windows" else "agent-pc/linux";
    res.content_type = .HTML;
    res.body = try std.fmt.allocPrint(req.arena,
        \\
<html><body><p>Token: <code>{s}</code></p>
        \\
<p>Platform: {s} image: {s}</p>
        \\
<p>Copy folder <code>{s}</code> onto the USB.</p>
        \\
<pre>TOKEN={s} MDM_URL=http://127.0.0.1:{d} ./tools/usb_pack.sh /tmp/usb {s}</pre>
        \\
<p><a href="/">Home</a></p></body></html>
    , .{ token, platform, slug, folder, token, app.cfg.port, platform });
}

fn postBulk(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    const uid = try requireUser(app, req, res) orelse return;
    const form = try req.formData();
    if (form.get("policy")) |name| {
        try app.db.assignPolicyAll(name, uid);
    } else if (form.get("command")) |typ| {
        try app.db.enqueueCommandAll(typ, uid);
    }
    res.status = 302;
    res.header("Location", "/");
}

fn getParentDevices(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    if (try requireUser(app, req, res) == null) return;
    res.content_type = .JSON;
    res.body = try app.db.devicesJson(req.arena);
}

fn getParentComms(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    if (try requireUser(app, req, res) == null) return;
    res.content_type = .JSON;
    res.body = "{\"events\":[]}";
}

const EnrollReq = struct {
    token: []const u8,
    uuid: ?[]const u8 = null,
    name: ?[]const u8 = null,
    platform: ?[]const u8 = null,
    model: ?[]const u8 = null,
    os_version: ?[]const u8 = null,
    agent_version: ?[]const u8 = null,
    image_slug: ?[]const u8 = null,
};

fn postAgentEnroll(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    const body = try req.json(EnrollReq);
    if (!try app.db.consumeToken(body.token)) {
        res.status = 403;
        res.body = "{\"ok\":false,\"error\":\"token\"}";
        return;
    }
    const uuid = body.uuid orelse try auth.generateSessionToken(req.arena);
    const platform = enroll_pc.normalizePlatform(body.platform orelse "android");
    const name = body.name orelse "device";
    const id = try app.db.insertDevice(
        uuid,
        name,
        platform,
        body.os_version orelse "",
        body.agent_version orelse "",
        body.token,
    );
    if (body.image_slug) |slug| {
        try app.db.bindImage(id, slug);
    }
    try app.db.assignPolicyByName(id, "SchoolDay");
    res.content_type = .JSON;
    res.body = try std.fmt.allocPrint(req.arena, "{{\"ok\":true,\"device_id\":{d},\"uuid\":\"{s}\"}}", .{ id, uuid });
}

const PollReq = struct {
    uuid: []const u8,
    battery_pct: ?i64 = null,
    agent_version: ?[]const u8 = null,
};

fn postAgentPoll(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    const raw = req.body() orelse "{}";
    const body = try req.json(PollReq);
    const id = try app.db.deviceByUuid(body.uuid) orelse {
        res.status = 404;
        res.body = "{\"ok\":false,\"error\":\"device\"}";
        return;
    };
    try app.db.touchDevice(id, body.battery_pct, poll_extras.extractExtrasJson(raw), body.agent_version);
    const cmds = try app.db.pendingCommandsJson(req.arena, id);
    const policy = try app.db.policyJson(req.arena, id);
    res.content_type = .JSON;
    res.body = try std.fmt.allocPrint(
        req.arena,
        "{{\"ok\":true,\"device_id\":{d},\"commands\":{s},\"policy\":{s}}}",
        .{ id, cmds, policy },
    );
}

const AckReq = struct {
    uuid: []const u8,
    command_id: i64,
    result: ?std.json.Value = null,
};

fn postAgentAck(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    const body = try req.json(AckReq);
    const id = try app.db.deviceByUuid(body.uuid) orelse {
        res.status = 404;
        res.body = "{\"ok\":false}";
        return;
    };
    try app.db.ackCommand(id, body.command_id, "{}");
    res.content_type = .JSON;
    res.body = "{\"ok\":true}";
}

const CommsReq = struct {
    uuid: []const u8,
};

fn postAgentComms(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    const body = try req.json(CommsReq);
    try app.db.insertComms(body.uuid, "", "in", "call", "", 1, "{}", "");
    _ = comms_log.ack;
    res.content_type = .JSON;
    res.body = comms_log.ack;
}
