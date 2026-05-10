# Generate man/figures/logo.png — hex sticker for the plnr package.
# Run from the package root:  Rscript data-raw/logo.R

library(hexSticker)

navy  <- "#5B8A4E"  # meadow green
red   <- "#E84B3B"
white <- "#FFFFFF"

svg <- fontawesome::fa("brain", fill = white)
icon_png <- tempfile(fileext = ".png")
rsvg::rsvg_png(charToRaw(as.character(svg)), file = icon_png, width = 1500)

out_path <- "man/figures/logo.png"
dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

sticker(
  subplot   = icon_png,
  package   = "plnr",
  s_x = 1, s_y = 1.15, s_width = 0.45,
  p_x = 1, p_y = 0.5, p_size = 24, p_color = white, p_family = "sans",
  h_fill    = navy,
  h_color   = navy,
  h_size    = 1.2,
  filename  = out_path,
  dpi       = 600
)

message("wrote ", out_path)
