# Análisis integrativo de ciencias ómicas para la identificación de posibles marcadores epigenéticos en leucemia mieloide aguda

Trabajo de titulación de la Maestría en Biotecnología, mención Ciencias de la Salud,
Universidad Regional Amazónica IKIAM.

**Autor:** Jorge Santiago Rojas Crespo

**Estado:** en desarrollo

## Descripción

Identificación de posibles marcadores epigenéticos en leucemia mieloide aguda (LMA)
a partir de datos públicos: la base de datos EpiFactors se usa para construir
un panel de genes epigenéticos, que luego se analiza con datos genómicos y
clínicos extraídos de TCGA-LAML (PanCancer Atlas) obtenidos desde cBioPortal.

Todo el análisis está escrito en R.

## Estructura del repositorio

- `datos/crudos/`: datos tal como se descargaron de su fuente. No se editan.
- `datos/procesados/`: datos generados por los scripts.
- `scripts/`: código del análisis, numerado en orden de ejecución.
- `resultados/`: tablas y figuras finales.

## Cómo reproducir el análisis

Ejecutar los scripts de `scripts/` en orden numérico, desde el proyecto
de RStudio `tesis-lma-epigenetica.Rproj`.
