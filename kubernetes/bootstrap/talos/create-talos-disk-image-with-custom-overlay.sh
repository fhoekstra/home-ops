# Sourced from: https://docs.siderolabs.com/talos/v1.11/build-and-extend-talos/custom-images-and-development/overlays#developing-an-overlay
# Outputs metal-arm64.raw into ./_out
# Write to SD card with:
# sudo dd if=_out/metal-arm64.raw of=/dev/sdb conv=fsync oflag=direct status=progress bs=4M

export TALOS_VERSION=v1.12.4
export OVERLAY_IMAGE="ghcr.io/siderolabs/sbc-rockchip:v0.1.8"
export OVERLAY_NAME="rock5b-plus"

sudo docker run --rm -t -v ./_out:/out -v /dev:/dev --privileged \
    ghcr.io/siderolabs/imager:${TALOS_VERSION} \
    metal --arch arm64 \
    --overlay-name="${OVERLAY_NAME}" \
    --overlay-image="${OVERLAY_IMAGE}"

