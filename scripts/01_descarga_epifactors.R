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
# Salida   : data/raw/epifactors/v2.1/*.csv
#            data/raw/epifactors/v2.1/registro_descarga.csv
# Cómo usar: Abrir el proyecto de RStudio (.Rproj) y ejecutar este script
#            completo. Las rutas son relativas a la carpeta del proyecto.
# =============================================================================


# --- 1. Parámetros -----------------------------------------------------------


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

dir.create(carpeta_destino, recursive = TRUE, showWarnings = FALSE)


# --- 3. Descargar cada archivo ------------------------------------------------

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

for (ruta in rutas) {
  cat("\n=====", basename(ruta), "=====\n")
  print(readLines(ruta, n = 3, warn = FALSE))
}

carpeta <- file.path("datos", "crudos", "epifactors", "v2.1")

# Una función propia: escribimos la lógica de lectura UNA vez y la reusamos 4 veces
leer_epi <- function(archivo) {
  read.csv(file.path(carpeta, archivo),
           na.strings   = "#",      # el '#' pasa a ser NA (dato faltante)
           check.names  = FALSE,    # respeta los nombres originales de columna
           fileEncoding = "UTF-8")
}

proteinas <- leer_epi("EpiGenes_main.csv")
complejos <- leer_epi("EpiGenes_complexes.csv")
histonas  <- leer_epi("EpiGenes_histones.csv")
lncrnas   <- leer_epi("EpiGenes_lncrnas.csv")

# ¿Cuántas filas y columnas tiene cada tabla?
sapply(list(proteinas = proteinas, complejos = complejos,
            histonas = histonas, lncrnas = lncrnas), dim)

# ¿Hay símbolos repetidos? ¿Cuántos no tienen Entrez ID?
sum(duplicated(proteinas$HGNC_symbol))
sum(is.na(proteinas$GeneID))
sum(is.na(histonas$GeneID))
sum(is.na(lncrnas$`Entrez gene ID`))   # backticks porque el nombre tiene espacios

# ¿Qué valores tiene la columna Status?
table(proteinas$Status, useNA = "ifany")


# 1. ¿Cuáles símbolos están repetidos?
repetidos <- proteinas$HGNC_symbol[duplicated(proteinas$HGNC_symbol)]
repetidos

# 2. Mostrar TODAS las filas sospechosas: las de símbolos repetidos
#    y las que no tienen Entrez ID. El símbolo | significa "o".
sospechosas <- proteinas$HGNC_symbol %in% repetidos | is.na(proteinas$GeneID)

proteinas[sospechosas,
          c("Id", "HGNC_symbol", "HGNC_ID", "GeneID", "UniProt_ID", "Status", "Function")]

# --- 6. Información de la sesión ----------------------------------------------
# Deja constancia de la versión de R y del sistema operativo usados.

sessionInfo()

