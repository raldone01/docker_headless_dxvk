FROM archlinux:latest

RUN --mount=type=cache,target=/var/cache/pacman \
  echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf && \
  pacman -Syu --noconfirm && \
  pacman -S --noconfirm --needed vulkan-swrast mesa mesa-utils base-devel wget curl gnupg xorg-server xf86-video-dummy xorg-server-xvfb lib32-vulkan-icd-loader vulkan-icd-loader vulkan-tools mesa mesa-demos wine-staging wine-gecko wine-mono dosbox gnutls lib32-gnutls lib32-gst-plugins-base lib32-gst-plugins-base-libs lib32-gst-plugins-good lib32-libpulse lib32-libxcomposite lib32-libxinerama lib32-opencl-icd-loader lib32-pcsclite lib32-sdl2 lib32-v4l-utils libgphoto2 libpulse libxcomposite libxinerama opencl-icd-loader pcsclite samba sane sdl2 unixodbc v4l-utils wine-gecko wine-mono && \
  # Debugging tools
  pacman -S --noconfirm nano strace less

# Download and install dxvk
RUN \
  mkdir -p /tmp/dxvk && \
  cd /tmp/dxvk && \
  curl -L 'https://github.com/doitsujin/dxvk/releases/download/v2.3/dxvk-2.3.tar.gz' -o dxvk-2.3.tar.gz && \
  # unpack and install dxvk
  tar -xzf dxvk-2.3.tar.gz && \
  cd dxvk-2.3 && \
  # copy the x32 and x64 folders to /usr/local/bin/dxvk
  mkdir -p /usr/local/bin/dxvk && \
  cp -r x32 x64 /usr/local/bin/dxvk && \
  rm -rf /tmp/dxvk

ENV WINEPREFIX=/root/.wine64
ENV WINEARCH=win64

# Setup wine prefix and install dxvk
RUN \
  wineboot -u && \
  cp /usr/local/bin/dxvk/x64/*.dll $WINEPREFIX/drive_c/windows/system32 && \
  cp /usr/local/bin/dxvk/x32/*.dll $WINEPREFIX/drive_c/windows/syswow64 && \
  #do this for every dll in x64 and x32 wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides' /v path_to_dll /d native /f && \
  before=$(stat -c '%Y' $WINEPREFIX/user.reg) \
  dlls_paths=$(find /usr/local/bin/dxvk -name '*.dll') && \
  for dll in $dlls_paths; do \
  wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v "$(basename "${dll%.*}")" /d native /f; \
  # get the reg keys
  # wine reg query "HKEY_CURRENT_USER\Software\Wine\DllOverrides" | grep -i $(basename "${dll%.*}"); \
  done \
  && while [ $(stat -c '%Y' $WINEPREFIX/user.reg) = $before ]; do sleep 1; done

# Install d3d11-triangle.exe
RUN \
  mkdir -p /tmp/d3d11-triangle && \
  cd /tmp/d3d11-triangle && \
  curl -L 'https://gitlab.melroy.org/melroy/winegui/uploads/c4db93700d13dfb71997f28c2965aeb7/dxvk-test.tar.gz' -o triangle.tar.gz && \
  mkdir -p /tmp/d3d11-triangle/dxvk-test && \
  tar -xzf triangle.tar.gz -C /tmp/d3d11-triangle/dxvk-test && \
  #64bit
  mv dxvk-test /usr/local/bin/d3d11-triangle && \
  rm -rf /tmp/d3d11-triangle

COPY --chown=root:root --chmod=755 entrypoint.sh /entrypoint.sh
COPY xorg.conf /etc/X11/xorg.conf.d/20-virt.conf
ENTRYPOINT ["/entrypoint.sh"]
