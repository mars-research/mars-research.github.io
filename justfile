# Build the website
build:
	hugo
	@>&2 echo '✅ The website has been built in `public`. Run `just serve` to start a local server.'
	
# Run a local server
serve:
	hugo serve
