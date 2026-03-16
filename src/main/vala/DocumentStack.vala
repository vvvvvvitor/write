
using Gtk;

// TODO: Check if a file has been removed.
// TODO: Autosave.

public class DocumentStack : Gtk.Box {
    public const string ACTION_NEW = "action-new";

    public signal void document_closed ();

    public signal void current_document_changed (Adw.TabPage new_document);
    public signal void current_document_modified ();
    public signal void current_document_saved ();

    Adw.TabView tab_view;
    Adw.TabBar switcher;

    Adw.TabPage last_page_document;
    // TODO: Move new_button to window if tab len == 0.
    Gtk.Button new_button;


    public DocumentStack(Gtk.ApplicationWindow window) {
        new_button = new Gtk.Button() {
            icon_name = "list-add-symbolic",
            action_name = MainWindow.ACTION_PREFIX + ACTION_NEW,
            sensitive = true,
            tooltip_markup = Granite.markup_accel_tooltip ({"<Control>N"}, "New file")
        };

        switcher.set_start_action_widget(new_button);

        SimpleAction new_action = new SimpleAction(ACTION_NEW, null);
        new_action.activate.connect(() => {
            Adw.TabPage document_page = new_document();
            tab_view.set_selected_page(document_page);
        });
        window.add_action(new_action);

        unowned var app = ((Gtk.Application) GLib.Application.get_default());
        app.set_accels_for_action(MainWindow.ACTION_PREFIX + ACTION_NEW, {"<Control>N"});
    }

    construct {
        last_page_document = null;

        orientation = Gtk.Orientation.VERTICAL;

        tab_view = new Adw.TabView();
        tab_view.close_page.connect ((page) => {
            if (tab_view.get_n_pages() == 1) {
                unowned var app = ((Gtk.Application) GLib.Application.get_default());
                app.quit();
            }
            tab_view.close_page_finish(page, true);
        });
        tab_view.notify["selected-page"].connect(() => {
            if (last_page_document != null) {
                DocumentView last_document = last_page_document.get_data<DocumentView>("document");;
                last_document.buffer.modified_changed.disconnect(_on_current_document_modified);
            }

            last_page_document = tab_view.selected_page;
            if (last_page_document != null) {
                // Workaround because for some reason getting the "document" meta doesn't work for the first widget.
                Gtk.ScrolledWindow document_scroll = (Gtk.ScrolledWindow)last_page_document.get_child();
                DocumentView current_document = (DocumentView)document_scroll.get_child();

                current_document.grab_focus();

                current_document.get_buffer().modified_changed.connect(_on_current_document_modified);
                current_document_changed (last_page_document);
            }
        });

        switcher = new Adw.TabBar() {
            view = tab_view,
            autohide = false,
            expand_tabs = false
        };

        append (switcher);
        append (tab_view);
    }

    protected void _on_current_document_modified() {
        current_document_modified ();
    }

    public int get_n_pages() {
        return tab_view.get_n_pages();
    }

    public Adw.TabPage get_nth_page(int position) {
        return tab_view.get_nth_page(position);
    }

    public void select_page(Adw.TabPage page) {
        tab_view.set_selected_page(page);
    }

    public Adw.TabPage get_current_page() {
        return tab_view.get_selected_page();
    }

    public DocumentView get_current_document() {
        return (DocumentView)get_current_page().get_data<DocumentView>("document");
    }

    public Gtk.FileDialog create_file_dialog(string title) {
        Gtk.FileFilter text_filter = new Gtk.FileFilter() {
            name = "Text"
        };
        text_filter.add_mime_type("text/*");
        Gtk.FileFilter all_filter = new Gtk.FileFilter() {
            name = "All"
        };
        all_filter.add_mime_type("*");

        GLib.ListStore filter_list = new GLib.ListStore(typeof(Gtk.FileFilter));
        filter_list.append(text_filter);
        filter_list.append(all_filter);

        return new Gtk.FileDialog() {
            title = title,
            filters = filter_list
        };
    }

    protected Gtk.ScrolledWindow build_document() {
        DocumentView editor = new DocumentView();

        Gtk.ScrolledWindow editor_scroll = new Gtk.ScrolledWindow() {
            child = editor,
            vexpand = true
        };

        return editor_scroll;
    }

    public Adw.TabPage new_document(string title = "New Document") {
        Gtk.ScrolledWindow document_scroll = build_document();

        Adw.TabPage new_page = tab_view.append(document_scroll);
        new_page.set_title(title);
        new_page.set_data<DocumentView>("document", (DocumentView)document_scroll.get_child());

        return new_page;
    }

    public void save_document(File file) {
        Adw.TabPage document_page = get_current_page();
        DocumentView document_view = document_page.get_data<DocumentView>("document");

        if (document_view.save_to_file(file) == false)
            return;

        try {
            FileInfo file_info = file.query_info ("standard::display-name", GLib.FileQueryInfoFlags.NONE);
            document_page.set_title (file_info.get_attribute_string ("standard::display-name"));
        } catch (Error e) {
            stderr.printf("Error: %s",  e.message);
            document_page.set_title ("Unknown file");
        }

        current_document_saved ();
    }

    public void open_document(File file) {
        for (int i = 0; i != get_n_pages(); i++) {
            Adw.TabPage page = get_nth_page(i);
            DocumentView document = page.get_data<DocumentView>("document");

            if (document.get_editing_mode() == DocumentView.EditingMode.NEW)
                continue;

            if (document.get_current_file().peek_path() == file.peek_path())
                return;
        }

        if (file != null) {
            Adw.TabPage document = null;

            try {
                FileInfo file_info = file.query_info ("standard::display-name", GLib.FileQueryInfoFlags.NONE);
                document = new_document (file_info.get_attribute_string ("standard::display-name"));
            } catch (Error e) {
                document = new_document ();
            }

            document.get_data<DocumentView>("document").load_file (file);
            tab_view.set_selected_page(document);
        }
    }

}