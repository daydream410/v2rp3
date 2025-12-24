package io.flutter.plugin.common;

/**
 * Temporary shim for the removed v1 Android embedding API.
 *
 * Newer versions of Flutter no longer ship {@code PluginRegistry.Registrar},
 * but many older plugins still reference this type in their static
 * {@code registerWith(PluginRegistry.Registrar registrar)} methods.
 *
 * Those v1-style registration methods are ignored when using the v2 embedding,
 * so providing this minimal stub is safe and only serves to satisfy the Java
 * compiler so that existing plugins can still build.
 */
@Deprecated
public interface PluginRegistry {
    /** Deprecated v1 embedding registrar marker interface. */
    @Deprecated
    interface Registrar {
        // Intentionally left empty – plugins only need the type to exist.
    }
}


