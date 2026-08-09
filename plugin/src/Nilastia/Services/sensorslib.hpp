#pragma once

#include <optional>

namespace nilastia::services::sensorslib {

void ensureInit();

[[nodiscard]] std::optional<double> cpuPackageTemp();
[[nodiscard]] std::optional<double> gpuPciAverageTemp();

} // namespace nilastia::services::sensorslib
