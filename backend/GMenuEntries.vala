namespace Slingshot.Backend {
    public class GMenuEntries : GLib.Object {

        public static Gee.ArrayList<GMenu.TreeDirectory> get_categories () {

            var tree = GMenu.Tree.lookup ("applications.menu", GMenu.TreeFlags.INCLUDE_EXCLUDED);
            var root = tree.get_root_directory ();
            var main_directory_entries = new Gee.ArrayList<GMenu.TreeDirectory> ();

            foreach (GMenu.TreeItem item in root.get_contents()) {
                if (item.get_type() == GMenu.TreeItemType.DIRECTORY) {
                    main_directory_entries.add ((GMenu.TreeDirectory) item);
                }
            }
            return main_directory_entries;
        }

        public static Gee.HashSet<GMenu.TreeEntry> get_applications_for_category (GMenu.TreeDirectory category) {

            var entries = new Gee.HashSet<GMenu.TreeEntry>  ( (x) => ((GMenu.TreeEntry)x).get_desktop_file_path ().hash (), (x,y) => ((GMenu.TreeEntry)x).get_desktop_file_path ().hash () == ((GMenu.TreeEntry)y).get_desktop_file_path ().hash ());

            foreach (GMenu.TreeItem item in category.get_contents ()) {
                switch (item.get_type ()) {
                    case GMenu.TreeItemType.DIRECTORY:
                        entries.add_all (get_applications_for_category ((GMenu.TreeDirectory) item));
                        break;
                    case GMenu.TreeItemType.ENTRY:
                        entries.add ((GMenu.TreeEntry) item);
                        break;
                }
            }
            return entries;
        }

        public static Gee.HashSet<GMenu.TreeEntry> get_all () {

            var the_apps = new Gee.HashSet<GMenu.TreeEntry> ( (x) => ((GMenu.TreeEntry)x).get_desktop_file_path ().hash (), (x,y) => ((GMenu.TreeEntry)x).get_desktop_file_path ().hash () == ((GMenu.TreeEntry)y).get_desktop_file_path ().hash ());
            var all_categories = get_categories ();

            foreach (GMenu.TreeDirectory directory in all_categories) {
                var this_category_apps = get_applications_for_category (directory);
                foreach(GMenu.TreeEntry this_app in this_category_apps){
                    the_apps.add(this_app);
                }
            }
            return the_apps;
        }

        public static void enumerate_apps (Gee.HashSet<GMenu.TreeEntry> source, Gee.HashMap<string, Gdk.Pixbuf> icons, int icon_size, out Gee.ArrayList<Gee.HashMap<string, string>> list) {

            var icon_theme = Gtk.IconTheme.get_default();

            list = new Gee.ArrayList<Gee.HashMap<string, string>> ();
            foreach (GMenu.TreeEntry app in source) {
               if (app.get_is_nodisplay() == false && app.get_is_excluded() == false && app.get_icon() != null) {
                    var app_to_add = new Gee.HashMap<string, string> ();
                    app_to_add["description"] = app.get_comment();
                    app_to_add["name"] = app.get_name();
                    app_to_add["command"] = app.get_exec();
                    app_to_add["desktop_file"] = app.get_desktop_file_path();
                    if (!icons.has_key(app_to_add["command"])) {
                        var app_icon = app.get_icon ();
                        try {
                            if (icon_theme.has_icon (app_icon)) {
                                /* Attention: the icons inside the icon_theme can tell lies about their icon_size, so we need always to scale them */
                                icons[app_to_add["command"]] = icon_theme.load_icon(app_icon, icon_size, 0).scale_simple(icon_size, icon_size, Gdk.InterpType.BILINEAR);
                            } else if (GLib.File.new_for_path(app_icon).query_exists()) {
                                icons[app_to_add["command"]] = new Gdk.Pixbuf.from_file_at_scale (app_icon.to_string (), -1, icon_size, true);
                            } else {
                                icons[app_to_add["command"]] = icon_theme.load_icon("application-default-icon", icon_size, 0);
                            }
                        } catch  (GLib.Error e) {
                            stdout.printf("No icon found.\n");
                        }
                    }
                    list.add (app_to_add);
                }
            }
        }
    }
}
