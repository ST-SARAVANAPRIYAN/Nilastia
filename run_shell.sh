#!/bin/bash
export PATH="$HOME/.local/bin:$PATH"
export LC_CTYPE="en_IN.UTF-8"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export QML2_IMPORT_PATH="$DIR/build/install/lib/qt6/qml"

# Unset any lingering GPU/DRM device overrides so Quickshell runs natively
# with full hardware acceleration on the active session GPU.
unset WLR_DRM_DEVICES WLR_RENDER_DRM_DEVICE VK_DRIVER_FILES __EGL_VENDOR_LIBRARY_FILENAMES __GLX_VENDOR_LIBRARY_NAME __NV_PRIME_RENDER_OFFLOAD __VK_LAYER_NV_optimus LIBVA_DRIVER_NAME VDPAU_DRIVER CUDA_VISIBLE_DEVICES NVIDIA_VISIBLE_DEVICES INIR_GPU_POLICY

exec /usr/bin/quickshell -n -c niri-nilastia-shell
