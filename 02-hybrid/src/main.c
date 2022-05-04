// ARKO Scale Image project
// Execute with:
//      ./image_viewer images/imageName.bmp
// "ctrl" + "+" to zoom in
// "ctrl" + "-" to zoom out
// Author: Mikalai Stelmakh
#include <gtk/gtk.h>
#include <gdk/gdkkeysyms.h>
#include <stdio.h>
#include <stdlib.h>
#include "scale.h"

#define SCALE_RATIO 2
#define OUTPUT_FILE_NAME "images/scaled.bmp"

GtkWidget *w_img_main;
int x = 0;

extern void f(void *input_img, int width, int height, void *output_img, int newWidth, int newHeight);


gboolean func (GtkWidget *widget, GdkEventKey *event, gpointer data);

#pragma pack(1)
typedef struct
{
    unsigned char sig_0;
    unsigned char sig_1;
    int32_t size;
    uint32_t reserved;
    uint32_t pixel_offset;
    uint32_t header_size;
    uint32_t width;
    uint32_t height;
    uint16_t planes;
    uint16_t bpp_type;
    uint32_t compression;
    uint32_t image_size;
    uint32_t horizontal_res;
    uint32_t vertical_res;
    uint32_t color_palette;
    uint32_t important_colors;
} Header;
#pragma pack(0)

int main(int argc, char *argv[])
{
    GtkBuilder *builder;
    GtkWidget *window;

    if (argc != 2)
    {
        printf("No file name provided.\n");
        return 0;
    }
    gtk_init(&argc, &argv);

    builder = gtk_builder_new_from_file("glade/window_main.glade");

    window = GTK_WIDGET(gtk_builder_get_object(builder, "window_main"));
    w_img_main = GTK_WIDGET(gtk_builder_get_object(builder, "img_main"));
    gtk_image_set_from_file(GTK_IMAGE(w_img_main), argv[1]);
    gtk_builder_connect_signals(builder, NULL);
    g_signal_connect (G_OBJECT (window), "key_press_event", G_CALLBACK (func), (gpointer) argv[1]);
    g_object_unref(builder);

    gtk_widget_show(window);
    gtk_main();

    return 0;
}

void on_window_main_destroy()
{
    gtk_main_quit();
}

void scale_image(char* file_name, int x){
    FILE *fp;
    fp = fopen(file_name, "rb");

    Header header;
    fread(&header, sizeof(Header), 1, fp);
    unsigned char *input_bitmap = (unsigned char *) malloc(header.size - 54);
    fread(input_bitmap, header.size-54, 1, fp);
    fclose(fp);

    Header output_header;
    output_header = header;
    output_header.width = header.width*SCALE_RATIO*x;
    output_header.height = header.height*SCALE_RATIO*x;
    output_header.size = (output_header.width*3 + output_header.width%4) * output_header.height;

    unsigned char *ScaledImage = (unsigned char*) malloc(output_header.size);
    output_header.size += 54;

    f(input_bitmap, header.width, header.height, ScaledImage, output_header.width, output_header.height);

    unsigned char* result = (unsigned char *)malloc(output_header.size);

    memcpy(result, &output_header, 54);

    fp = fopen(OUTPUT_FILE_NAME, "wb");
    fwrite(result, 54, 1, fp);
    fwrite(ScaledImage, output_header.size - 54, 1, fp);
    fclose(fp);
    free(result);

    gtk_image_set_from_file(GTK_IMAGE(w_img_main), OUTPUT_FILE_NAME);
}

gboolean
func (GtkWidget *widget, GdkEventKey *event, gpointer data)
{
    char* file_name = data;
    switch (event->keyval)
    {
        case (GDK_KEY_equal):
            if (event->state & GDK_CONTROL_MASK){
                ++x;
                scale_image(file_name, x);
            }
            break;
        case (GDK_KEY_minus):
            if (event->state & GDK_CONTROL_MASK){
                if (x>1){
                    --x;
                    scale_image(file_name, x);
                }
                else if (x==1)
                {
                    --x;
                    gtk_image_set_from_file(GTK_IMAGE(w_img_main), file_name);
                }
            }
            break;
    }
    return TRUE;
}


