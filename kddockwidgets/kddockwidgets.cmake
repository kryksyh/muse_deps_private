# Version lives here, not in the app.
set(DEP_VERSION 2.4)

# Source-delivery: the consumer compiles it in-tree.
set(DEP_KIND source)

# Called by the consumer (muse dockwindow_v2) after the manifest populated the
# sources.
function(kddockwidgets_add_to_build)
    if(TARGET kddockwidgets)
        return()
    endif()
    get_property(_src GLOBAL PROPERTY kddockwidgets_SOURCE_DIR)
    if(NOT BUILD_SHARED_LIBS)
        set(KDDockWidgets_STATIC ON CACHE BOOL "" FORCE)
    endif()
    set(KDDockWidgets_QT6 ON CACHE BOOL "" FORCE)
    set(KDDockWidgets_FRONTENDS "qtquick" CACHE STRING "" FORCE)
    set(KDDockWidgets_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(KDDockWidgets_TESTS OFF CACHE BOOL "" FORCE)
    add_subdirectory("${_src}/kddockwidgets" kddockwidgets EXCLUDE_FROM_ALL)
endfunction()
