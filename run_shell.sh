#!/bin/bash
export PATH="$HOME/.local/bin:$PATH"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export QML2_IMPORT_PATH="$DIR/build/install/lib/qt6/qml"

# When running in a GPU-accelerated session (Niri on NVIDIA), unpin Quickshell
# from Intel/Mesa overrides so it renders directly with hardware acceleration on NVIDIA
# rather than falling back to CPU software rendering (wl_shm).
if [ "${NIRI_GPU_MODE:-}" = "nvidia" ]; then
    unset WLR_DRM_DEVICES WLR_RENDER_DRM_DEVICE VK_DRIVER_FILES __EGL_VENDOR_LIBRARY_FILENAMES __GLX_VENDOR_LIBRARY_NAME __NV_PRIME_RENDER_OFFLOAD __VK_LAYER_NV_optimus LIBVA_DRIVER_NAME VDPAU_DRIVER CUDA_VISIBLE_DEVICES NVIDIA_VISIBLE_DEVICES INIR_GPU_POLICY
fi

exec /usr/bin/quickshell -n -c niri-nilastia-shell
