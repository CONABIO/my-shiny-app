# Activate renv for local development, but skip it in Shiny Server runtime.
is_shiny_server <- nzchar(Sys.getenv("SHINY_SERVER_VERSION")) ||
	nzchar(Sys.getenv("SHINY_PORT")) ||
	identical(tolower(Sys.getenv("R_CONFIG_ACTIVE", "")), "shiny")

if (!is_shiny_server) {
	source("renv/activate.R")
}
