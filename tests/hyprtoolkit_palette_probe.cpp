// Parse the palette using Hyprtoolkit 0.6's registered color keys and Hyprlang.
#include <hyprlang.hpp>
#include <cstdio>

int main(int argc, char** argv) {
    if (argc != 2)
        return 2;
    Hyprlang::CConfig config(argv[1], Hyprlang::SConfigOptions{});
    for (const char* key : {"background", "base", "alternate_base", "text",
                            "bright_text", "link_text", "accent", "accent_secondary"})
        config.addConfigValue(key, Hyprlang::INT{0});
    config.commence();
    const auto result = config.parse();
    if (result.error) {
        std::fprintf(stderr, "%s\n", result.getError());
        return 1;
    }
    return 0;
}
