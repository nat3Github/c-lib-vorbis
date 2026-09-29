const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const libc_include = b.option(std.Build.LazyPath, "libc_include", "Build without libc against these headers; the consumer provides the symbols");

    const ogg = b.dependency("ogg", .{ .target = target, .optimize = optimize, .libc_include = libc_include }).artifact("ogg");

    const mod = b.createModule(.{ .target = target, .optimize = optimize, .link_libc = libc_include == null });
    if (libc_include) |p| mod.addIncludePath(p); // -I: must win over the macOS SDK headers zig always adds
    mod.addIncludePath(b.path("include"));
    mod.addIncludePath(b.path("lib"));
    mod.linkLibrary(ogg);
    if (target.result.os.tag != .windows) mod.addCMacro("HAVE_ALLOCA_H", "1");
    mod.addCSourceFiles(.{ .root = b.path("lib"), .files = &.{
        "mdct.c",      "smallft.c",    "block.c",      "envelope.c",  "window.c",
        "lsp.c",       "lpc.c",        "analysis.c",   "synthesis.c", "psy.c",
        "info.c",      "floor1.c",     "floor0.c",     "res0.c",      "mapping0.c",
        "registry.c",  "codebook.c",   "sharedbook.c", "lookup.c",    "bitrate.c",
        "vorbisenc.c", "vorbisfile.c",
    } });

    const lib = b.addLibrary(.{ .name = "vorbis", .root_module = mod });
    lib.installHeadersDirectory(b.path("include/vorbis"), "vorbis", .{});
    lib.installLibraryHeaders(ogg);
    b.installArtifact(lib);
}
