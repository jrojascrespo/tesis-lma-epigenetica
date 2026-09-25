# =============================================================================
# 01_descarga_epifactors.R
# -----------------------------------------------------------------------------
# Proyecto : Análisis integrativo de ciencias ómicas para la identificación de
#            marcadores epigenéticos en leucemia mieloide aguda (LMA)
# Autor    : Jorge Santiago Rojas Crespo
# Propósito: Descargar las tablas oficiales de la base de datos EpiFactors
#            (proteínas, complejos, histonas y lncRNAs) y dejar constancia de
#            QUÉ se descargó, DE DÓNDE y CUÁNDO.
# Entrada  : Ninguna (los datos vienen de internet).
# Salida   : datos/crudos/epifactors/v2.1/*.csv
#            datos/crudos/epifactors/v2.1/registro_descarga.csv
#            datos/crudos/hgnc/hgnc_complete_set_<fecha>.txt (+ su registro)
# Cómo usar: Abrir el proyecto de RStudio (.Rproj) y ejecutar este script
#            completo. Las rutas son relativas a la carpeta del proyecto.
# =============================================================================


# --- 1. Parámetros -----------------------------------------------------------
# Todo lo que podría cambiar va aquí arriba, en un solo lugar.
# Si mañana quieres otra versión de EpiFactors, solo cambias esta línea.

version_epifactors <- "v2.1"   # versión publicada el 10-sep-2024
url_base <- paste0("https://epifactors.autosome.org/public_data/",
                   version_epifactors, "/")

archivos <- c(
  proteinas = "EpiGenes_main.csv",
  complejos = "EpiGenes_complexes.csv",
  histonas  = "EpiGenes_histones.csv",
  lncrnas   = "EpiGenes_lncrnas.csv"
)

carpeta_destino <- file.path("datos", "crudos", "epifactors", version_epifactors)


# --- 2. Crear la carpeta de destino -------------------------------------------
# recursive = TRUE crea también las carpetas intermedias si no existen.
# showWarnings = FALSE evita un aviso si la carpeta ya estaba creada.

dir.create(carpeta_destino, recursive = TRUE, showWarnings = FALSE)


# --- 3. Descargar cada archivo ------------------------------------------------
# los datos crudos (raw) NUNCA se editan a mano.
# Si el archivo ya existe, no se vuelve a descargar (así no sobrescribimos
# por accidente la copia con la que ya trabajamos).

for (nombre in names(archivos)) {
  url     <- paste0(url_base, archivos[[nombre]])
  destino <- file.path(carpeta_destino, archivos[[nombre]])

  if (file.exists(destino)) {
    message("Ya existe, no se descarga de nuevo: ", destino)
  } else {
    message("Descargando ", nombre, " desde ", url)
    download.file(url, destfile = destino, mode = "wb", quiet = TRUE)
  }
}


# --- 4. Registro de la descarga (trazabilidad) --------------------------------
# Esta tabla funciona como un "acta" de la descarga: qué archivo, de qué URL, en qué
# fecha, cuánto pesa y su huella digital (MD5).
# El MD5 es una "huella" del contenido: si alguien vuelve a descargar el
# archivo y obtiene el mismo MD5, tiene exactamente los mismos datos que tú.

rutas <- file.path(carpeta_destino, archivos)

registro <- data.frame(
  tabla           = names(archivos),
  archivo         = unname(archivos),
  url             = paste0(url_base, archivos),
  version         = version_epifactors,
  fecha_descarga  = format(file.mtime(rutas), "%Y-%m-%d %H:%M"),
  tamano_bytes    = file.size(rutas),
  md5             = unname(tools::md5sum(rutas))
)

write.csv(registro,
          file.path(carpeta_destino, "registro_descarga.csv"),
          row.names = FALSE)

print(registro[, c("tabla", "tamano_bytes", "fecha_descarga")])


# --- 5. Primera mirada a los archivos -----------------------------------------
# Antes de leer una tabla con read.csv() hay que saber CÓMO está escrita:
# ¿separada por comas, por tabulaciones, por punto y coma? ¿tiene encabezado?
# Por eso miramos las primeras líneas "en bruto", sin interpretarlas.
# Si aparece "\t" entre las palabras, el separador es tabulación.

for (ruta in rutas) {
  cat("\n=====", basename(ruta), "=====\n")
  print(readLines(ruta, n = 3, warn = FALSE))
}


# --- 6. Tabla de referencia HGNC ----------------------------------------------
# EpiFactors trae símbolos desactualizados (ej. H1F0, hoy H1-0) y algunos
# genes sin Entrez ID (ej. MEN1). La fuente oficial de nomenclatura de genes
# humanos es el HGNC. Su tabla "complete set" relaciona cada HGNC ID con el
# símbolo vigente, los símbolos anteriores y el Entrez ID.
# Usamos una versión TRIMESTRAL CON FECHA (no "la última") para que cualquiera
# pueda descargar exactamente el mismo archivo en el futuro.
# Si esta URL diera error 404, entrar a
# https://www.genenames.org/download/archive/quarterly/tsv/
# y copiar el enlace del archivo trimestral más reciente.

url_hgnc <- paste0("https://storage.googleapis.com/public-download-files/",
                   "hgnc/archive/archive/quarterly/tsv/",
                   "hgnc_complete_set_2026-07-07.txt")

carpeta_hgnc <- file.path("datos", "crudos", "hgnc")
dir.create(carpeta_hgnc, recursive = TRUE, showWarnings = FALSE)
destino_hgnc <- file.path(carpeta_hgnc, basename(url_hgnc))

if (file.exists(destino_hgnc)) {
  message("Ya existe, no se descarga de nuevo: ", destino_hgnc)
} else {
  message("Descargando tabla HGNC desde ", url_hgnc)
  download.file(url_hgnc, destfile = destino_hgnc, mode = "wb", quiet = TRUE)
}

registro_hgnc <- data.frame(
  archivo        = basename(destino_hgnc),
  url            = url_hgnc,
  fecha_descarga = format(file.mtime(destino_hgnc), "%Y-%m-%d %H:%M"),
  tamano_bytes   = file.size(destino_hgnc),
  md5            = unname(tools::md5sum(destino_hgnc))
)
write.csv(registro_hgnc, file.path(carpeta_hgnc, "registro_descarga.csv"),
          row.names = FALSE)
print(registro_hgnc[, c("archivo", "tamano_bytes", "fecha_descarga")])

# Leer la tabla de proteínas (si ya no está en memoria)
leer_epi <- function(archivo) {
  read.csv(file.path(carpeta_destino, archivo),
           na.strings = "#", check.names = FALSE, fileEncoding = "UTF-8")
}
proteinas <- leer_epi("EpiGenes_main.csv")

# Leer la tabla HGNC
hgnc <- read.delim(destino_hgnc, quote = "", colClasses = "character")

# ¿Qué dice el HGNC de los 5 genes sin Entrez ID?
ids_faltantes <- paste0("HGNC:", proteinas$HGNC_ID[is.na(proteinas$GeneID)])
hgnc[hgnc$hgnc_id %in% ids_faltantes,
     c("hgnc_id", "symbol", "entrez_id", "prev_symbol")]

# ¿Y la histona H1F0?
hgnc[hgnc$hgnc_id == "HGNC:4714", c("hgnc_id", "symbol", "entrez_id", "prev_symbol")]

# --- 7. Información de la sesión ----------------------------------------------
# Deja constancia de la versión de R y del sistema operativo usados.

sessionInfo()
