const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const vendor_dir = "vendor/ggml";

    const ggml_src = b.path(vendor_dir ++ "/src");
    const ggml_include = b.path(vendor_dir ++ "/include");
    const ggml_cpu_src = b.path(vendor_dir ++ "/src/ggml-cpu");

    const root_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    root_mod.addIncludePath(ggml_src);
    root_mod.addIncludePath(ggml_include);
    root_mod.addIncludePath(ggml_cpu_src);

    const ggml_lib = b.addLibrary(.{
        .name = "ggml",
        .linkage = .static,
        .root_module = root_mod,
    });

    const c_flags = &[_][]const u8{ "-std=gnu11", "-D_GNU_SOURCE", "-DGGML_VERSION=\"0.10.0\"", "-DGGML_COMMIT=\"unknown\"" };
    const c_files = &[_][]const u8{
        "ggml.c",
        "ggml-alloc.c",
        "ggml-quants.c",
    };
    for (c_files) |file| {
        ggml_lib.root_module.addCSourceFile(.{
            .file = ggml_src.path(b, file),
            .flags = c_flags,
        });
    }

    const cpp_flags = &[_][]const u8{"-std=c++17"};
    const cpp_files = &[_][]const u8{
        "ggml.cpp",
        "ggml-backend.cpp",
        "ggml-backend-meta.cpp",
        "ggml-opt.cpp",
        "ggml-threading.cpp",
        "ggml-cpu/ggml-cpu.cpp",
        "ggml-cpu/ops.cpp",
        "ggml-cpu/vec.cpp",
        "ggml-cpu/traits.cpp",
        "ggml-cpu/binary-ops.cpp",
        "ggml-cpu/unary-ops.cpp",
        "ggml-cpu/repack.cpp",
    };
    for (cpp_files) |file| {
        ggml_lib.root_module.addCSourceFile(.{
            .file = ggml_src.path(b, file),
            .flags = cpp_flags,
        });
    }

    b.installArtifact(ggml_lib);

    const ggml_mod = b.createModule(.{
        .root_source_file = b.path("src/ggml.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    ggml_mod.addIncludePath(ggml_src);
    ggml_mod.addIncludePath(ggml_include);
    ggml_mod.linkLibrary(ggml_lib);

    const tests = b.addTest(.{ .root_module = ggml_mod });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_tests.step);
}
