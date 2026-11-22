#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"
#include <string.h>

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static gboolean on_native_drag_motion(GtkWidget* widget,
                                      GdkDragContext* context,
                                      gint x,
                                      gint y,
                                      guint time,
                                      gpointer user_data) {
  auto* channel = static_cast<FlMethodChannel*>(user_data);
  GdkDragAction suggested = gdk_drag_context_get_suggested_action(context);
  GdkDragAction actions = gdk_drag_context_get_actions(context);
  GdkDragAction chosen = GDK_ACTION_COPY;
  if (suggested & (GDK_ACTION_COPY | GDK_ACTION_MOVE | GDK_ACTION_LINK)) {
    chosen = suggested;
  } else if (actions & GDK_ACTION_COPY) {
    chosen = GDK_ACTION_COPY;
  } else if (actions & GDK_ACTION_MOVE) {
    chosen = GDK_ACTION_MOVE;
  } else if (actions & GDK_ACTION_LINK) {
    chosen = GDK_ACTION_LINK;
  }
  gdk_drag_status(context, chosen, time);
  fl_method_channel_invoke_method(channel, "dragEntered", nullptr, nullptr, nullptr, nullptr);
  return FALSE;
}

static void on_native_drag_leave(GtkWidget* widget,
                                 GdkDragContext* context,
                                 guint time,
                                 gpointer user_data) {
  auto* channel = static_cast<FlMethodChannel*>(user_data);
  fl_method_channel_invoke_method(channel, "dragExited", nullptr, nullptr, nullptr, nullptr);
}

static void on_native_drag_data_received(GtkWidget* widget,
                                         GdkDragContext* context,
                                         gint x,
                                         gint y,
                                         GtkSelectionData* sdata,
                                         guint info,
                                         guint time,
                                         gpointer user_data) {
  auto* channel = static_cast<FlMethodChannel*>(user_data);
  g_autoptr(FlValue) path_list = fl_value_new_list();

  // 1. Extract standard URI list (text/uri-list)
  gchar** uris = gtk_selection_data_get_uris(sdata);
  if (uris != nullptr) {
    for (int i = 0; uris[i] != nullptr; i++) {
      g_autofree gchar* local_path = g_filename_from_uri(uris[i], nullptr, nullptr);
      if (local_path != nullptr && strlen(local_path) > 0) {
        fl_value_append_take(path_list, fl_value_new_string(local_path));
      } else if (strlen(uris[i]) > 0) {
        fl_value_append_take(path_list, fl_value_new_string(uris[i]));
      }
    }
    g_strfreev(uris);
  }

  // 2. Fallback: extract text or raw selection payload
  if (fl_value_get_length(path_list) == 0) {
    gchar* text = reinterpret_cast<gchar*>(gtk_selection_data_get_text(sdata));
    if (text != nullptr) {
      fl_value_append_take(path_list, fl_value_new_string(text));
      g_free(text);
    } else {
      gint length = gtk_selection_data_get_length(sdata);
      const guchar* raw_data = gtk_selection_data_get_data(sdata);
      if (length > 0 && raw_data != nullptr) {
        g_autofree gchar* raw_str = g_strndup(reinterpret_cast<const gchar*>(raw_data), length);
        fl_value_append_take(path_list, fl_value_new_string(raw_str));
      }
    }
  }

  fl_method_channel_invoke_method(channel, "dragDropped", path_list, nullptr, nullptr, nullptr);
}

// Called when first Flutter frame received.
static void first_frame_cb(FlView* view, gpointer user_data) {
  gtk_widget_show(GTK_WIDGET(view));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "AppImage Studio");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "AppImage Studio");
  }

  // Set window icon for taskbar / dock / Alt-Tab
  g_autofree gchar* exe_path = g_file_read_link("/proc/self/exe", nullptr);
  if (exe_path != nullptr) {
    g_autofree gchar* dir = g_path_get_dirname(exe_path);
    g_autofree gchar* icon_path = g_build_filename(dir, "data", "flutter_assets", "assets", "icon.png", nullptr);
    if (g_file_test(icon_path, G_FILE_TEST_EXISTS)) {
      gtk_window_set_icon_from_file(window, icon_path, nullptr);
      gtk_window_set_default_icon_from_file(icon_path, nullptr);
    } else {
      g_autofree gchar* fallback_icon = g_build_filename(dir, "assets", "icon.png", nullptr);
      if (g_file_test(fallback_icon, G_FILE_TEST_EXISTS)) {
        gtk_window_set_icon_from_file(window, fallback_icon, nullptr);
        gtk_window_set_default_icon_from_file(fallback_icon, nullptr);
      }
    }
  }

  // Set fixed size and lock window geometry (prevent manual resizing & maximize)
  gtk_window_set_default_size(window, 1000, 780);
  gtk_widget_set_size_request(GTK_WIDGET(window), 1000, 780);
  gtk_window_set_resizable(window, FALSE);

  GdkGeometry geometry;
  geometry.min_width = 1000;
  geometry.min_height = 780;
  geometry.max_width = 1000;
  geometry.max_height = 780;
  gtk_window_set_geometry_hints(
      window, GTK_WIDGET(window), &geometry,
      static_cast<GdkWindowHints>(GDK_HINT_MIN_SIZE | GDK_HINT_MAX_SIZE | GDK_HINT_BASE_SIZE));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  // Disconnect broken desktop_drop GTK signal handlers (void on_drag_motion ABI bug)
  g_signal_handlers_disconnect_matched(
      GTK_WIDGET(view), G_SIGNAL_MATCH_ID,
      g_signal_lookup("drag-motion", GTK_TYPE_WIDGET),
      0, nullptr, nullptr, nullptr);
  g_signal_handlers_disconnect_matched(
      GTK_WIDGET(view), G_SIGNAL_MATCH_ID,
      g_signal_lookup("drag-data-received", GTK_TYPE_WIDGET),
      0, nullptr, nullptr, nullptr);
  g_signal_handlers_disconnect_matched(
      GTK_WIDGET(view), G_SIGNAL_MATCH_ID,
      g_signal_lookup("drag-leave", GTK_TYPE_WIDGET),
      0, nullptr, nullptr, nullptr);
  g_signal_handlers_disconnect_matched(
      GTK_WIDGET(view), G_SIGNAL_MATCH_ID,
      g_signal_lookup("focus-in-event", GTK_TYPE_WIDGET),
      0, nullptr, nullptr, nullptr);

  // Configure native GTK3 drag-and-drop prioritizing real text/uri-list paths
  gtk_drag_dest_unset(GTK_WIDGET(view));
  gtk_drag_dest_set(
      GTK_WIDGET(view),
      GTK_DEST_DEFAULT_ALL,
      nullptr,
      0,
      static_cast<GdkDragAction>(GDK_ACTION_COPY | GDK_ACTION_MOVE | GDK_ACTION_LINK));
  gtk_drag_dest_add_uri_targets(GTK_WIDGET(view));
  gtk_drag_dest_add_text_targets(GTK_WIDGET(view));

  FlEngine* engine = fl_view_get_engine(view);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* drop_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(engine),
      "appimage_studio/native_drop",
      FL_METHOD_CODEC(codec));
  g_object_set_data_full(G_OBJECT(view), "native_drop_channel",
                         drop_channel, g_object_unref);

  g_signal_connect(GTK_WIDGET(view), "drag-motion",
                   G_CALLBACK(on_native_drag_motion), drop_channel);
  g_signal_connect(GTK_WIDGET(view), "drag-leave",
                   G_CALLBACK(on_native_drag_leave), drop_channel);
  g_signal_connect(GTK_WIDGET(view), "drag-data-received",
                   G_CALLBACK(on_native_drag_data_received), drop_channel);

  g_signal_connect(view, "first-frame", G_CALLBACK(first_frame_cb), self);

  gtk_widget_grab_focus(GTK_WIDGET(view));

  gtk_widget_show(GTK_WIDGET(window));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_init(MyApplication* self) {}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

MyApplication* my_application_new() {
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
