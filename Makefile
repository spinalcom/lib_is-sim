
all:
	@echo "compiling lib_is-sim..."
	@python	bin/make.py
	@echo "\n\033[0;32m[OK] Compiling lib_is-sim : Done\033[m\n"

clean:
	@! test -e gen || rm -rf gen/ .gen/ models.js processes.js stylesheets.css
	@echo "\033[0;32m[OK] cleaning lib_is-sim : Done\033[m"

.PHONY: all clean
