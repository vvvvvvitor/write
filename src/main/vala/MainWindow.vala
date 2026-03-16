
using Gtk;
using Granite;

// TODO: Add save comfirmation before closing dialog.
// TODO: Add save state to also save unsaved documents.


public class MainWindow : Gtk.ApplicationWindow {
    public const string ACTION_PREFIX = "win.";
    public const string ACTION_OPEN = "action-open";
    public const string ACTION_SAVE = "action-save";

    Gtk.HeaderBar headerbar;
    DocumentStack document_stack;

    Gtk.Button open_button;
    Gtk.Button save_as_button;

    construct {
        document_stack = new DocumentStack(this);
        document_stack.current_document_changed.connect(update_title);
        document_stack.current_document_saved.connect(() => {
            update_title(document_stack.get_current_page());
        });
        document_stack.current_document_modified.connect(() => {
            update_title_prefix(document_stack.get_current_page());
        });

        document_stack.new_document();

        Gtk.Box body = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
            vexpand = true
        };
        body.append (document_stack);

        open_button = new Gtk.Button() {
            icon_name = "document-open",
            action_name = ACTION_PREFIX + ACTION_OPEN,
            tooltip_markup = Granite.markup_accel_tooltip ({"<Control>O"}, "Open file")
        };
        save_as_button = new Gtk.Button() {
            icon_name = "document-save-as",
            tooltip_markup = Granite.markup_accel_tooltip ({"<Control>S"}, "Save file")
        };

        save_as_button.clicked.connect (save_as);

        headerbar = new Gtk.HeaderBar();
        headerbar.add_css_class(Granite.STYLE_CLASS_FLAT);

        headerbar.pack_start (open_button);
        headerbar.pack_start (save_as_button);

        set_titlebar(headerbar);
        set_child(body);

        SimpleAction save_action = new SimpleAction(ACTION_SAVE, null);
        save_action.activate.connect(_on_save);
        add_action(save_action);

        SimpleAction open_action = new SimpleAction(ACTION_OPEN, null);
        open_action.activate.connect(_on_open);
        add_action(open_action);

        unowned var app = ((Gtk.Application) GLib.Application.get_default());
        app.set_accels_for_action(ACTION_PREFIX + ACTION_OPEN, {"<Control>O"});
        app.set_accels_for_action(ACTION_PREFIX + ACTION_SAVE, {"<Control>S"});

    }

    // Experimental: auto-save.
//    protected override bool close_request() {
//        for (int i = 0; i != document_stack.get_n_pages(); i++) {
//            Adw.TabPage page = document_stack.get_nth_page(i);
//            DocumentView document = page.get_data<DocumentView>("document");
//
//            if (document.get_editing_mode() == DocumentView.EditingMode.NEW)
//            continue;
//
//            document_stack.save_document(document.get_current_file());
//        }
//
//        return false;
//    }

    protected void update_title(Adw.TabPage document) {
        Gtk.ScrolledWindow document_scroll = (Gtk.ScrolledWindow)document.get_child();
        DocumentView document_view = (DocumentView)document_scroll.get_child();

        switch (document_view.get_editing_mode()) {
            case DocumentView.EditingMode.NEW:
                set_title("New Document");
                break;
            case DocumentView.EditingMode.EDITING:
                set_title(document_view.get_current_file().get_path());
                break;
        }

        update_title_prefix(document);
    }

    protected void update_title_prefix(Adw.TabPage document) {
        DocumentView editor = document.get_data<DocumentView>("document");
        set_title((editor.buffer.get_modified() ? "* " : "") + title);
    }


    protected void add_and_select_new_document() {
        Adw.TabPage document_page = document_stack.new_document();
        document_stack.select_page(document_page);
    }

    protected void save_as() {
        Gtk.FileDialog save_file_dialog = document_stack.create_file_dialog("Save Text File");

        save_file_dialog.save.begin(this, null, (obj, res) => {
            try {
                var file = save_file_dialog.save.end(res);
                document_stack.save_document(file);
            } catch (Error e) {
                stderr.printf("Error: %s\n", e.message);
            }
        });
    }

    protected void _on_open() {
        Gtk.FileDialog open_file_dialog = document_stack.create_file_dialog("Open Text File");

        open_file_dialog.open.begin(this, null, (obj, res) => {
            try {
                var file = open_file_dialog.open.end(res);
                if (file != null) {
                    document_stack.open_document(file);
                }
            } catch (Error e) {
                stderr.printf("Error: %s\n", e.message);
            }
        });
    }

    protected void _on_save() {
        DocumentView document = document_stack.get_current_document();

        switch (document.get_editing_mode()) {
            case DocumentView.EditingMode.NEW:
                save_as();
                break;
            case DocumentView.EditingMode.EDITING:
                document_stack.save_document(document.get_current_file());
                break;
        }
    }
}
