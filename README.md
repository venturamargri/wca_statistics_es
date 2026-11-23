# Estadísticas WCA España

Estadísticas de speedcubing para competidores que representan a España y competiciones celebradas en España, calculadas a partir de los [volcados públicos de la base de datos de la WCA](https://www.worldcubeassociation.org/export/results).

Basado en el proyecto original de [jonatanklosko/wca_statistics](https://github.com/jonatanklosko/wca_statistics) y su adaptación nacional [maxidragon/wca_statistics_pl](https://github.com/maxidragon/wca_statistics_pl).

## Puesta en marcha

Requisitos: Ruby (ver `.ruby-version`) y MySQL.

- Instalar dependencias: `bundle`
- Inicializar configuración: `bin/init.rb`
- Ajustar `database.yml` en la raíz del proyecto si es necesario.
- Descargar e importar la base de datos de la WCA: `bin/update_database.rb`
- Calcular todas las estadísticas: `bin/compute_all.rb && bin/compute_index.rb`
