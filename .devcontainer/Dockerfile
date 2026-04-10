FROM alpine:3.23

RUN apk update && apk add --no-cache \
    bash sudo shadow openssh \
    alpine-sdk meson ninja \
    gtk4.0-dev libadwaita-dev \
    desktop-file-utils gobject-introspection-dev \
    adwaita-icon-theme font-dejavu nautilus \
    json-glib-dev libgee-dev \
    gstreamer-dev gst-plugins-base-dev \
    uncrustify gdb \
    vala vala-language-server \
    just

# Create user adw, grant root access, remove password
RUN useradd -m -s /bin/bash adw && \
    echo 'adw ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/adw && \
    chmod 0440 /etc/sudoers.d/adw

# Copy the .bashrc file over
COPY .bashrc /home/adw/.bashrc

# Switch to user adw
USER adw
WORKDIR /home/adw
