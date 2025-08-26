
# Autogenerate 8.5x11-style thumbnails (keep page aspect) from first page of PDFs in media/pubs
# Requirements: magick (links to ImageMagick/Ghostscript)

suppressPackageStartupMessages({
  library(magick)
  library(fs)
  library(glue)
})

pdf_dir <- "media/pubs"
target_w <- 400                  # px; thumbnail width
target_h <- round(target_w * 11/8.5)  # maintain 8.5x11 ratio (~207 px at 160 px width)
density  <- 300                  # DPI for rasterizing page 1
quality  <- 95                   # JPEG quality (0–100)

dir_create(pdf_dir)               # ensure folder exists

pdfs <- dir_ls(pdf_dir, glob = "*.pdf", recurse = FALSE)

if (length(pdfs)) {
  message(glue("Found {length(pdfs)} PDF(s) in {pdf_dir}"))
} else {
  message(glue("No PDFs found in {pdf_dir}; skipping thumbnail generation."))
  quit(save = "no")
}

for (pdf in pdfs) {
  base  <- path_ext_remove(path_file(pdf))
  thumb <- path(pdf_dir, paste0(base, ".jpg"))
  
  regenerate <- !file_exists(thumb) ||
    file_info(thumb)$modification_time < file_info(pdf)$modification_time
  
  if (!regenerate) {
    message(glue("✓ {path_file(thumb)} up-to-date"))
    next
  }
  
  message(glue("→ Generating thumb for {path_file(pdf)} → {path_file(thumb)}"))
  
  # Read only first page at desired density; handle potential read failures gracefully
  img <- tryCatch(
    image_read_pdf(pdf, density = density, pages = 1),
    error = function(e) {
      message(glue("  ! Failed to read {path_file(pdf)}: {conditionMessage(e)}"))
      NULL
    }
  )
  if (is.null(img)) next
  
  # Resize by width to preserve aspect ratio, then pad to exact target canvas
  img_thumb <- img #|>
    #image_resize(glue("{target_w}x")) |>
   # image_extent(glue("{target_w}x{target_h}"), gravity = "Center")
  
  image_write(img_thumb, path = thumb, format = "jpeg", quality = quality, flatten = TRUE)
  message(glue("  ✓ Wrote {path_file(thumb)}"))
}
