
using Gtk;
using Granite;


// TODO: Update buffer if file is updated somewhere else, or at least give a warning.
// TODO: Implement zooming.

public class DocumentView : Gtk.TextView {
    public signal void editor_mode_changed (EditingMode mode);

    public enum EditingMode {
        NEW,
        EDITING
    }

    protected EditingMode editing_mode;
    protected GLib.File current_file;

    construct {
        left_margin = 12;
        right_margin = 12;
        top_margin = 12;
        bottom_margin = 12;

        current_file = null;
        set_editing_mode(EditingMode.NEW);

        buffer.changed.connect(_on_buffer_changed);
    }


    public GLib.File get_current_file() {
        return current_file;
    }

    public EditingMode get_editing_mode() {
        return editing_mode;
    }

    protected void set_editing_mode(EditingMode mode) {
        editing_mode = mode;

        editor_mode_changed(editing_mode);
    }

    // TODO: Rewrite!
    public void load_file(GLib.File file) {
        current_file = file;
        uint8[] loaded_buffer;

        try {
            current_file.load_contents (null, out loaded_buffer, null);
            buffer.set_text ((string)loaded_buffer);
            buffer.set_modified(false);

            set_editing_mode(EditingMode.EDITING);
        } catch (Error e) {
            stderr.printf ("Error: %s", e.message);
            current_file = null;
        }
    }

    // If "to" is empty, save to current_file if there is one.
    public bool save_to_file(File file) {
        if (file == null)
            return false;

        Gtk.TextBuffer buffer = buffer;

        Gtk.TextIter start;
        buffer.get_start_iter (out start);

        Gtk.TextIter end;
        buffer.get_end_iter (out end);

        string? text = buffer.get_text (start, end, false);

        if (text == null || text.length == 0)
            return false;

        try {
            if (file.replace_contents(text.data, null, false, FileCreateFlags.PRIVATE, null)) {
                current_file = file;
                buffer.set_modified (false);
                set_editing_mode (EditingMode.EDITING);
            }
        } catch (Error e) {
            stderr.printf("Error: %s", e.message);
            return false;
        }

        return true;
    }

    protected void _on_buffer_changed() {
        // Experimental: auto-save.
        // if (editing_mode == EditingMode.NEW)
            buffer.set_modified(true);
    }
}