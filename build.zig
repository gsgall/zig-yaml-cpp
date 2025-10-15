const std = @import("std");
const Build = std.Build;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const linkage = b.option(std.builtin.LinkMode, "linkage", "static or dynamic linkage") orelse .dynamic;

    // Additional build configuration options
    const build_contrib = b.option(bool, "build-contrib", "Enable yaml-cpp contrib in library") orelse true;
    const build_tools = b.option(bool, "build-tools", "Enable parse tools") orelse false;

    const std_module_opts: std.Build.Module.CreateOptions = .{
        .target = target,
        .optimize = optimize,
        .pic = true,
        .link_libcpp = true,
    };

    // Upstream yaml-cpp library
    const upstream = b.dependency("yaml_cpp", .{
        .target = target,
        .optimize = optimize,
        .linkage = linkage,
    });

    // Export the yaml-cpp module to downstream consumers
    const mod = b.addModule("yaml-cpp", std_module_opts);
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
        .flags = &.{ "-std=c++17", "-fPIC" },
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
    const lib = b.addLibrary(.{ .name = "yaml-cpp", .root_module = mod, .linkage = linkage, .version = .{ .major = 0, .minor = 8, .patch = 0 } });

    lib.installHeadersDirectory(upstream.path("include"), "", .{});
    if (build_contrib) {
        lib.installHeadersDirectory(upstream.path("src/contrib"), "yaml-cpp", .{});
    }

    b.installArtifact(lib);

    if (build_tools) {
        const sandbox = b.addExecutable(.{
            .name = "yaml-cpp-sandbox",
            .root_module = b.createModule(std_module_opts),
        });
        sandbox.addCSourceFiles(.{ .root = upstream.path("util"), .files = &.{"sandbox.cpp"} });
        sandbox.linkLibrary(lib);
        b.installArtifact(sandbox);

        const parse = b.addExecutable(.{
            .name = "yaml-cpp-parse",
            .root_module = b.createModule(std_module_opts),
        });
        parse.addCSourceFiles(.{ .root = upstream.path("util"), .files = &.{"parse.cpp"} });
        parse.linkLibrary(lib);
        b.installArtifact(parse);

        const read = b.addExecutable(.{
            .name = "yaml-cpp-read",
            .root_module = b.createModule(std_module_opts),
        });
        read.addCSourceFiles(.{ .root = upstream.path("util"), .files = &.{"read.cpp"} });
        read.linkLibrary(lib);
        b.installArtifact(read);
    }
}
