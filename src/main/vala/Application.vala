
using Gtk;
using Granite;


// TODO: Maybe have configurable actions on the topbar?


public class TextEditor : Gtk.Application {
    public TextEditor() {
        Object (
            application_id: "io.github.vvvvvvitor.write",
            flags: ApplicationFlags.DEFAULT_FLAGS
        );
    }

    protected override void activate() {
        MainWindow window = new MainWindow() {
            default_width = 320,
            default_height = 320
        };

        add_window(window);

        window.present();

        // inhibit(window, Gtk.ApplicationInhibitFlags.IDLE, string? reason);

        // Granite.Services.Application.set_progress_visible (true);
        // Granite.Services.Application.set_progress(0.5f);
    }

    public static int main(string[] args) {
        return new TextEditor().run(args);
    }
}