const std = @import("std");
const Build = std.Build;

pub fn build(b: *std.Build) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimize options allows the user to choose the optimization mode
    // when running 'zig build'.  This applies to downstream consumers of this package
    // as well, e.g. when added as a dependency in build.zig.zon.
    // Default to Debug, but allow the user to specify ReleaseSafe or ReleaseFast builds
    const optimize = b.standardOptimizeOption(.{});

    // Specify the default library linkage mode
    const linkage = b.option(std.builtin.LinkMode, "linkage", "static or dynamic linkage") orelse .static;

    // Additional build configuration options
    const build_contrib = b.option(bool, "build-contrib", "Enable yaml-cpp contrib in library") orelse true;
    const build_tools = b.option(bool, "build-tools", "Enable parse tools") orelse true;

    // Upstream yaml-cpp library
    const upstream = b.dependency("yaml_cpp", .{
        .target = target,
        .optimize = optimize,
        .linkage = linkage,
    });

    // Export the yaml-cpp module to downstream consumers
    const mod = b.addModule("yaml-cpp", .{
        .target = target,
        .optimize = optimize,
        .link_libcpp = true,
    });
    mod.addIncludePath(upstream.path("include/"));
    mod.addIncludePath(upstream.path("src/"));
    mod.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = &.{
            "binary.cpp",
            "convert.cpp",
            "depthguard.cpp",
            "directives.cpp",
            "emit.cpp",
            "emitfromevents.cpp",
            "emitter.cpp",
            "emitterstate.cpp",
            "emitterutils.cpp",
            "exceptions.cpp",
            "exp.cpp",
            "fptostring.cpp",
            "memory.cpp",
            "node.cpp",
            "node_data.cpp",
            "nodebuilder.cpp",
            "nodeevents.cpp",
            "null.cpp",
            "ostream_wrapper.cpp",
            "parse.cpp",
            "parser.cpp",
            "regex_yaml.cpp",
            "scanner.cpp",
            "scanscalar.cpp",
            "scantag.cpp",
            "scantoken.cpp",
            "simplekey.cpp",
            "singledocparser.cpp",
            "stream.cpp",
            "tag.cpp",
        },
        // .flags = &.{"-std=c++11"},
    });

    if (build_contrib) {
        mod.addIncludePath(upstream.path("src/contrib/"));
        mod.addCSourceFiles(.{
            .root = upstream.path("src"),
            .files = &.{
                "contrib/graphbuilder.cpp",
                "contrib/graphbuilderadapter.cpp",
            },
        });
    }

    // Build and install the actual library
    const lib = b.addLibrary(.{
        .name = "yaml-cpp",
        .root_module = mod,
        .linkage = linkage,
    });

    lib.installHeadersDirectory(upstream.path("include"), "", .{});
    if (build_contrib) {
        lib.installHeadersDirectory(upstream.path("src/contrib"), "yaml-cpp", .{});
    }

    b.installArtifact(lib);

    if (build_tools) {
        const sandbox = b.addExecutable(.{
            .name = "yaml-cpp-sandbox",
            .target = target,
            .optimize = optimize,
            // We could specify the linkage here, but it's target dependent
            // (Builing for GNU libC requires dynamic, while MUSL will use static)
            // So, just let the compiler figure it out.
        });
        sandbox.addCSourceFiles(.{ .root = upstream.path("util"), .files = &.{"sandbox.cpp"} });
        sandbox.linkLibrary(lib);
        b.installArtifact(sandbox);

        const parse = b.addExecutable(.{
            .name = "yaml-cpp-parse",
            .target = target,
            .optimize = optimize,
        });
        parse.addCSourceFiles(.{ .root = upstream.path("util"), .files = &.{"parse.cpp"} });
        parse.linkLibrary(lib);
        b.installArtifact(parse);

        const read = b.addExecutable(.{
            .name = "yaml-cpp-read",
            .target = target,
            .optimize = optimize,
        });
        read.addCSourceFiles(.{ .root = upstream.path("util"), .files = &.{"read.cpp"} });
        read.linkLibrary(lib);
        b.installArtifact(read);
    }
}
